"""탈퇴 로그 (복구 시 provider/oauth_id 조회용, 30일 이내 복구)"""
from sqlalchemy import Column, String, DateTime, BigInteger, Text, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy import func

from app.db.base import Base


class WithdrawalLog(Base):
    __tablename__ = "withdrawal_log"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    user_id = Column(UUID(as_uuid=True), nullable=False)
    deleted_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    archive_date = Column(String(8), nullable=False)  # YYYYMMDD
    restored_at = Column(DateTime(timezone=True), nullable=True)
    reason = Column(Text, nullable=True)
    provider = Column(String(50), nullable=True)
    provider_user_id = Column(String(255), nullable=True)
    firebase_uid = Column(String(128), nullable=True)

    __table_args__ = (
        Index("idx_withdrawal_log_provider_oauth", "provider", "provider_user_id"),
        Index("idx_withdrawal_log_firebase_uid", "firebase_uid"),
    )
