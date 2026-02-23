"""add_auth_and_subscription_module

Revision ID: add_auth_subscription
Revises: 8ae72374b022
Create Date: 2026-02-22

회원가입/로그인·구독 모듈: users 확장, user_tokens, withdrawal_log, subscription_payments
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "add_auth_subscription"
down_revision = "8ae72374b022"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ----- users 테이블 컬럼 추가 -----
    op.add_column("users", sa.Column("firebase_uid", sa.String(128), nullable=True))
    op.add_column("users", sa.Column("email", sa.String(255), nullable=True))
    op.add_column("users", sa.Column("status", sa.String(20), nullable=False, server_default="active"))
    op.add_column("users", sa.Column("withdrawn_at", sa.DateTime(timezone=True), nullable=True))
    op.add_column("users", sa.Column("plan_type", sa.String(20), nullable=False, server_default="FREE"))
    op.add_column("users", sa.Column("plan_expire_at", sa.DateTime(timezone=True), nullable=True))
    op.create_index("idx_users_firebase_uid", "users", ["firebase_uid"], unique=True)
    op.create_index("idx_users_status", "users", ["status"], unique=False)

    # ----- user_tokens -----
    op.create_table(
        "user_tokens",
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("provider", sa.String(50), nullable=False),
        sa.Column("refresh_token", sa.Text(), nullable=False),
        sa.Column("access_token", sa.Text(), nullable=True),
        sa.Column("token_updated_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.PrimaryKeyConstraint("user_id", "provider"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
    )

    # ----- withdrawal_log -----
    op.create_table(
        "withdrawal_log",
        sa.Column("id", sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("archive_date", sa.String(8), nullable=False),
        sa.Column("restored_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("reason", sa.Text(), nullable=True),
        sa.Column("provider", sa.String(50), nullable=True),
        sa.Column("provider_user_id", sa.String(255), nullable=True),
        sa.Column("firebase_uid", sa.String(128), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_withdrawal_log_provider_oauth", "withdrawal_log", ["provider", "provider_user_id"])
    op.create_index("idx_withdrawal_log_firebase_uid", "withdrawal_log", ["firebase_uid"])

    # ----- subscription_payments -----
    op.create_table(
        "subscription_payments",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("transaction_id", sa.String(128), nullable=False),
        sa.Column("platform", sa.String(20), nullable=False),
        sa.Column("product_id", sa.String(64), nullable=False),
        sa.Column("amount", sa.Numeric(10, 2), server_default="0", nullable=False),
        sa.Column("currency", sa.String(10), server_default="KRW", nullable=False),
        sa.Column("payment_status", sa.String(20), server_default="PAID", nullable=False),
        sa.Column("payment_date", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("processed_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("last_verified_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("purchase_token", sa.Text(), nullable=True),
        sa.Column("original_transaction_id", sa.String(128), nullable=True),
        sa.Column("environment", sa.String(16), server_default="prod", nullable=False),
        sa.Column("raw_receipt", postgresql.JSONB(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.UniqueConstraint("platform", "transaction_id", name="uq_subscription_platform_transaction"),
    )
    op.create_index("idx_subscription_payments_user_expires", "subscription_payments", ["user_id", "expires_at"])
    op.create_index("idx_subscription_payments_status", "subscription_payments", ["payment_status"])


def downgrade() -> None:
    op.drop_index("idx_subscription_payments_status", "subscription_payments")
    op.drop_index("idx_subscription_payments_user_expires", "subscription_payments")
    op.drop_table("subscription_payments")
    op.drop_index("idx_withdrawal_log_firebase_uid", "withdrawal_log")
    op.drop_index("idx_withdrawal_log_provider_oauth", "withdrawal_log")
    op.drop_table("withdrawal_log")
    op.drop_table("user_tokens")
    op.drop_index("idx_users_status", "users")
    op.drop_index("idx_users_firebase_uid", "users")
    op.drop_column("users", "plan_expire_at")
    op.drop_column("users", "plan_type")
    op.drop_column("users", "withdrawn_at")
    op.drop_column("users", "status")
    op.drop_column("users", "email")
    op.drop_column("users", "firebase_uid")
