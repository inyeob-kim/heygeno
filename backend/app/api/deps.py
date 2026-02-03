from typing import Optional
from fastapi import Depends, HTTPException, status, Header
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.db.session import get_db
from app.core.security import decode_access_token
from app.models.user import User


async def get_device_uid(
    x_device_uid: Optional[str] = Header(None, alias="X-Device-UID"),
) -> Optional[str]:
    """X-Device-UID 헤더에서 device_uid 추출"""
    return x_device_uid


async def get_current_user(
    token: Optional[str] = None,
    db: AsyncSession = Depends(get_db)
) -> Optional[User]:
    """현재 인증된 사용자 반환"""
    # TODO: 실제 토큰 추출 로직 구현 필요 (Header에서)
    if not token:
        return None
    
    payload = decode_access_token(token)
    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials"
        )
    
    user_id: str = payload.get("sub")
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials"
        )
    
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found"
        )
    
    return user
