"""add_user_password_hash

Revision ID: add_password_hash
Revises: add_auth_subscription
Create Date: 2026-02-22

users.password_hash 추가 (EMAIL 로그인용)
"""
from alembic import op
import sqlalchemy as sa

revision = "add_password_hash"
down_revision = "add_auth_subscription"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("users", sa.Column("password_hash", sa.String(255), nullable=True))


def downgrade() -> None:
    op.drop_column("users", "password_hash")
