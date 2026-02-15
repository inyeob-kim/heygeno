"""미션 API 라우터"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID
from typing import Optional

from app.db.session import get_db
from app.api.deps import get_device_uid
from app.services.mission_service import MissionService
from app.services.user_service import UserService
from app.schemas.mission import MissionRead, MissionClaimResponse

router = APIRouter()


async def get_user_id_from_device_uid(
    device_uid: Optional[str],
    db: AsyncSession
) -> UUID:
    """device_uid로 user_id 조회"""
    if not device_uid:
        # TODO: 실제 인증 구현 후 수정
        # 임시로 mock user_id 반환
        from uuid import UUID
        return UUID("00000000-0000-0000-0000-000000000000")
    
    user = await UserService.get_user_by_device_uid(device_uid, db)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    return user.id


@router.get("/", response_model=list[MissionRead])
async def get_missions(
    device_uid: Optional[str] = Depends(get_device_uid),
    db: AsyncSession = Depends(get_db),
):
    """사용자의 미션 목록 조회"""
    user_id = await get_user_id_from_device_uid(device_uid, db)
    
    missions = await MissionService.get_user_missions(db, user_id)
    return missions


@router.get("/{campaign_id}", response_model=MissionRead)
async def get_mission(
    campaign_id: UUID,
    device_uid: Optional[str] = Depends(get_device_uid),
    db: AsyncSession = Depends(get_db),
):
    """특정 미션 상세 조회"""
    user_id = await get_user_id_from_device_uid(device_uid, db)
    
    mission = await MissionService.get_user_mission(db, user_id, campaign_id)
    if not mission:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="미션을 찾을 수 없습니다"
        )
    
    return mission


@router.post("/{campaign_id}/claim", response_model=MissionClaimResponse)
async def claim_mission_reward(
    campaign_id: UUID,
    device_uid: Optional[str] = Depends(get_device_uid),
    db: AsyncSession = Depends(get_db),
):
    """미션 보상 받기"""
    user_id = await get_user_id_from_device_uid(device_uid, db)
    
    result = await MissionService.claim_reward(db, user_id, campaign_id)
    return result
