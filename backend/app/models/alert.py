from sqlalchemy import Column, Integer, Boolean, DateTime, ForeignKey, Enum as SQLEnum, Numeric, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid
import enum

from app.db.base import Base, TimestampMixin


class AlertRuleType(str, enum.Enum):
    BELOW_AVG = "BELOW_AVG"
    NEW_LOW = "NEW_LOW"
    TARGET_PRICE = "TARGET_PRICE"


class AlertEventStatus(str, enum.Enum):
    SENT = "SENT"
    FAILED = "FAILED"


class Alert(Base, TimestampMixin):
    __tablename__ = "alerts"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    tracking_id = Column(UUID(as_uuid=True), ForeignKey("trackings.id", ondelete="CASCADE"), nullable=False, index=True)
    rule_type = Column(SQLEnum(AlertRuleType), nullable=False)
    target_price = Column(Integer, nullable=True)  # TARGET_PRICE일 때만
    cooldown_hours = Column(Integer, default=24, nullable=False)
    is_enabled = Column(Boolean, default=True, nullable=False)
    last_triggered_at = Column(DateTime(timezone=True), nullable=True)

    __table_args__ = (
        Index('idx_alerts_tracking_enabled', 'tracking_id', 'is_enabled'),
    )

    # Relationships
    tracking = relationship("Tracking", back_populates="alerts")
    events = relationship("AlertEvent", back_populates="alert", cascade="all, delete-orphan")


class AlertEvent(Base):
    """알림 이벤트 - final_price 기준"""
    __tablename__ = "alert_events"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    alert_id = Column(UUID(as_uuid=True), ForeignKey("alerts.id", ondelete="CASCADE"), nullable=False, index=True)
    trigger_reason = Column(SQLEnum(AlertRuleType), nullable=False)
    price_at_trigger = Column(Integer, nullable=False)  # final_price 기준
    avg_price_at_trigger = Column(Integer, nullable=True)
    delta_percent = Column(Numeric(6, 2), nullable=True)
    sent_at = Column(DateTime(timezone=True), nullable=False)
    opened_at = Column(DateTime(timezone=True), nullable=True)
    clicked_at = Column(DateTime(timezone=True), nullable=True)
    status = Column(SQLEnum(AlertEventStatus), nullable=False, server_default='SENT')
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    __table_args__ = (
        Index('idx_alert_events_alert_time', 'alert_id', 'sent_at', postgresql_ops={'sent_at': 'DESC'}),
    )

    # Relationships
    alert = relationship("Alert", back_populates="events")
