"""
구독(결제) API (재사용 가능한 구독 모듈)

- POST /billing/verify: 영수증 검증 및 구독 권한 갱신
- GET /billing/me/entitlements: 현재 사용자 구독 권한
- GET /billing/products: 플랫폼별 상품 ID
"""
from datetime import datetime, timezone
from uuid import UUID
from fastapi import APIRouter, Depends, Query, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.core.config import settings
from app.services.billing_service import record_or_update_subscription_payment
from app.services.entitlement_service import get_user_entitlement

router = APIRouter()


class VerifyRequest(BaseModel):
    platform: str  # ios | android
    product_id: str
    receipt_or_token: str
    transaction_id: str
    original_transaction_id: str | None = None
    amount: float = 0.0
    currency: str = "KRW"


class VerifyResponse(BaseModel):
    entitlement: dict
    payment_recorded: bool


def _verify_receipt_stub(platform: str, receipt_or_token: str, product_id: str) -> dict:
    """
    스텁: 실제로는 App Store Server API / Google Play API 호출.
    Returns: { "status": "PAID"|"REFUNDED"|"FAILED", "expires_at": datetime, "transaction_id": str }
    """
    # 개발용: 항상 PAID, 만료 1달 후
    from datetime import timedelta
    exp = datetime.now(timezone.utc) + timedelta(days=30)
    return {
        "status": "PAID",
        "expires_at": exp,
        "transaction_id": "stub_" + str(int(exp.timestamp())),
    }


@router.post("/verify", response_model=VerifyResponse)
async def post_verify(
    user_id: str = Query(..., alias="user_id"),
    body: VerifyRequest = ...,
    db: AsyncSession = Depends(get_db),
):
    """
    영수증 검증 후 subscription_payments UPSERT, user plan 갱신.
    Idempotent: 동일 (platform, transaction_id) 시 200 + 기존 entitlement 반환.
    """
    try:
        uid = UUID(user_id)
    except ValueError:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid user_id")
    # Idempotency: 이미 처리된 transaction이면 갱신만 하고 반환
    verification = _verify_receipt_stub(body.platform, body.receipt_or_token, body.product_id)
    if verification["status"] == "FAILED":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Receipt verification failed")
    expires_at = verification["expires_at"]
    if isinstance(expires_at, datetime) and expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)
    payment, was_created = await record_or_update_subscription_payment(
        db,
        user_id=uid,
        platform=body.platform,
        transaction_id=body.transaction_id or verification.get("transaction_id", ""),
        product_id=body.product_id,
        payment_status=verification["status"],
        expires_at=expires_at,
        amount=body.amount,
        currency=body.currency,
        purchase_token=body.receipt_or_token if body.platform == "android" else None,
        original_transaction_id=body.original_transaction_id,
        raw_receipt={"stub": True},
    )
    await db.commit()
    entitlement = await get_user_entitlement(db, uid)
    return VerifyResponse(entitlement=entitlement, payment_recorded=was_created)


@router.get("/me/entitlements")
async def get_entitlements(
    user_id: str = Query(..., alias="user_id"),
    db: AsyncSession = Depends(get_db),
):
    """현재 사용자 구독 권한 (pro, plan_type, plan_expire_at)"""
    try:
        uid = UUID(user_id)
    except ValueError:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid user_id")
    return await get_user_entitlement(db, uid)


@router.get("/products")
async def get_products():
    """플랫폼별 상품 ID (앱에서 IAP 상품 로드용)"""
    return {
        "ios_product_id": settings.IOS_PRODUCT_ID or "pro_monthly",
        "android_product_id": settings.ANDROID_PRODUCT_ID or "pro_monthly",
    }
