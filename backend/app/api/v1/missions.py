"""미션 API 라우터"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID

from app.db.session import get_db
from app.api.deps import get_current_user_required
from app.models.user import User
from app.services.mission_service import MissionService
from app.schemas.mission import MissionRead, MissionClaimResponse

router = APIRouter()


@router.get("/", response_model=list[MissionRead])
async def get_missions(
    user: User = Depends(get_current_user_required),
    db: AsyncSession = Depends(get_db),
):
    """사용자의 미션 목록 조회 (Bearer 토큰 필수)"""
    
    missions = await MissionService.get_user_missions(db, user.id)
    return missions


@router.get("/{campaign_id}", response_model=MissionRead)
async def get_mission(
    campaign_id: UUID,
    user: User = Depends(get_current_user_required),
    db: AsyncSession = Depends(get_db),
):
    """특정 미션 상세 조회 (Bearer 토큰 필수)"""
    mission = await MissionService.get_user_mission(db, user.id, campaign_id)
    if not mission:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="미션을 찾을 수 없습니다"
        )
    
    return mission


@router.post("/{campaign_id}/claim", response_model=MissionClaimResponse)
async def claim_mission_reward(
    campaign_id: UUID,
    user: User = Depends(get_current_user_required),
    db: AsyncSession = Depends(get_db),
):
    """미션 보상 받기 (Bearer 토큰 필수)"""
    result = await MissionService.claim_reward(db, user.id, campaign_id)
    return result
