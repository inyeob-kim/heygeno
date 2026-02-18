"""일반 사용자용 캠페인 API 라우터"""
from fastapi import APIRouter, Depends, Query, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional, List
from datetime import datetime, timezone
import logging

from app.db.session import get_db
from app.api.deps import get_device_uid
from app.services.campaign_service import CampaignService
from app.services.user_service import UserService
from app.schemas.campaign import CampaignRead
from app.models.campaign import CampaignPlacement

logger = logging.getLogger(__name__)
router = APIRouter()


@router.get("/", response_model=List[CampaignRead])
async def get_active_campaigns(
    placement: Optional[CampaignPlacement] = Query(None, description="배치 위치 필터"),
    device_uid: Optional[str] = Depends(get_device_uid),
    db: AsyncSession = Depends(get_db),
):
    """
    활성화된 캠페인 목록 조회 (일반 사용자용)
    
    - 현재 시간 기준으로 활성화된 캠페인만 반환
    - placement 필터로 특정 위치의 캠페인만 조회 가능
    - 중복 노출 방지를 위한 impression 체크는 클라이언트에서 처리
    """
    try:
        now = datetime.now(timezone.utc)
        
        # 활성화된 캠페인만 조회
        campaigns = await CampaignService.get_campaigns(
            db=db,
            placement=placement.value if placement else None,
            enabled=True
        )
        
        # 현재 시간 기준으로 ACTIVE_NOW인 캠페인만 필터링
        active_campaigns = []
        for campaign in campaigns:
            status = CampaignService._calculate_status(campaign, now)
            if status == "ACTIVE_NOW":
                # CampaignRead로 변환
                campaign_dict = {
                    "id": campaign.id,
                    "key": campaign.key,
                    "kind": campaign.kind,
                    "placement": campaign.placement,
                    "template": campaign.template,
                    "priority": campaign.priority,
                    "is_enabled": campaign.is_enabled,
                    "start_at": campaign.start_at,
                    "end_at": campaign.end_at,
                    "content": campaign.content or {},
                    "rules": [rule.rule for rule in campaign.rules] if campaign.rules else [],
                    "actions": [
                        {
                            "trigger": action.trigger,
                            "action_type": action.action_type,
                            "action": action.action
                        }
                        for action in campaign.actions
                    ] if campaign.actions else [],
                    "status": status,
                    "created_at": campaign.created_at,
                    "updated_at": campaign.updated_at,
                }
                active_campaigns.append(CampaignRead.model_validate(campaign_dict))
        
        # priority 순으로 정렬 (낮을수록 우선)
        active_campaigns.sort(key=lambda x: (x.priority, x.created_at))
        
        logger.info(f"[Campaigns API] 활성 캠페인 {len(active_campaigns)}개 반환 (placement={placement})")
        return active_campaigns
        
    except Exception as e:
        logger.error(f"[Campaigns API] 캠페인 조회 중 오류: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"캠페인 조회 중 오류가 발생했습니다: {str(e)}"
        )
