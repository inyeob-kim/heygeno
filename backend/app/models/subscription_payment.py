"""인앱 구독 결제 이력 (재사용 가능한 구독 모듈)"""
from sqlalchemy import Column, String, DateTime, Numeric, UniqueConstraint, Index, Text, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from sqlalchemy import func
import uuid
import enum

from app.db.base import Base, TimestampMixin


class PaymentPlatform(str, enum.Enum):
    IOS = "ios"
    ANDROID = "android"


class SubscriptionPaymentStatus(str, enum.Enum):
    PAID = "PAID"
    REFUNDED = "REFUNDED"
    FAILED = "FAILED"


class SubscriptionPayment(Base, TimestampMixin):
    __tablename__ = "subscription_payments"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    transaction_id = Column(String(128), nullable=False)
    platform = Column(String(20), nullable=False)  # ios, android
    product_id = Column(String(64), nullable=False)
    amount = Column(Numeric(10, 2), nullable=False, server_default="0")
    currency = Column(String(10), nullable=False, server_default="KRW")
    payment_status = Column(String(20), nullable=False, server_default="PAID")
    payment_date = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    expires_at = Column(DateTime(timezone=True), nullable=False)
    processed_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    last_verified_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    purchase_token = Column(Text, nullable=True)
    original_transaction_id = Column(String(128), nullable=True)
    environment = Column(String(16), nullable=False, server_default="prod")
    raw_receipt = Column(JSONB, nullable=True)

    __table_args__ = (
        UniqueConstraint("platform", "transaction_id", name="uq_subscription_platform_transaction"),
        Index("idx_subscription_payments_user_expires", "user_id", "expires_at"),
        Index("idx_subscription_payments_status", "payment_status"),
    )

    user = relationship("User", back_populates="subscription_payments")
