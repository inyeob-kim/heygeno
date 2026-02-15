"""가격 추적 관련 비즈니스 로직"""
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.exc import IntegrityError
from fastapi import HTTPException, status

from app.models.tracking import Tracking, TrackingStatus
from app.schemas.tracking import TrackingCreate


class TrackingService:
    """가격 추적 서비스 - 추적 관련 비즈니스 로직만 담당"""
    
    @staticmethod
    async def get_trackings_by_user_id(user_id: UUID, db: AsyncSession) -> list[Tracking]:
        """사용자 ID로 추적 목록 조회"""
        result = await db.execute(
            select(Tracking).where(
                Tracking.user_id == user_id,
                Tracking.status != TrackingStatus.DELETED
            )
        )
        return list(result.scalars().all())
    
    @staticmethod
    async def get_tracking_by_id(tracking_id: UUID, db: AsyncSession) -> Tracking:
        """추적 ID로 조회"""
        result = await db.execute(select(Tracking).where(Tracking.id == tracking_id))
        tracking = result.scalar_one_or_none()
        
        if tracking is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Tracking not found"
            )
        
        return tracking
    
    @staticmethod
    async def create_tracking(
        user_id: UUID,
        tracking_data: TrackingCreate,
        db: AsyncSession
    ) -> Tracking:
        """가격 추적 생성 (기존 tracking이 있으면 재활성화)"""
        # 기존 tracking 확인 (DELETED 포함)
        existing = await db.execute(
            select(Tracking).where(
                Tracking.user_id == user_id,
                Tracking.pet_id == tracking_data.pet_id,
                Tracking.product_id == tracking_data.product_id
            )
        )
        existing_tracking = existing.scalar_one_or_none()
        
        if existing_tracking is not None:
            # 기존 tracking이 ACTIVE 또는 PAUSED 상태면 에러 반환
            if existing_tracking.status in [TrackingStatus.ACTIVE, TrackingStatus.PAUSED]:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Tracking already exists"
                )
            # DELETED 상태면 재활성화
            existing_tracking.status = TrackingStatus.ACTIVE
            await db.commit()
            await db.refresh(existing_tracking)
            
            # 미션 진행도 업데이트 (트리거)
            try:
                from app.services.mission_service import MissionService
                from app.models.campaign import CampaignTrigger
                await MissionService.update_progress(
                    db, user_id, CampaignTrigger.TRACKING_CREATED
                )
            except Exception:
                pass
            
            return existing_tracking
        
        # 새 tracking 생성
        tracking = Tracking(
            user_id=user_id,
            pet_id=tracking_data.pet_id,
            product_id=tracking_data.product_id,
            status=TrackingStatus.ACTIVE,
        )
        
        db.add(tracking)
        try:
            await db.commit()
            await db.refresh(tracking)
        except IntegrityError:
            # 동시 요청으로 인한 중복 생성 시도 시 기존 tracking 조회
            await db.rollback()
            existing = await db.execute(
                select(Tracking).where(
                    Tracking.user_id == user_id,
                    Tracking.pet_id == tracking_data.pet_id,
                    Tracking.product_id == tracking_data.product_id
                )
            )
            existing_tracking = existing.scalar_one_or_none()
            if existing_tracking:
                # 기존 tracking이 ACTIVE/PAUSED면 에러, DELETED면 재활성화
                if existing_tracking.status == TrackingStatus.DELETED:
                    existing_tracking.status = TrackingStatus.ACTIVE
                    await db.commit()
                    await db.refresh(existing_tracking)
                    tracking = existing_tracking
                else:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="Tracking already exists"
                    )
            else:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Failed to create tracking"
                )
        
        # 미션 진행도 업데이트 (트리거)
        try:
            from app.services.mission_service import MissionService
            from app.models.campaign import CampaignTrigger
            await MissionService.update_progress(
                db, user_id, CampaignTrigger.TRACKING_CREATED
            )
        except Exception:
            # 미션 업데이트 실패해도 추적 생성은 성공 처리
            pass
        
        # 첫 추적인지 확인
        count_result = await db.execute(
            select(func.count(Tracking.id))
            .where(
                Tracking.user_id == user_id,
                Tracking.status != TrackingStatus.DELETED
            )
        )
        if count_result.scalar() == 1:
            # 첫 추적 미션 진행도 업데이트
            try:
                from app.models.campaign import CampaignTrigger
                await MissionService.update_progress(
                    db, user_id, CampaignTrigger.FIRST_TRACKING_CREATED
                )
            except Exception:
                pass
        
        return tracking
    
    @staticmethod
    async def delete_tracking(tracking_id: UUID, db: AsyncSession) -> None:
        """가격 추적 삭제 (소프트 삭제)"""
        tracking = await TrackingService.get_tracking_by_id(tracking_id, db)
        tracking.status = TrackingStatus.DELETED
        await db.commit()
