from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional
from pydantic import BaseModel

from app.db.session import get_db
from app.api.deps import get_device_uid
from app.services.user_service import UserService

router = APIRouter()


class UserResponse(BaseModel):
    """사용자 정보 응답"""
    id: str
    nickname: str
    provider_user_id: str
    
    class Config:
        from_attributes = True


@router.get("/me", response_model=UserResponse)
async def get_current_user(
    device_uid: Optional[str] = Depends(get_device_uid),
    db: AsyncSession = Depends(get_db),
):
    """현재 사용자 정보 조회 (device_uid 기반)"""
    if not device_uid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="X-Device-UID header is required"
        )
    
    # 사용자 조회
    user = await UserService.get_user_by_device_uid(device_uid, db)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    return UserResponse(
        id=str(user.id),
        nickname=user.nickname,
        provider_user_id=user.provider_user_id
    )


@router.get("/")
async def get_users(db: AsyncSession = Depends(get_db)):
    """사용자 목록 조회"""
    return {"message": "Users endpoint"}


@router.get("/{user_id}")
async def get_user(user_id: str, db: AsyncSession = Depends(get_db)):
    """사용자 상세 조회"""
    return {"message": f"User {user_id}"}

