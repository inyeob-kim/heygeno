from sqlalchemy import Column, ForeignKey, Enum as SQLEnum, UniqueConstraint, Index, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid
import enum

from app.db.base import Base, TimestampMixin


class TrackingStatus(str, enum.Enum):
    ACTIVE = "ACTIVE"
    PAUSED = "PAUSED"
    DELETED = "DELETED"


class Tracking(Base, TimestampMixin):
    __tablename__ = "trackings"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    pet_id = Column(UUID(as_uuid=True), ForeignKey("pets.id", ondelete="CASCADE"), nullable=False, index=True)
    product_id = Column(UUID(as_uuid=True), ForeignKey("products.id", ondelete="CASCADE"), nullable=False, index=True)
    status = Column(SQLEnum(TrackingStatus), default=TrackingStatus.ACTIVE, nullable=False)
    last_checked_at = Column(DateTime(timezone=True), nullable=True)  # 마지막 가격 확인 시간
    next_check_at = Column(DateTime(timezone=True), nullable=True)  # 다음 가격 확인 예정 시간

    __table_args__ = (
        UniqueConstraint('user_id', 'pet_id', 'product_id', name='uq_tracking_user_pet_product'),
        Index('idx_trackings_user', 'user_id'),
        Index('idx_trackings_pet', 'pet_id'),
        Index('idx_trackings_product', 'product_id'),
    )

    # Relationships
    user = relationship("User", back_populates="trackings")
    pet = relationship("Pet", back_populates="trackings")
    product = relationship("Product", back_populates="trackings")
    alerts = relationship("Alert", back_populates="tracking", cascade="all, delete-orphan")
