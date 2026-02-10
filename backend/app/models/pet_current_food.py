from sqlalchemy import Column, String, Boolean, ForeignKey, Enum as SQLEnum, Index, Integer, SmallInteger, CheckConstraint, DateTime, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid
import enum

from app.db.base import Base, TimestampMixin


class FeedType(str, enum.Enum):
    MAIN = "MAIN"
    SUB = "SUB"


class DailyAmountLevel(str, enum.Enum):
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"


class TreatsLevel(str, enum.Enum):
    NONE = "NONE"
    SOME = "SOME"
    OFTEN = "OFTEN"


class PetCurrentFood(Base, TimestampMixin):
    """반려동물 현재 급여 사료"""
    __tablename__ = "pet_current_foods"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    pet_id = Column(UUID(as_uuid=True), ForeignKey("pets.id", ondelete="CASCADE"), nullable=False, index=True)
    product_id = Column(UUID(as_uuid=True), ForeignKey("products.id", ondelete="RESTRICT"), nullable=False, index=True)

    feed_type = Column(String(10), nullable=False)  # 'MAIN' | 'SUB'
    is_active = Column(Boolean, nullable=False, server_default='true')

    started_at = Column(DateTime(timezone=True), nullable=True)
    ended_at = Column(DateTime(timezone=True), nullable=True)

    # 급여량(옵션, MVP)
    meals_per_day = Column(SmallInteger, nullable=True)  # 1~4
    daily_amount_level = Column(String(10), nullable=True)  # 'LOW'|'MEDIUM'|'HIGH'
    treats_level = Column(String(10), nullable=True)  # 'NONE'|'SOME'|'OFTEN'
    estimated_days_per_bag = Column(Integer, nullable=True)  # 사용자 입력(봉지당 며칠)
    last_confirmed_at = Column(DateTime(timezone=True), nullable=True)  # 사용자가 최신이라고 확인한 시각

    __table_args__ = (
        CheckConstraint('meals_per_day IS NULL OR meals_per_day BETWEEN 1 AND 4', name='chk_meals_per_day'),
        CheckConstraint('estimated_days_per_bag IS NULL OR estimated_days_per_bag BETWEEN 1 AND 365', name='chk_estimated_days'),
        CheckConstraint('ended_at IS NULL OR started_at IS NULL OR ended_at >= started_at', name='chk_ended_after_started'),
        Index('idx_pcf_pet_active', 'pet_id', 'is_active'),
        Index('idx_pcf_product_active', 'product_id', 'is_active'),
        Index('idx_pcf_pet_feedtype_active', 'pet_id', 'feed_type', 'is_active'),
        # Partial unique index: 활성 MAIN은 1개만
        Index('uq_pcf_pet_main_active', 'pet_id', unique=True, postgresql_where=text("is_active = true AND feed_type = 'MAIN'")),
        # Partial unique index: 활성 SUB도 1개만
        Index('uq_pcf_pet_sub_active', 'pet_id', unique=True, postgresql_where=text("is_active = true AND feed_type = 'SUB'")),
    )

    # Relationships
    pet = relationship("Pet", back_populates="current_foods")
    product = relationship("Product", back_populates="current_foods")
