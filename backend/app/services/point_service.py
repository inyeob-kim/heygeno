"""포인트 서비스"""
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from fastapi import HTTPException, status

from app.models.point import PointWallet, PointLedger


class PointService:
    """포인트 서비스"""
    
    @staticmethod
    async def get_balance(db: AsyncSession, user_id: UUID) -> int:
        """사용자 포인트 잔액 조회"""
        result = await db.execute(
            select(PointWallet)
            .where(PointWallet.user_id == user_id)
        )
        wallet = result.scalar_one_or_none()
        
        if wallet is None:
            # 지갑이 없으면 생성
            wallet = PointWallet(user_id=user_id, balance=0)
            db.add(wallet)
            await db.commit()
            await db.refresh(wallet)
            return 0
        
        return wallet.balance
    
    @staticmethod
    async def grant_points(
        db: AsyncSession,
        user_id: UUID,
        points: int,
        reason: str,
        ref_type: str = None,
        ref_id: UUID = None
    ) -> PointLedger:
        """포인트 지급"""
        if points <= 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="포인트는 양수여야 합니다"
            )
        
        # 지갑 조회 또는 생성
        wallet_result = await db.execute(
            select(PointWallet).where(PointWallet.user_id == user_id)
        )
        wallet = wallet_result.scalar_one_or_none()
        
        if wallet is None:
            wallet = PointWallet(user_id=user_id, balance=0)
            db.add(wallet)
            await db.flush()
        
        # 잔액 증가
        wallet.balance += points
        
        # 장부 기록
        ledger = PointLedger(
            user_id=user_id,
            delta=points,
            reason=reason,
            ref_type=ref_type,
            ref_id=ref_id
        )
        db.add(ledger)
        
        await db.commit()
        await db.refresh(ledger)
        
        return ledger
    
    @staticmethod
    async def deduct_points(
        db: AsyncSession,
        user_id: UUID,
        points: int,
        reason: str,
        ref_type: str = None,
        ref_id: UUID = None
    ) -> PointLedger:
        """포인트 차감"""
        if points <= 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="포인트는 양수여야 합니다"
            )
        
        # 지갑 조회
        wallet_result = await db.execute(
            select(PointWallet).where(PointWallet.user_id == user_id)
        )
        wallet = wallet_result.scalar_one_or_none()
        
        if wallet is None or wallet.balance < points:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="포인트가 부족합니다"
            )
        
        # 잔액 감소
        wallet.balance -= points
        
        # 장부 기록
        ledger = PointLedger(
            user_id=user_id,
            delta=-points,
            reason=reason,
            ref_type=ref_type,
            ref_id=ref_id
        )
        db.add(ledger)
        
        await db.commit()
        await db.refresh(ledger)
        
        return ledger
    
    @staticmethod
    async def get_ledger_history(
        db: AsyncSession,
        user_id: UUID,
        limit: int = 50
    ) -> list[PointLedger]:
        """포인트 이력 조회"""
        result = await db.execute(
            select(PointLedger)
            .where(PointLedger.user_id == user_id)
            .order_by(PointLedger.created_at.desc())
            .limit(limit)
        )
        return list(result.scalars().all())
