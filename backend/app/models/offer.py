from sqlalchemy import Column, String, Boolean, ForeignKey, Enum as SQLEnum, UniqueConstraint, Index, BigInteger
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid
import enum

from app.db.base import Base, TimestampMixin


class Merchant(str, enum.Enum):
    COUPANG = "COUPANG"
    NAVER = "NAVER"
    BRAND = "BRAND"


class ProductOffer(Base, TimestampMixin):
    __tablename__ = "product_offers"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    product_id = Column(UUID(as_uuid=True), ForeignKey("products.id", ondelete="CASCADE"), nullable=False, index=True)
    merchant = Column(SQLEnum(Merchant), nullable=False)
    merchant_product_id = Column(String(255), nullable=False)
    vendor_item_id = Column(BigInteger, nullable=True, unique=True)  # 쿠팡 vendorItemId 매핑용
    normalized_key = Column(String(255), nullable=True)  # 안정적 매핑 키
    url = Column(String(500), nullable=False)
    affiliate_url = Column(String(500), nullable=True)
    seller_name = Column(String(120), nullable=True)  # 네이버/오픈마켓 대비
    is_primary = Column(Boolean, default=False, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)

    __table_args__ = (
        UniqueConstraint('merchant', 'merchant_product_id', name='uq_offer_merchant_product'),
        Index('ix_offers_product_merchant', 'product_id', 'merchant'),
        Index('idx_offers_active', 'is_active'),
    )

    # Relationships
    product = relationship("Product", back_populates="offers")
    price_snapshots = relationship("PriceSnapshot", back_populates="offer", cascade="all, delete-orphan")
    price_summary = relationship("PriceSummary", back_populates="offer", uselist=False, cascade="all, delete-orphan")
