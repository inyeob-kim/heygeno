from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel

from app.db.session import get_db
from app.api.deps import get_current_user_for_me
from app.models.user import User

router = APIRouter()


class UserResponse(BaseModel):
    """사용자 정보 응답"""
    id: str
    nickname: str
    provider_user_id: str

    class Config:
        from_attributes = True


@router.get("/me", response_model=UserResponse)
async def get_me(
    user: User = Depends(get_current_user_for_me),
):
    """현재 사용자 정보 조회. Authorization Bearer 우선, 없으면 X-Device-UID."""
    return UserResponse(
        id=str(user.id),
        nickname=user.nickname,
        provider_user_id=user.provider_user_id,
    )


@router.get("/")
async def get_users(db: AsyncSession = Depends(get_db)):
    """사용자 목록 조회"""
    return {"message": "Users endpoint"}


@router.get("/{user_id}")
async def get_user(user_id: str, db: AsyncSession = Depends(get_db)):
    """사용자 상세 조회"""
    return {"message": f"User {user_id}"}

