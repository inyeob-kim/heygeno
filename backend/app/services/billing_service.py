"""
구독 결제 서비스 (재사용 가능한 구독 모듈)

- record_or_update_subscription_payment: 영수증 검증 결과를 subscription_payments에 UPSERT
- Idempotent: (platform, transaction_id) 동일 시 기존 레코드 갱신
"""
from datetime import datetime, timezone
from uuid import UUID
from decimal import Decimal
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.subscription_payment import SubscriptionPayment
from app.services.entitlement_service import reconcile_user_plan


async def record_or_update_subscription_payment(
    db: AsyncSession,
    user_id: UUID,
    platform: str,
    transaction_id: str,
    product_id: str,
    payment_status: str,
    expires_at: datetime,
    *,
    amount: Decimal = Decimal("0"),
    currency: str = "KRW",
    purchase_token: str | None = None,
    original_transaction_id: str | None = None,
    environment: str = "prod",
    raw_receipt: dict | None = None,
) -> tuple[SubscriptionPayment, bool]:
    """
    subscription_payments에 UPSERT.
    Returns: (payment, was_created)
    """
    result = await db.execute(
        select(SubscriptionPayment).where(
            SubscriptionPayment.platform == platform,
            SubscriptionPayment.transaction_id == transaction_id,
        )
    )
    existing = result.scalar_one_or_none()
    now = datetime.now(timezone.utc)
    if existing:
        existing.payment_status = payment_status
        existing.expires_at = expires_at
        existing.last_verified_at = now
        existing.processed_at = now
        if raw_receipt is not None:
            existing.raw_receipt = raw_receipt
        await db.flush()
        await db.refresh(existing)
        await reconcile_user_plan(db, user_id)
        return existing, False
    payment = SubscriptionPayment(
        user_id=user_id,
        transaction_id=transaction_id,
        platform=platform,
        product_id=product_id,
        amount=amount,
        currency=currency,
        payment_status=payment_status,
        payment_date=now,
        expires_at=expires_at,
        processed_at=now,
        last_verified_at=now,
        purchase_token=purchase_token,
        original_transaction_id=original_transaction_id,
        environment=environment,
        raw_receipt=raw_receipt,
    )
    db.add(payment)
    await db.flush()
    await db.refresh(payment)
    await reconcile_user_plan(db, user_id)
    return payment, True
