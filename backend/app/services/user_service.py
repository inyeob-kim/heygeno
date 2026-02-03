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
    
    @staticmethod
    async def get_user_by_device_uid(device_uid: str, db: AsyncSession) -> User | None:
        """Device UID로 사용자 조회"""
        from app.models.user import AuthProvider
        result = await db.execute(
            select(User).where(
                User.provider == AuthProvider.DEVICE,
                User.provider_user_id == device_uid
            )
        )
        return result.scalar_one_or_none()
    
    @staticmethod
    async def get_or_create_user_by_device_uid(
        device_uid: str,
        nickname: str,
        db: AsyncSession
    ) -> User:
        """Device UID로 사용자 조회 또는 생성"""
        user = await UserService.get_user_by_device_uid(device_uid, db)
        
        if user is None:
            user = User(
                provider='DEVICE',
                provider_user_id=device_uid,
                nickname=nickname,
            )
            db.add(user)
            await db.commit()
            await db.refresh(user)
        else:
            # 닉네임 업데이트
            if user.nickname != nickname:
                user.nickname = nickname
                await db.commit()
                await db.refresh(user)
        
        return user
