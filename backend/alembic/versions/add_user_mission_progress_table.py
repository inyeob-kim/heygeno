"""add_user_mission_progress_table

Revision ID: add_mission_progress
Revises: add_ingredient_config
Create Date: 2026-02-11 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'add_mission_progress'
down_revision = 'add_ingredient_config'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # campaigns 테이블에 kind='MISSION' 지원 (이미 String이므로 별도 수정 불필요)
    
    # user_mission_progress 테이블 생성
    op.create_table('user_mission_progress',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('campaign_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('current_value', sa.Integer(), server_default='0', nullable=False),
        sa.Column('target_value', sa.Integer(), nullable=False),
        sa.Column('status', sa.String(length=20), server_default='IN_PROGRESS', nullable=False),
        sa.Column('started_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('completed_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('claimed_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['campaign_id'], ['campaigns.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id', 'campaign_id', name='uq_user_mission_progress')
    )
    
    # 인덱스 생성
    op.create_index('idx_user_mission_progress_user', 'user_mission_progress', ['user_id'])
    op.create_index('idx_user_mission_progress_user_status', 'user_mission_progress', ['user_id', 'status'])
    
    # campaigns 테이블에 relationship 추가 (이미 있으므로 별도 수정 불필요)


def downgrade() -> None:
    op.drop_index('idx_user_mission_progress_user_status', table_name='user_mission_progress')
    op.drop_index('idx_user_mission_progress_user', table_name='user_mission_progress')
    op.drop_table('user_mission_progress')
