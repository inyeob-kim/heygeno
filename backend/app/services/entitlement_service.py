"""
구독 권한(entitlement) 서비스 (재사용 가능한 구독 모듈)

- reconcile_user_plan: subscription_payments 기반으로 users.plan_type, plan_expire_at 갱신
- get_user_entitlement: pro 여부, plan_type, plan_expire_at 반환
"""
from datetime import datetime, timezone
from uuid import UUID
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.models.subscription_payment import SubscriptionPayment


PAID_STATUS = "PAID"


async def get_max_expires_at_for_user(db: AsyncSession, user_id: UUID) -> datetime | None:
    """PAID 상태 구독 중 expires_at 최대값"""
    result = await db.execute(
        select(func.max(SubscriptionPayment.expires_at)).where(
            SubscriptionPayment.user_id == user_id,
            SubscriptionPayment.payment_status == PAID_STATUS,
        )
    )
    return result.scalar()


async def reconcile_user_plan(db: AsyncSession, user_id: UUID) -> None:
    """
    subscription_payments의 PAID 구독을 반영해 users.plan_type, plan_expire_at 갱신.
    """
    user = await db.get(User, user_id)
    if not user:
        return
    max_expires = await get_max_expires_at_for_user(db, user_id)
    now = datetime.now(timezone.utc)
    if max_expires and max_expires > now:
        user.plan_type = "PRO"
        user.plan_expire_at = max_expires
    else:
        user.plan_type = "FREE"
        user.plan_expire_at = None
    await db.flush()


def is_pro_user(user: User) -> bool:
    """PRO 권한 여부"""
    if user.plan_type != "PRO":
        return False
    if user.plan_expire_at is None:
        return True
    return user.plan_expire_at > datetime.now(timezone.utc)


async def get_user_entitlement(db: AsyncSession, user_id: UUID) -> dict:
    """
    Returns: { "pro": bool, "plan_type": "FREE"|"PRO", "plan_expire_at": datetime|None }
    """
    user = await db.get(User, user_id)
    if not user:
        return {"pro": False, "plan_type": "FREE", "plan_expire_at": None}
    pro = is_pro_user(user)
    return {
        "pro": pro,
        "plan_type": user.plan_type,
        "plan_expire_at": user.plan_expire_at.isoformat() if user.plan_expire_at else None,
    }
