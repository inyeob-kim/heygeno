"""미션 서비스"""
from typing import List, Optional, Dict, Any
from uuid import UUID
from datetime import datetime, timezone
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, func, update
from sqlalchemy.orm import selectinload
from fastapi import HTTPException, status

from app.models.campaign import (
    Campaign, CampaignAction, UserMissionProgress, MissionProgressStatus,
    UserCampaignReward, CampaignKind, CampaignTrigger
)
from app.models.point import PointWallet, PointLedger
from app.services.point_service import PointService


class MissionService:
    """미션 서비스"""
    
    @staticmethod
    async def get_user_missions(
        db: AsyncSession,
        user_id: UUID
    ) -> List[Dict[str, Any]]:
        """사용자의 미션 목록 조회"""
        now = datetime.now(timezone.utc)
        
        # 활성 미션 조회
        query = (
            select(Campaign)
            .options(selectinload(Campaign.actions))
            .where(
                Campaign.kind == CampaignKind.MISSION,
                Campaign.is_enabled == True,
                func.now().between(Campaign.start_at, Campaign.end_at)
            )
            .order_by(Campaign.priority.asc(), Campaign.created_at.desc())
        )
        
        result = await db.execute(query)
        campaigns = result.scalars().all()
        
        # 사용자 진행도 조회
        progress_query = select(UserMissionProgress).where(
            UserMissionProgress.user_id == user_id,
            UserMissionProgress.campaign_id.in_([c.id for c in campaigns])
        )
        progress_result = await db.execute(progress_query)
        progress_map = {p.campaign_id: p for p in progress_result.scalars().all()}
        
        missions = []
        for campaign in campaigns:
            progress = progress_map.get(campaign.id)
            
            # content에서 미션 정보 추출
            content = campaign.content or {}
            target_value = content.get('target_value', 1)
            reward_points = content.get('reward_points', 0)
            
            # 진행도 계산
            current_value = progress.current_value if progress else 0
            status_value = progress.status if progress else MissionProgressStatus.IN_PROGRESS
            completed = status_value in [MissionProgressStatus.COMPLETED, MissionProgressStatus.CLAIMED]
            can_claim = (
                status_value == MissionProgressStatus.COMPLETED and
                (progress is None or progress.claimed_at is None)
            )
            
            missions.append({
                "id": str(campaign.id),
                "campaign_id": str(campaign.id),
                "title": content.get('title', ''),
                "description": content.get('description', ''),
                "reward_points": reward_points,
                "current_value": current_value,
                "target_value": target_value,
                "status": status_value,
                "completed": completed,
                "can_claim": can_claim,
                "completed_at": progress.completed_at.isoformat() if progress and progress.completed_at else None,
                "started_at": progress.started_at.isoformat() if progress and progress.started_at else None,
            })
        
        return missions
    
    @staticmethod
    async def get_user_mission(
        db: AsyncSession,
        user_id: UUID,
        campaign_id: UUID
    ) -> Optional[Dict[str, Any]]:
        """특정 미션 상세 조회"""
        # 캠페인 조회
        result = await db.execute(
            select(Campaign)
            .options(selectinload(Campaign.actions))
            .where(Campaign.id == campaign_id)
        )
        campaign = result.scalar_one_or_none()
        
        if not campaign or campaign.kind != CampaignKind.MISSION:
            return None
        
        # 진행도 조회
        progress_result = await db.execute(
            select(UserMissionProgress).where(
                UserMissionProgress.user_id == user_id,
                UserMissionProgress.campaign_id == campaign_id
            )
        )
        progress = progress_result.scalar_one_or_none()
        
        content = campaign.content or {}
        target_value = content.get('target_value', 1)
        reward_points = content.get('reward_points', 0)
        
        current_value = progress.current_value if progress else 0
        status_value = progress.status if progress else MissionProgressStatus.IN_PROGRESS
        completed = status_value in [MissionProgressStatus.COMPLETED, MissionProgressStatus.CLAIMED]
        can_claim = (
            status_value == MissionProgressStatus.COMPLETED and
            (progress is None or progress.claimed_at is None)
        )
        
        return {
            "id": str(campaign.id),
            "campaign_id": str(campaign.id),
            "title": content.get('title', ''),
            "description": content.get('description', ''),
            "reward_points": reward_points,
            "current_value": current_value,
            "target_value": target_value,
            "status": status_value,
            "completed": completed,
            "can_claim": can_claim,
            "completed_at": progress.completed_at.isoformat() if progress and progress.completed_at else None,
            "started_at": progress.started_at.isoformat() if progress else None,
        }
    
    @staticmethod
    async def update_progress(
        db: AsyncSession,
        user_id: UUID,
        trigger: CampaignTrigger,
        context: Optional[Dict[str, Any]] = None
    ) -> None:
        """트리거 발생 시 미션 진행도 업데이트 및 즉시 보상 지급"""
        now = datetime.now(timezone.utc)
        
        # 해당 트리거를 가진 활성 캠페인 조회 (MISSION + EVENT 모두 처리)
        query = (
            select(Campaign)
            .options(selectinload(Campaign.actions), selectinload(Campaign.rules))
            .join(CampaignAction)
            .where(
                Campaign.kind.in_([CampaignKind.MISSION, CampaignKind.EVENT]),
                Campaign.is_enabled == True,
                CampaignAction.trigger == trigger.value,
                func.now().between(Campaign.start_at, Campaign.end_at)
            )
            .order_by(Campaign.priority.asc())
        )
        
        result = await db.execute(query)
        campaigns = result.scalars().all()
        
        for campaign in campaigns:
            # CampaignRule 평가 (간단한 구현 - 필요시 확장)
            # 현재는 규칙이 없으면 통과
            if campaign.rules:
                # TODO: 규칙 평가 로직 구현
                pass
            
            # 해당 트리거의 모든 액션 찾기
            matching_actions = [
                a for a in campaign.actions 
                if a.trigger == trigger.value
            ]
            
            if not matching_actions:
                continue
            
            # 각 액션 타입별로 처리
            for action in matching_actions:
                action_type = action.action_type
                action_data = action.action or {}
                
                # 1. GRANT_POINTS 액션 처리 (즉시 포인트 지급)
                if action_type == "GRANT_POINTS":
                    # 중복 지급 방지 체크
                    reward_check = await db.execute(
                        select(UserCampaignReward).where(
                            UserCampaignReward.user_id == user_id,
                            UserCampaignReward.campaign_id == campaign.id,
                            UserCampaignReward.action_id == action.id
                        )
                    )
                    existing_reward = reward_check.scalar_one_or_none()
                    
                    if existing_reward:
                        # 이미 지급됨 → 스킵
                        continue
                    
                    # 포인트 지급
                    points = action_data.get('points', 0)
                    if points > 0:
                        await PointService.grant_points(
                            db=db,
                            user_id=user_id,
                            points=points,
                            reason=f"campaign:{campaign.key}",
                            ref_type="campaign_reward",
                            ref_id=campaign.id
                        )
                    
                    # 보상 기록
                    reward = UserCampaignReward(
                        user_id=user_id,
                        campaign_id=campaign.id,
                        action_id=action.id,
                        status="GRANTED",
                        granted_at=now
                    )
                    db.add(reward)
                    await db.commit()
                
                # 2. UPDATE_PROGRESS 액션 처리 (미션 진행도 업데이트)
                elif action_type == "UPDATE_PROGRESS":
                    increment = action_data.get('progress_increment', 1)
                    auto_claim = action_data.get('auto_claim', False)
                    
                    # 진행도 조회 또는 생성
                    progress_result = await db.execute(
                        select(UserMissionProgress).where(
                            UserMissionProgress.user_id == user_id,
                            UserMissionProgress.campaign_id == campaign.id
                        )
                    )
                    progress = progress_result.scalar_one_or_none()
                    
                    content = campaign.content or {}
                    target_value = content.get('target_value', 1)
                    
                    if not progress:
                        # 새로 시작
                        progress = UserMissionProgress(
                            user_id=user_id,
                            campaign_id=campaign.id,
                            current_value=increment,
                            target_value=target_value,
                            status=MissionProgressStatus.IN_PROGRESS
                        )
                        db.add(progress)
                    else:
                        # 진행도 증가
                        progress.current_value += increment
                        
                        # 완료 체크
                        if progress.current_value >= progress.target_value:
                            progress.status = MissionProgressStatus.COMPLETED
                            progress.completed_at = now
                            
                            # auto_claim이면 즉시 지급
                            if auto_claim:
                                await MissionService._grant_reward(
                                    db, user_id, campaign, action
                                )
                                progress.status = MissionProgressStatus.CLAIMED
                                progress.claimed_at = now
                    
                    await db.commit()
                    await db.refresh(progress)
    
    @staticmethod
    async def claim_reward(
        db: AsyncSession,
        user_id: UUID,
        campaign_id: UUID
    ) -> Dict[str, Any]:
        """미션 보상 받기"""
        now = datetime.now(timezone.utc)
        
        # 캠페인 조회
        result = await db.execute(
            select(Campaign)
            .options(selectinload(Campaign.actions))
            .where(Campaign.id == campaign_id)
        )
        campaign = result.scalar_one_or_none()
        
        if not campaign or campaign.kind != CampaignKind.MISSION:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="미션을 찾을 수 없습니다"
            )
        
        # 진행도 확인
        progress_result = await db.execute(
            select(UserMissionProgress).where(
                UserMissionProgress.user_id == user_id,
                UserMissionProgress.campaign_id == campaign_id,
                UserMissionProgress.status == MissionProgressStatus.COMPLETED
            )
        )
        progress = progress_result.scalar_one_or_none()
        
        if not progress:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="완료된 미션이 없습니다"
            )
        
        if progress.claimed_at is not None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="이미 보상을 받았습니다"
            )
        
        # 중복 지급 방지 체크
        reward_check = await db.execute(
            select(UserCampaignReward).where(
                UserCampaignReward.user_id == user_id,
                UserCampaignReward.campaign_id == campaign_id
            )
        )
        if reward_check.scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="이미 보상을 받았습니다"
            )
        
        # 보상 지급
        action = campaign.actions[0] if campaign.actions else None
        if not action:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="미션 액션이 없습니다"
            )
        
        content = campaign.content or {}
        reward_points = content.get('reward_points', 0)
        
        if reward_points > 0:
            # 포인트 지급
            await PointService.grant_points(
                db=db,
                user_id=user_id,
                points=reward_points,
                reason=f"campaign:{campaign.key}",
                ref_type="mission_reward",
                ref_id=campaign_id
            )
        
        # 보상 기록
        reward = UserCampaignReward(
            user_id=user_id,
            campaign_id=campaign_id,
            action_id=action.id,
            status="GRANTED",
            granted_at=now
        )
        db.add(reward)
        
        # 진행도 상태 업데이트
        progress.status = MissionProgressStatus.CLAIMED
        progress.claimed_at = now
        
        await db.commit()
        
        return {
            "success": True,
            "reward_points": reward_points,
            "message": f"{reward_points}P가 지급되었습니다"
        }
    
    @staticmethod
    async def _grant_reward(
        db: AsyncSession,
        user_id: UUID,
        campaign: Campaign,
        action: CampaignAction
    ) -> None:
        """내부용: 보상 지급"""
        content = campaign.content or {}
        reward_points = content.get('reward_points', 0)
        
        if reward_points > 0:
            await PointService.grant_points(
                db=db,
                user_id=user_id,
                points=reward_points,
                reason=f"campaign:{campaign.key}",
                ref_type="mission_reward",
                ref_id=campaign.id
            )
        
        # 보상 기록
        reward = UserCampaignReward(
            user_id=user_id,
            campaign_id=campaign.id,
            action_id=action.id,
            status="GRANTED",
            granted_at=datetime.now(timezone.utc)
        )
        db.add(reward)
