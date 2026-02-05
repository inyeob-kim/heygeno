"""add_mid_term_schema_improvements

Revision ID: 2d390ff1ada4
Revises: 8464df52ccf5
Create Date: 2026-02-05 17:44:XX.XXXXXX

중기 적용 추천 (MVP 론칭 후 1~3개월 내, 운영하면서 넣기)
- 어필리에이트 수익 분석용 예상/실제 커미션
- 가격 추적 주기 관리용 필드
- 알림 중복 발송 방지용 마지막 전송 가격
- 추천 이유 디버깅 + 설명용 세부 점수 분해

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = '2d390ff1ada4'
down_revision = '8464df52ccf5'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # 5. 어필리에이트 수익 분석용 예상/실제 커미션
    op.add_column('outbound_clicks', sa.Column('estimated_commission', sa.Numeric(10, 2), nullable=True))
    op.add_column('outbound_clicks', sa.Column('actual_commission', sa.Numeric(10, 2), nullable=True))
    
    # 6. 가격 추적 주기 관리용 필드
    op.add_column('trackings', sa.Column('last_checked_at', sa.DateTime(timezone=True), nullable=True))
    op.add_column('trackings', sa.Column('next_check_at', sa.DateTime(timezone=True), nullable=True))
    
    # 7. 알림 중복 발송 방지용 마지막 전송 가격
    op.add_column('alerts', sa.Column('last_sent_price', sa.Integer(), nullable=True))
    
    # 8. 추천 이유 디버깅 + 설명용 세부 점수 분해
    op.add_column('recommendation_items', sa.Column('score_components', postgresql.JSONB(astext_type=sa.Text()), nullable=True))


def downgrade() -> None:
    # 8. 추천 이유 디버깅 + 설명용 세부 점수 분해 제거
    op.drop_column('recommendation_items', 'score_components')
    
    # 7. 알림 중복 발송 방지용 마지막 전송 가격 제거
    op.drop_column('alerts', 'last_sent_price')
    
    # 6. 가격 추적 주기 관리용 필드 제거
    op.drop_column('trackings', 'next_check_at')
    op.drop_column('trackings', 'last_checked_at')
    
    # 5. 어필리에이트 수익 분석용 예상/실제 커미션 제거
    op.drop_column('outbound_clicks', 'actual_commission')
    op.drop_column('outbound_clicks', 'estimated_commission')
