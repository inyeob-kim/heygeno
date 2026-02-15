"""포인트 API 라우터"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID
from typing import Optional

from app.db.session import get_db
from app.api.deps import get_device_uid
from app.services.point_service import PointService
from app.services.user_service import UserService
from pydantic import BaseModel

router = APIRouter()


async def get_user_id_from_device_uid(
    device_uid: Optional[str],
    db: AsyncSession
) -> UUID:
    """device_uid로 user_id 조회"""
    if not device_uid:
        # TODO: 실제 인증 구현 후 수정
        # 임시로 mock user_id 반환
        return UUID("00000000-0000-0000-0000-000000000000")
    
    user = await UserService.get_user_by_device_uid(device_uid, db)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    return user.id


class PointBalanceResponse(BaseModel):
    """포인트 잔액 응답"""
    balance: int


@router.get("/balance", response_model=PointBalanceResponse)
async def get_point_balance(
    device_uid: Optional[str] = Depends(get_device_uid),
    db: AsyncSession = Depends(get_db),
):
    """포인트 잔액 조회"""
    user_id = await get_user_id_from_device_uid(device_uid, db)
    
    balance = await PointService.get_balance(db, user_id)
    return PointBalanceResponse(balance=balance)
