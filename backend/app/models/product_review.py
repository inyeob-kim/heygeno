from sqlalchemy import Column, String, Integer, Enum as SQLEnum, Index, CheckConstraint, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from sqlalchemy.types import Numeric
import uuid
import enum

from app.db.base import Base, TimestampMixin
from app.models.offer import Merchant


class ProductReview(Base, TimestampMixin):
    """상품 리뷰 - 신규 테이블"""
    __tablename__ = "product_reviews"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    product_id = Column(UUID(as_uuid=True), ForeignKey("products.id", ondelete="CASCADE"), nullable=False, index=True)
    merchant = Column(SQLEnum(Merchant), nullable=False)
    average_rating = Column(Numeric(3, 2), nullable=False)  # 1.0-5.0
    review_count = Column(Integer, nullable=False)
    last_fetched_at = Column(DateTime(timezone=True), nullable=False)
    top_reviews = Column(JSONB, nullable=True)  # 상위 리뷰 스니펫 배열

    __table_args__ = (
        Index('idx_product_reviews_product_merchant', 'product_id', 'merchant'),
        CheckConstraint('average_rating BETWEEN 1.0 AND 5.0', name='product_reviews_rating_check'),
    )

    # Relationships
    product = relationship("Product", back_populates="reviews")
