from sqlalchemy import Column, String, Index, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid
import enum

from app.db.base import Base, TimestampMixin


class AuthProvider(str, enum.Enum):
    DEVICE = "DEVICE"


class User(Base, TimestampMixin):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    provider = Column(String(50), nullable=False, server_default='DEVICE')  # device_uid 기반
    provider_user_id = Column(String(255), nullable=False)  # device_uid
    nickname = Column(String(50), nullable=False)
    timezone = Column(String(50), default='Asia/Seoul', nullable=False)

    __table_args__ = (
        UniqueConstraint('provider', 'provider_user_id', name='uq_user_provider'),
        Index('idx_users_provider_user_id', 'provider', 'provider_user_id'),
        Index('idx_users_nickname', 'nickname'),
    )

    # Relationships
    pets = relationship("Pet", back_populates="user", cascade="all, delete-orphan")
    trackings = relationship("Tracking", back_populates="user", cascade="all, delete-orphan")
