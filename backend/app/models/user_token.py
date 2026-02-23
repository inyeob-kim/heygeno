"""소셜 로그인 refresh_token 저장 (재사용 가능한 인증 모듈)"""
from sqlalchemy import Column, String, DateTime, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy import func
import uuid

from app.db.base import Base, TimestampMixin


class UserToken(Base, TimestampMixin):
    """한 사용자가 여러 provider로 로그인한 refresh_token 저장"""
    __tablename__ = "user_tokens"

    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True,
        nullable=False,
    )
    provider = Column(String(50), primary_key=True, nullable=False)
    refresh_token = Column(Text, nullable=False)
    access_token = Column(Text, nullable=True)
    token_updated_at = Column(DateTime(timezone=True), nullable=True, onupdate=func.now())

    user = relationship("User", back_populates="user_tokens")
