"""사용자 관련 비즈니스 로직"""
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException, status

from app.models.user import User


class UserService:
    """사용자 서비스 - 사용자 관련 비즈니스 로직만 담당"""
    
    @staticmethod
    async def get_user_by_id(user_id: UUID, db: AsyncSession) -> User:
        """사용자 ID로 조회"""
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        return user
