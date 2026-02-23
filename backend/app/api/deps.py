from typing import Optional
from uuid import UUID
from fastapi import Depends, HTTPException, status, Header
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.db.session import get_db
from app.core.security import decode_access_token
from app.models.user import User


def _get_bearer_token(authorization: Optional[str] = Header(None)) -> Optional[str]:
    """Authorization: Bearer <token> 에서 token 추출"""
    if not authorization or not authorization.startswith("Bearer "):
        return None
    return authorization[7:].strip()


async def get_current_user(
    token: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
) -> Optional[User]:
    """JWT 토큰으로 사용자 반환 (Authorization: Bearer). 토큰 없으면 None."""
    if not token:
        return None
    payload = decode_access_token(token)
    if payload is None:
        return None
    user_id_raw = payload.get("sub")
    if user_id_raw is None:
        return None
    try:
        user_uuid = UUID(user_id_raw)
    except (ValueError, TypeError):
        return None
    result = await db.execute(select(User).where(User.id == user_uuid))
    return result.scalar_one_or_none()


async def get_current_user_required(
    authorization: Optional[str] = Header(None),
    db: AsyncSession = Depends(get_db),
) -> User:
    """
    Bearer 토큰 필수. Google/Apple/Email 로그인 사용자만 허용.
    토큰 없거나 유효하지 않으면 401.
    """
    token = _get_bearer_token(authorization)
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authorization Bearer token required",
        )
    user = await get_current_user(token, db)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )
    return user


async def get_current_user_for_me(
    authorization: Optional[str] = Header(None),
    db: AsyncSession = Depends(get_db),
) -> User:
    """/users/me 전용: Bearer 토큰 필수."""
    return await get_current_user_required(authorization, db)
