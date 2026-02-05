from sqlalchemy import Column, String, DateTime, ForeignKey, Enum as SQLEnum, Index, Numeric
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.sql import func
import uuid
import enum

from app.db.base import Base


class ClickSource(str, enum.Enum):
    HOME = "HOME"
    DETAIL = "DETAIL"
    ALERT = "ALERT"


class OutboundClick(Base):
    """외부 클릭 추적 - 성과 트래킹"""
    __tablename__ = "outbound_clicks"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    pet_id = Column(UUID(as_uuid=True), ForeignKey("pets.id", ondelete="SET NULL"), nullable=True)
    product_id = Column(UUID(as_uuid=True), ForeignKey("products.id", ondelete="CASCADE"), nullable=False, index=True)
    offer_id = Column(UUID(as_uuid=True), ForeignKey("product_offers.id", ondelete="SET NULL"), nullable=True)
    source = Column(String(20), nullable=False)  # HOME/DETAIL/ALERT
    clicked_at = Column(DateTime(timezone=True), nullable=False)
    session_id = Column(String(255), nullable=True)
    estimated_commission = Column(Numeric(10, 2), nullable=True)  # 어필리에이트 수익 분석용 예상 커미션
    actual_commission = Column(Numeric(10, 2), nullable=True)  # 어필리에이트 수익 분석용 실제 커미션
    meta = Column(JSONB, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    __table_args__ = (
        Index('idx_clicks_product_time', 'product_id', 'clicked_at', postgresql_ops={'clicked_at': 'DESC'}),
        Index('idx_clicks_user_time', 'user_id', 'clicked_at', postgresql_ops={'clicked_at': 'DESC'}),
    )
