from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Index, Boolean
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

from app.db.base import Base


class PriceSnapshot(Base):
    """가격 스냅샷 - final_price를 표준으로"""
    __tablename__ = "price_snapshots"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    offer_id = Column(UUID(as_uuid=True), ForeignKey("product_offers.id", ondelete="CASCADE"), nullable=False, index=True)
    
    # 가격 구성 요소
    listed_price = Column(Integer, nullable=False)  # 페이지에 표시된 가격
    shipping_fee = Column(Integer, nullable=False, server_default='0')
    coupon_discount = Column(Integer, nullable=False, server_default='0')
    card_discount = Column(Integer, nullable=False, server_default='0')
    
    # 최종 가격 (표준 "비교값")
    final_price = Column(Integer, nullable=False)  # listed + shipping - discounts
    currency = Column(String(3), default='KRW', nullable=False)
    
    is_sold_out = Column(Boolean, nullable=False, server_default='false')
    captured_at = Column(DateTime(timezone=True), nullable=False)
    captured_source = Column(String(50), nullable=False, server_default='COUPANG_API')  # 가격 스냅샷 출처
    meta = Column(JSONB, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    __table_args__ = (
        Index('idx_price_snapshots_offer_time', 'offer_id', 'captured_at', postgresql_ops={'captured_at': 'DESC'}),
        Index('idx_price_snapshots_offer_final', 'offer_id', 'final_price'),
    )

    # Relationships
    offer = relationship("ProductOffer", back_populates="price_snapshots")


class PriceSummary(Base):
    """가격 요약 - window별 캐시"""
    __tablename__ = "price_summaries"

    offer_id = Column(UUID(as_uuid=True), ForeignKey("product_offers.id", ondelete="CASCADE"), primary_key=True)
    window_days = Column(Integer, default=30, nullable=False)
    
    # final_price 기준 통계
    avg_final_price = Column(Integer, nullable=False)
    min_final_price = Column(Integer, nullable=False)
    max_final_price = Column(Integer, nullable=False)
    last_final_price = Column(Integer, nullable=False)
    last_captured_at = Column(DateTime(timezone=True), nullable=False)
    
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    offer = relationship("ProductOffer", back_populates="price_summary")
