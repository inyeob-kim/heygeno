from sqlalchemy import Column, String, Integer, Enum as SQLEnum, Index, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid
import enum

from app.db.base import Base, TimestampMixin
from app.models.offer import Merchant


class StockStatus(str, enum.Enum):
    IN_STOCK = "IN_STOCK"
    LOW_STOCK = "LOW_STOCK"
    OUT_OF_STOCK = "OUT_OF_STOCK"
    UNAVAILABLE = "UNAVAILABLE"


class ProductAvailability(Base, TimestampMixin):
    """상품 재고·지역 제한 - 신규 테이블"""
    __tablename__ = "product_availability"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    product_id = Column(UUID(as_uuid=True), ForeignKey("products.id", ondelete="CASCADE"), nullable=False, index=True)
    merchant = Column(SQLEnum(Merchant), nullable=False)
    stock_status = Column(SQLEnum(StockStatus), nullable=False)
    zip_code_restriction = Column(String(20), nullable=True)  # US 우편번호 기반 제한
    delivery_time_days = Column(Integer, nullable=True)  # 예상 배송 일수
    last_checked_at = Column(DateTime(timezone=True), nullable=False)

    __table_args__ = (
        Index('idx_product_availability_product_merchant', 'product_id', 'merchant'),
    )

    # Relationships
    product = relationship("Product", back_populates="availability")
