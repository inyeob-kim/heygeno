"""사용자 및 인증 관련 모델 (재사용 가능한 인증·구독 모듈)"""
from sqlalchemy import Column, String, Boolean, Index, UniqueConstraint, DateTime, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from sqlalchemy import func
import uuid
import enum

from app.db.base import Base, TimestampMixin


class AuthProvider(str, enum.Enum):
    """인증 제공자 (소셜·이메일·디바이스)"""
    DEVICE = "DEVICE"
    GOOGLE = "GOOGLE"
    APPLE = "APPLE"
    NAVER = "NAVER"
    EMAIL = "EMAIL"  # Firebase 이메일/비밀번호


class UserStatus(str, enum.Enum):
    """계정 상태"""
    ACTIVE = "active"
    WITHDRAWN = "withdrawn"
    PENDING = "pending"


class PlanType(str, enum.Enum):
    """구독 플랜 타입"""
    FREE = "FREE"
    PRO = "PRO"


class User(Base, TimestampMixin):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    provider = Column(String(50), nullable=False, server_default="DEVICE")
    provider_user_id = Column(String(255), nullable=False)  # OAuth sub / device_uid
    firebase_uid = Column(String(128), nullable=True, unique=True)  # Firebase UID (이메일/Google/Apple)
    email = Column(String(255), nullable=True)
    email_verified = Column(Boolean, nullable=False, server_default="false")  # EMAIL signup 시 검증 전 false
    password_hash = Column(String(255), nullable=True)  # EMAIL provider 전용
    nickname = Column(String(50), nullable=False, server_default="User")
    timezone = Column(String(50), default="America/New_York", nullable=False)

    # 계정 상태 (탈퇴·복구)
    status = Column(String(20), nullable=False, server_default="active")
    withdrawn_at = Column(DateTime(timezone=True), nullable=True)

    # 구독 (인앱 구매)
    plan_type = Column(String(20), nullable=False, server_default="FREE")
    plan_expire_at = Column(DateTime(timezone=True), nullable=True)

    __table_args__ = (
        UniqueConstraint("provider", "provider_user_id", name="uq_user_provider"),
        Index("idx_users_provider_user_id", "provider", "provider_user_id"),
        Index("idx_users_nickname", "nickname"),
        Index("idx_users_firebase_uid", "firebase_uid"),
        Index("idx_users_status", "status"),
    )

    pets = relationship("Pet", back_populates="user", cascade="all, delete-orphan")
    trackings = relationship("Tracking", back_populates="user", cascade="all, delete-orphan")
    user_tokens = relationship("UserToken", back_populates="user", cascade="all, delete-orphan")
    subscription_payments = relationship(
        "SubscriptionPayment", back_populates="user", cascade="all, delete-orphan"
    )
