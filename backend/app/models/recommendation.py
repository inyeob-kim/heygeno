from sqlalchemy import Column, ForeignKey, Enum as SQLEnum, Integer, Numeric, Index, DateTime
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid
import enum

from app.db.base import Base, TimestampMixin


class RecStrategy(str, enum.Enum):
    RULE_V1 = "RULE_V1"
    RULE_V2 = "RULE_V2"
    ML_V1 = "ML_V1"


class RecommendationRun(Base, TimestampMixin):
    """추천 실행 로그 - 추천 "설명"과 개선을 가능하게 하는 핵심"""
    __tablename__ = "recommendation_runs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    pet_id = Column(UUID(as_uuid=True), ForeignKey("pets.id", ondelete="CASCADE"), nullable=False)
    strategy = Column(SQLEnum(RecStrategy), nullable=False, server_default='RULE_V1')
    context = Column(JSONB, nullable=False)  # 당시 펫/필터/선호/제외 알레르겐 등 스냅샷
    # created_at은 TimestampMixin에서 상속

    # created_at은 TimestampMixin에서 상속되므로 인덱스에 사용 가능
    __table_args__ = (
        Index('idx_rec_runs_pet_time', 'pet_id', 'created_at', postgresql_ops={'created_at': 'DESC'}),
    )

    # Relationships
    items = relationship("RecommendationItem", back_populates="run", cascade="all, delete-orphan")


class RecommendationItem(Base):
    """추천 아이템 - 추천 결과와 이유"""
    __tablename__ = "recommendation_items"

    run_id = Column(UUID(as_uuid=True), ForeignKey("recommendation_runs.id", ondelete="CASCADE"), primary_key=True)
    product_id = Column(UUID(as_uuid=True), ForeignKey("products.id", ondelete="CASCADE"), primary_key=True)
    rank = Column(Integer, nullable=False)
    score = Column(Numeric(8, 4), nullable=False)
    reasons = Column(JSONB, nullable=False)  # ["알레르겐 제외 통과", "체중관리 클레임", ...]
    score_components = Column(JSONB, nullable=True)  # 추천 이유 디버깅 + 설명용 세부 점수 분해

    __table_args__ = (
        Index('idx_rec_items_run_rank', 'run_id', 'rank'),
    )

    # Relationships
    run = relationship("RecommendationRun", back_populates="items")
