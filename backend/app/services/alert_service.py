"""알림 관련 비즈니스 로직"""
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException, status

from app.models.alert import Alert
from app.schemas.alert import AlertCreate


class AlertService:
    """알림 서비스 - 알림 관련 비즈니스 로직만 담당"""
    
    @staticmethod
    async def get_alerts_by_user_id(user_id: UUID, db: AsyncSession) -> list[Alert]:
        """사용자 ID로 알림 목록 조회"""
        # Tracking을 통해 user_id로 필터링
        from app.models.tracking import Tracking
        
        result = await db.execute(
            select(Alert)
            .join(Tracking)
            .where(
                Tracking.user_id == user_id,
                Alert.is_enabled == True
            )
        )
        return list(result.scalars().all())
    
    @staticmethod
    async def get_alert_by_id(alert_id: UUID, db: AsyncSession) -> Alert:
        """알림 ID로 조회"""
        result = await db.execute(select(Alert).where(Alert.id == alert_id))
        alert = result.scalar_one_or_none()
        
        if alert is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Alert not found"
            )
        
        return alert
    
    @staticmethod
    async def create_alert(
        alert_data: AlertCreate,
        db: AsyncSession
    ) -> Alert:
        """알림 생성"""
        # Tracking 존재 확인
        from app.models.tracking import Tracking
        
        tracking_result = await db.execute(
            select(Tracking).where(Tracking.id == alert_data.tracking_id)
        )
        tracking = tracking_result.scalar_one_or_none()
        
        if tracking is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Tracking not found"
            )
        
        alert = Alert(
            tracking_id=alert_data.tracking_id,
            rule_type=alert_data.rule_type,
            target_price=alert_data.target_price,
            cooldown_hours=alert_data.cooldown_hours or 24,
            is_enabled=True,
        )
        
        db.add(alert)
        await db.commit()
        await db.refresh(alert)
        
        # 미션 진행도 업데이트 (트리거)
        try:
            from app.services.mission_service import MissionService
            from app.models.campaign import CampaignTrigger
            from app.models.tracking import Tracking
            
            # tracking에서 user_id 가져오기
            tracking_result = await db.execute(
                select(Tracking).where(Tracking.id == alert_data.tracking_id)
            )
            tracking = tracking_result.scalar_one_or_none()
            
            if tracking:
                await MissionService.update_progress(
                    db, tracking.user_id, CampaignTrigger.ALERT_CREATED
                )
        except Exception as e:
            # 미션 업데이트 실패해도 알림 생성은 성공 처리
            pass
        
        return alert
    
    @staticmethod
    async def mark_alert_read(alert_id: UUID, db: AsyncSession) -> Alert:
        """알림 읽음 처리"""
        alert = await AlertService.get_alert_by_id(alert_id, db)
        # TODO: alert_events 테이블에 읽음 이벤트 기록
        return alert
