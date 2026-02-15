"""Campaign 서비스 로직"""
from typing import Optional, List, Dict, Any
from datetime import datetime
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_, func
from sqlalchemy.orm import selectinload
from fastapi import HTTPException, status
from sqlalchemy.exc import IntegrityError

from app.models.campaign import (
    Campaign, CampaignRule, CampaignAction,
    UserCampaignReward, UserCampaignImpression
)
from app.schemas.campaign import (
    CampaignCreate, CampaignUpdate,
    CampaignRuleSchema, CampaignActionSchema
)


class CampaignService:
    """Campaign 서비스"""
    
    @staticmethod
    def _calculate_status(campaign: Campaign, now: datetime) -> str:
        """파생 상태 계산"""
        from datetime import timezone
        
        if not campaign.is_enabled:
            return "DISABLED"
        
        # timezone-aware datetime으로 통일
        if now.tzinfo is None:
            now = now.replace(tzinfo=timezone.utc)
        if campaign.start_at.tzinfo is None:
            start_at = campaign.start_at.replace(tzinfo=timezone.utc)
        else:
            start_at = campaign.start_at
        if campaign.end_at.tzinfo is None:
            end_at = campaign.end_at.replace(tzinfo=timezone.utc)
        else:
            end_at = campaign.end_at
        
        if now < start_at:
            return "SCHEDULED"
        if now > end_at:
            return "EXPIRED"
        return "ACTIVE_NOW"
    
    @staticmethod
    async def get_campaigns(
        db: AsyncSession,
        key: Optional[str] = None,
        kind: Optional[str] = None,
        placement: Optional[str] = None,
        template: Optional[str] = None,
        enabled: Optional[bool] = None
    ) -> List[Campaign]:
        """캠페인 목록 조회 (필터링)"""
        query = select(Campaign).options(
            selectinload(Campaign.rules),
            selectinload(Campaign.actions)
        )
        
        conditions = []
        if key:
            conditions.append(Campaign.key.ilike(f"%{key}%"))
        if kind:
            conditions.append(Campaign.kind == kind)
        if placement:
            conditions.append(Campaign.placement == placement)
        if template:
            conditions.append(Campaign.template == template)
        if enabled is not None:
            conditions.append(Campaign.is_enabled == enabled)
        
        if conditions:
            query = query.where(and_(*conditions))
        
        # priority asc 기본 정렬
        query = query.order_by(Campaign.priority.asc(), Campaign.created_at.desc())
        
        result = await db.execute(query)
        return list(result.scalars().all())
    
    @staticmethod
    async def get_campaign_by_id(db: AsyncSession, campaign_id: UUID) -> Optional[Campaign]:
        """캠페인 상세 조회"""
        result = await db.execute(
            select(Campaign)
            .options(
                selectinload(Campaign.rules),
                selectinload(Campaign.actions)
            )
            .where(Campaign.id == campaign_id)
        )
        return result.scalar_one_or_none()
    
    @staticmethod
    async def create_campaign(db: AsyncSession, data: CampaignCreate) -> Campaign:
        """캠페인 생성 (트랜잭션 필수)"""
        try:
            # 1) campaigns insert
            campaign = Campaign(
                key=data.key,
                kind=data.kind,
                placement=data.placement,
                template=data.template,
                priority=data.priority,
                is_enabled=data.is_enabled,
                start_at=data.start_at,
                end_at=data.end_at,
                content=data.content.model_dump()
            )
            db.add(campaign)
            await db.flush()  # ID 생성
            
            # 2) campaign_rules bulk insert
            for rule_data in data.rules:
                rule = CampaignRule(
                    campaign_id=campaign.id,
                    rule=rule_data.model_dump()
                )
                db.add(rule)
            
            # 3) campaign_actions bulk insert
            for action_data in data.actions:
                action = CampaignAction(
                    campaign_id=campaign.id,
                    trigger=action_data.trigger,
                    action_type=action_data.action_type,
                    action=action_data.action
                )
                db.add(action)
            
            await db.commit()
            await db.refresh(campaign)
            
            # 관계 로드
            await db.execute(
                select(Campaign)
                .options(
                    selectinload(Campaign.rules),
                    selectinload(Campaign.actions)
                )
                .where(Campaign.id == campaign.id)
            )
            
            return campaign
            
        except IntegrityError as e:
            await db.rollback()
            if "unique constraint" in str(e).lower() or "duplicate key" in str(e).lower():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"캠페인 키 '{data.key}'는 이미 존재합니다"
                )
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"캠페인 생성 실패: {str(e)}"
            )
    
    @staticmethod
    async def update_campaign(
        db: AsyncSession,
        campaign_id: UUID,
        data: CampaignUpdate
    ) -> Campaign:
        """캠페인 수정 (전체 교체 전략)"""
        campaign = await CampaignService.get_campaign_by_id(db, campaign_id)
        if not campaign:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="캠페인을 찾을 수 없습니다"
            )
        
        try:
            # 1) campaigns update
            update_data = data.model_dump(exclude_unset=True, exclude={'rules', 'actions'})
            if 'content' in update_data and isinstance(update_data['content'], dict):
                # content는 JSONB이므로 직접 업데이트
                if hasattr(update_data['content'], 'model_dump'):
                    update_data['content'] = update_data['content'].model_dump()
            
            for key, value in update_data.items():
                if key != 'content':
                    setattr(campaign, key, value)
                else:
                    campaign.content = value
            
            # 2) campaign_rules delete where campaign_id
            result = await db.execute(
                select(CampaignRule).where(CampaignRule.campaign_id == campaign_id)
            )
            existing_rules = result.scalars().all()
            for rule in existing_rules:
                await db.delete(rule)
            
            # 3) campaign_actions delete where campaign_id
            result = await db.execute(
                select(CampaignAction).where(CampaignAction.campaign_id == campaign_id)
            )
            existing_actions = result.scalars().all()
            for action in existing_actions:
                await db.delete(action)
            
            await db.flush()
            
            # 4) 새 rules/actions insert
            if data.rules is not None:
                for rule_data in data.rules:
                    if isinstance(rule_data, CampaignRuleSchema):
                        rule_dict = rule_data.model_dump()
                    else:
                        rule_dict = rule_data
                    rule = CampaignRule(
                        campaign_id=campaign.id,
                        rule=rule_dict
                    )
                    db.add(rule)
            
            if data.actions is not None:
                for action_data in data.actions:
                    if isinstance(action_data, CampaignActionSchema):
                        trigger = action_data.trigger
                        action_type = action_data.action_type
                        action_dict = action_data.action
                    else:
                        trigger = action_data.get('trigger')
                        action_type = action_data.get('action_type')
                        action_dict = action_data.get('action', {})
                    action = CampaignAction(
                        campaign_id=campaign.id,
                        trigger=trigger,
                        action_type=action_type,
                        action=action_dict
                    )
                    db.add(action)
            
            await db.commit()
            await db.refresh(campaign)
            
            # 관계 다시 로드
            await db.execute(
                select(Campaign)
                .options(
                    selectinload(Campaign.rules),
                    selectinload(Campaign.actions)
                )
                .where(Campaign.id == campaign.id)
            )
            
            return campaign
            
        except IntegrityError as e:
            await db.rollback()
            if "unique constraint" in str(e).lower() or "duplicate key" in str(e).lower():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"캠페인 키가 이미 존재합니다"
                )
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"캠페인 수정 실패: {str(e)}"
            )
    
    @staticmethod
    async def toggle_campaign(
        db: AsyncSession,
        campaign_id: UUID,
        is_enabled: bool
    ) -> Campaign:
        """캠페인 토글 (idempotent)"""
        campaign = await CampaignService.get_campaign_by_id(db, campaign_id)
        if not campaign:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="캠페인을 찾을 수 없습니다"
            )
        
        # 같은 값 연속 호출 → 상태 유지 (idempotent)
        if campaign.is_enabled == is_enabled:
            return campaign
        
        campaign.is_enabled = is_enabled
        await db.commit()
        await db.refresh(campaign)
        
        return campaign
    
    @staticmethod
    async def simulate_campaign(
        db: AsyncSession,
        user_id: UUID,
        trigger: str,
        context: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """시뮬레이션 (실제 지급 X, rule 평가만)"""
        # 활성 캠페인 조회
        now = datetime.now(timezone.utc)
        result = await db.execute(
            select(Campaign)
            .options(
                selectinload(Campaign.rules),
                selectinload(Campaign.actions)
            )
            .where(
                and_(
                    Campaign.is_enabled == True,
                    Campaign.start_at <= now,
                    Campaign.end_at >= now
                )
            )
            .order_by(Campaign.priority.asc())
        )
        active_campaigns = list(result.scalars().all())
        
        # rule 평가 (서버 로직 - 여기서는 간단히 구현)
        eligible_campaigns = []
        for campaign in active_campaigns:
            # trigger 매칭 확인
            matching_actions = [a for a in campaign.actions if a.trigger == trigger]
            if not matching_actions:
                continue
            
            # rule 평가 (간단한 예시 - 실제로는 더 복잡한 로직 필요)
            if not campaign.rules:
                # 규칙 없음 = 전체 대상
                eligible_campaigns.append({
                    "campaign_id": str(campaign.id),
                    "campaign_key": campaign.key,
                    "action": matching_actions[0].action if matching_actions else None
                })
            else:
                # 규칙 평가 (실제 구현 필요)
                # 여기서는 항상 통과로 가정
                eligible_campaigns.append({
                    "campaign_id": str(campaign.id),
                    "campaign_key": campaign.key,
                    "action": matching_actions[0].action if matching_actions else None
                })
        
        return {
            "eligible_campaigns": eligible_campaigns,
            "action": eligible_campaigns[0]["action"] if eligible_campaigns else None
        }
    
    @staticmethod
    async def get_rewards(
        db: AsyncSession,
        user_id: Optional[UUID] = None,
        campaign_id: Optional[UUID] = None
    ) -> List[UserCampaignReward]:
        """리워드 조회"""
        query = select(UserCampaignReward).options(
            selectinload(UserCampaignReward.campaign)
        )
        
        conditions = []
        if user_id:
            conditions.append(UserCampaignReward.user_id == user_id)
        if campaign_id:
            conditions.append(UserCampaignReward.campaign_id == campaign_id)
        
        if conditions:
            query = query.where(and_(*conditions))
        
        query = query.order_by(UserCampaignReward.created_at.desc())
        
        result = await db.execute(query)
        return list(result.scalars().all())
    
    @staticmethod
    async def get_impressions(
        db: AsyncSession,
        user_id: Optional[UUID] = None,
        campaign_id: Optional[UUID] = None
    ) -> List[UserCampaignImpression]:
        """노출 조회"""
        query = select(UserCampaignImpression).options(
            selectinload(UserCampaignImpression.campaign)
        )
        
        conditions = []
        if user_id:
            conditions.append(UserCampaignImpression.user_id == user_id)
        if campaign_id:
            conditions.append(UserCampaignImpression.campaign_id == campaign_id)
        
        if conditions:
            query = query.where(and_(*conditions))
        
        query = query.order_by(UserCampaignImpression.last_seen_at.desc())
        
        result = await db.execute(query)
        return list(result.scalars().all())
