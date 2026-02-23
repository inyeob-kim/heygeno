"""포인트 API 라우터"""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel

from app.db.session import get_db
from app.api.deps import get_current_user_required
from app.models.user import User
from app.services.point_service import PointService

router = APIRouter()


class PointBalanceResponse(BaseModel):
    """포인트 잔액 응답"""
    balance: int


@router.get("/balance", response_model=PointBalanceResponse)
async def get_point_balance(
    user: User = Depends(get_current_user_required),
    db: AsyncSession = Depends(get_db),
):
    """포인트 잔액 조회 (Bearer 토큰 필수)"""
    
    balance = await PointService.get_balance(db, user.id)
    return PointBalanceResponse(balance=balance)
