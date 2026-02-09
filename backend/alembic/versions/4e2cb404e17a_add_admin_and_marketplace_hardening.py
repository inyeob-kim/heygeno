"""add_admin_and_marketplace_hardening

Revision ID: 4e2cb404e17a
Revises: 2d390ff1ada4
Create Date: 2026-02-09 10:37:12.420985

Admin page + marketplace operations hardening
Safe to re-run (idempotent) / Production-ready
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = '4e2cb404e17a'
down_revision = '2d390ff1ada4'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ==============================================
    # 0) Extensions
    # ==============================================
    op.execute("CREATE EXTENSION IF NOT EXISTS pgcrypto")

    # ==============================================
    # 1) ENUM TYPES (create only if missing)
    # ==============================================
    op.execute("""
        DO $$
        BEGIN
          IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'offer_fetch_status') THEN
            CREATE TYPE offer_fetch_status AS ENUM ('SUCCESS', 'FAILED', 'PENDING', 'NOT_FETCHED');
          END IF;

          IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'admin_import_type') THEN
            CREATE TYPE admin_import_type AS ENUM ('PRODUCTS', 'OFFERS', 'INGREDIENTS', 'ALLERGENS', 'CLAIMS', 'BULK_UPDATE');
          END IF;

          IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'admin_import_status') THEN
            CREATE TYPE admin_import_status AS ENUM ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED');
          END IF;

          IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'admin_audit_action') THEN
            CREATE TYPE admin_audit_action AS ENUM ('INSERT', 'UPDATE', 'DELETE', 'BULK_INSERT', 'BULK_UPDATE', 'IMPORT');
          END IF;

          IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'product_completion_status') THEN
            CREATE TYPE product_completion_status AS ENUM (
              'COMPLETE',
              'MISSING_INGREDIENTS',
              'MISSING_NUTRITION',
              'MISSING_OFFERS',
              'MISSING_TAGS',
              'NEEDS_REVIEW'
            );
          END IF;
        END$$;
    """)

    # ==============================================
    # 2) products: admin convenience fields
    # ==============================================
    op.add_column('products', sa.Column('primary_image_url', sa.String(length=500), nullable=True))
    op.add_column('products', sa.Column('thumbnail_url', sa.String(length=500), nullable=True))
    op.add_column('products', sa.Column('images', postgresql.JSONB(astext_type=sa.Text()), nullable=False, server_default='[]'))
    op.add_column('products', sa.Column('admin_memo', sa.Text(), nullable=True))
    op.add_column('products', sa.Column('official_url', sa.String(length=500), nullable=True))
    op.add_column('products', sa.Column('manufacturer_code', sa.String(length=100), nullable=True))
    op.add_column('products', sa.Column('completion_status', postgresql.ENUM('COMPLETE', 'MISSING_INGREDIENTS', 'MISSING_NUTRITION', 'MISSING_OFFERS', 'MISSING_TAGS', 'NEEDS_REVIEW', name='product_completion_status', create_type=False), nullable=False, server_default='MISSING_INGREDIENTS'))
    op.add_column('products', sa.Column('last_admin_updated_at', sa.DateTime(timezone=True), nullable=True))
    op.add_column('products', sa.Column('last_admin_user_id', postgresql.UUID(as_uuid=True), nullable=True))
    op.add_column('products', sa.Column('archived_at', sa.DateTime(timezone=True), nullable=True))

    # FK: products.last_admin_user_id -> users(id) (users 존재할 때만)
    op.execute("""
        DO $$
        BEGIN
          IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_products_last_admin_user') THEN
              ALTER TABLE products
                ADD CONSTRAINT fk_products_last_admin_user
                FOREIGN KEY (last_admin_user_id) REFERENCES users(id)
                ON DELETE SET NULL;
            END IF;
          END IF;
        END$$;
    """)

    # products 검색/정렬 인덱스(관리자 목록 최적화)
    op.create_index('idx_products_active_updated', 'products', ['is_active', sa.text('last_admin_updated_at DESC NULLS LAST')], unique=False)
    op.create_index('idx_products_completion_status', 'products', ['completion_status', sa.text('last_admin_updated_at DESC NULLS LAST')], unique=False)

    # ==============================================
    # 3) product_offers: vendor management fields
    # ==============================================
    op.add_column('product_offers', sa.Column('platform_image_url', sa.String(length=500), nullable=True))
    op.add_column('product_offers', sa.Column('display_priority', sa.SmallInteger(), nullable=False, server_default='10'))
    op.add_column('product_offers', sa.Column('admin_note', sa.Text(), nullable=True))
    op.add_column('product_offers', sa.Column('last_fetch_status', postgresql.ENUM('SUCCESS', 'FAILED', 'PENDING', 'NOT_FETCHED', name='offer_fetch_status', create_type=False), nullable=False, server_default='NOT_FETCHED'))
    op.add_column('product_offers', sa.Column('last_fetch_error', sa.Text(), nullable=True))
    op.add_column('product_offers', sa.Column('last_fetched_at', sa.DateTime(timezone=True), nullable=True))
    op.add_column('product_offers', sa.Column('current_price', sa.Integer(), nullable=True))
    op.add_column('product_offers', sa.Column('currency', sa.CHAR(length=3), nullable=False, server_default='KRW'))
    op.add_column('product_offers', sa.Column('last_seen_price', sa.Integer(), nullable=True))

    # offers 조회/정렬 인덱스
    op.create_index('idx_product_offers_product_priority', 'product_offers', ['product_id', 'display_priority'], unique=False)
    op.create_index('idx_product_offers_last_fetch', 'product_offers', ['last_fetch_status', sa.text('last_fetched_at DESC')], unique=False)
    op.create_index('idx_product_offers_current_price', 'product_offers', ['product_id', 'current_price'], unique=False)

    # ==============================================
    # 4) bulk import logs (CSV/대량 업로드)
    # ==============================================
    op.create_table('admin_import_logs',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('import_type', postgresql.ENUM('PRODUCTS', 'OFFERS', 'INGREDIENTS', 'ALLERGENS', 'CLAIMS', 'BULK_UPDATE', name='admin_import_type', create_type=False), nullable=False),
        sa.Column('filename', sa.String(length=255), nullable=False),
        sa.Column('row_count', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('success_count', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('failed_count', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('error_summary', sa.Text(), nullable=True),
        sa.Column('admin_user_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('started_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('now()')),
        sa.Column('finished_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('status', postgresql.ENUM('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', name='admin_import_status', create_type=False), nullable=False, server_default='PENDING'),
        sa.PrimaryKeyConstraint('id')
    )

    # FK: admin_import_logs.admin_user_id -> users(id) (users 존재할 때만)
    op.execute("""
        DO $$
        BEGIN
          IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_admin_import_logs_user') THEN
              ALTER TABLE admin_import_logs
                ADD CONSTRAINT fk_admin_import_logs_user
                FOREIGN KEY (admin_user_id) REFERENCES users(id)
                ON DELETE SET NULL;
            END IF;
          END IF;
        END$$;
    """)

    op.create_index('idx_admin_import_logs_started', 'admin_import_logs', [sa.text('started_at DESC')], unique=False)
    op.create_index('idx_admin_import_logs_status', 'admin_import_logs', ['status', sa.text('started_at DESC')], unique=False)

    # (선택) 실패 행/원인까지 저장하고 싶으면 아래 테이블도 같이 사용
    op.create_table('admin_import_log_rows',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('import_log_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('row_number', sa.Integer(), nullable=False),
        sa.Column('raw_row', postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column('error_message', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('now()')),
        sa.ForeignKeyConstraint(['import_log_id'], ['admin_import_logs.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )

    op.create_index('idx_admin_import_log_rows_log', 'admin_import_log_rows', ['import_log_id', 'row_number'], unique=False)

    # ==============================================
    # 5) admin audit logs (감사 로그)
    # ==============================================
    op.create_table('admin_audit_logs',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('table_name', sa.String(length=100), nullable=False),
        sa.Column('record_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('action', postgresql.ENUM('INSERT', 'UPDATE', 'DELETE', 'BULK_INSERT', 'BULK_UPDATE', 'IMPORT', name='admin_audit_action', create_type=False), nullable=False),
        sa.Column('changed_by', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('old_data', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column('new_data', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column('memo', sa.Text(), nullable=True),
        sa.Column('ip_address', sa.String(length=45), nullable=True),
        sa.Column('user_agent', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('now()')),
        sa.PrimaryKeyConstraint('id')
    )

    # FK: admin_audit_logs.changed_by -> users(id) (users 존재할 때만)
    op.execute("""
        DO $$
        BEGIN
          IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_admin_audit_logs_user') THEN
              ALTER TABLE admin_audit_logs
                ADD CONSTRAINT fk_admin_audit_logs_user
                FOREIGN KEY (changed_by) REFERENCES users(id)
                ON DELETE SET NULL;
            END IF;
          END IF;
        END$$;
    """)

    op.create_index('idx_admin_audit_table_record', 'admin_audit_logs', ['table_name', 'record_id'], unique=False)
    op.create_index('idx_admin_audit_created', 'admin_audit_logs', [sa.text('created_at DESC')], unique=False)

    # ==============================================
    # 6) ingredients / nutrition: manual input & last editor
    # ==============================================
    op.add_column('product_ingredient_profiles', sa.Column('is_manual_input', sa.Boolean(), nullable=False, server_default='true'))
    op.add_column('product_ingredient_profiles', sa.Column('last_updated_by', postgresql.UUID(as_uuid=True), nullable=True))
    op.add_column('product_nutrition_facts', sa.Column('is_manual_input', sa.Boolean(), nullable=False, server_default='true'))
    op.add_column('product_nutrition_facts', sa.Column('last_updated_by', postgresql.UUID(as_uuid=True), nullable=True))

    # FK: product_ingredient_profiles.last_updated_by -> users(id) (users 존재할 때만)
    op.execute("""
        DO $$
        BEGIN
          IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_ingredient_profiles_last_updated_by') THEN
              ALTER TABLE product_ingredient_profiles
                ADD CONSTRAINT fk_ingredient_profiles_last_updated_by
                FOREIGN KEY (last_updated_by) REFERENCES users(id)
                ON DELETE SET NULL;
            END IF;

            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_nutrition_facts_last_updated_by') THEN
              ALTER TABLE product_nutrition_facts
                ADD CONSTRAINT fk_nutrition_facts_last_updated_by
                FOREIGN KEY (last_updated_by) REFERENCES users(id)
                ON DELETE SET NULL;
            END IF;
          END IF;
        END$$;
    """)

    # ==============================================
    # 7) allergens / claims: admin note
    # ==============================================
    op.add_column('product_allergens', sa.Column('admin_note', sa.Text(), nullable=True))
    op.add_column('product_claims', sa.Column('admin_note', sa.Text(), nullable=True))

    # ==============================================
    # 8) admin update meta triggers (prevents missing timestamps)
    # ==============================================
    # products: whenever admin edits a product, set last_admin_updated_at automatically
    op.execute("""
        CREATE OR REPLACE FUNCTION set_products_admin_update_meta()
        RETURNS TRIGGER AS $$
        BEGIN
          NEW.last_admin_updated_at = NOW();
          RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
    """)

    op.execute("""
        DO $$
        BEGIN
          IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_products_admin_meta') THEN
            CREATE TRIGGER trg_products_admin_meta
            BEFORE UPDATE ON products
            FOR EACH ROW
            EXECUTE FUNCTION set_products_admin_update_meta();
          END IF;
        END$$;
    """)

    # ==============================================
    # 9) OPTIONAL (recommended): completion_status helper view
    # ==============================================
    # 관리자 목록에서 "왜 미완성인지" 바로 보여주기 위해 뷰 제공
    op.execute("""
        CREATE OR REPLACE VIEW v_products_completion_flags AS
        SELECT
          p.id AS product_id,
          p.completion_status,
          -- offers 존재 여부
          (EXISTS (SELECT 1 FROM product_offers o WHERE o.product_id = p.id)) AS has_offers,
          -- 성분 존재 여부
          (EXISTS (SELECT 1 FROM product_ingredient_profiles ip WHERE ip.product_id = p.id)) AS has_ingredients,
          -- 영양 존재 여부
          (EXISTS (SELECT 1 FROM product_nutrition_facts nf WHERE nf.product_id = p.id)) AS has_nutrition
        FROM products p;
    """)


def downgrade() -> None:
    # Drop view
    op.execute("DROP VIEW IF EXISTS v_products_completion_flags")

    # Drop trigger
    op.execute("DROP TRIGGER IF EXISTS trg_products_admin_meta ON products")
    op.execute("DROP FUNCTION IF EXISTS set_products_admin_update_meta()")

    # Drop admin_note columns
    op.drop_column('product_claims', 'admin_note')
    op.drop_column('product_allergens', 'admin_note')

    # Drop last_updated_by columns and FKs
    op.execute("""
        DO $$
        BEGIN
          IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_nutrition_facts_last_updated_by') THEN
            ALTER TABLE product_nutrition_facts DROP CONSTRAINT fk_nutrition_facts_last_updated_by;
          END IF;
          IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_ingredient_profiles_last_updated_by') THEN
            ALTER TABLE product_ingredient_profiles DROP CONSTRAINT fk_ingredient_profiles_last_updated_by;
          END IF;
        END$$;
    """)
    op.drop_column('product_nutrition_facts', 'last_updated_by')
    op.drop_column('product_nutrition_facts', 'is_manual_input')
    op.drop_column('product_ingredient_profiles', 'last_updated_by')
    op.drop_column('product_ingredient_profiles', 'is_manual_input')

    # Drop audit logs table
    op.drop_index('idx_admin_audit_created', table_name='admin_audit_logs')
    op.drop_index('idx_admin_audit_table_record', table_name='admin_audit_logs')
    op.execute("""
        DO $$
        BEGIN
          IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_admin_audit_logs_user') THEN
            ALTER TABLE admin_audit_logs DROP CONSTRAINT fk_admin_audit_logs_user;
          END IF;
        END$$;
    """)
    op.drop_table('admin_audit_logs')

    # Drop import log tables
    op.drop_index('idx_admin_import_log_rows_log', table_name='admin_import_log_rows')
    op.drop_table('admin_import_log_rows')
    op.drop_index('idx_admin_import_logs_status', table_name='admin_import_logs')
    op.drop_index('idx_admin_import_logs_started', table_name='admin_import_logs')
    op.execute("""
        DO $$
        BEGIN
          IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_admin_import_logs_user') THEN
            ALTER TABLE admin_import_logs DROP CONSTRAINT fk_admin_import_logs_user;
          END IF;
        END$$;
    """)
    op.drop_table('admin_import_logs')

    # Drop product_offers columns
    op.drop_index('idx_product_offers_current_price', table_name='product_offers')
    op.drop_index('idx_product_offers_last_fetch', table_name='product_offers')
    op.drop_index('idx_product_offers_product_priority', table_name='product_offers')
    op.drop_column('product_offers', 'last_seen_price')
    op.drop_column('product_offers', 'currency')
    op.drop_column('product_offers', 'current_price')
    op.drop_column('product_offers', 'last_fetched_at')
    op.drop_column('product_offers', 'last_fetch_error')
    op.drop_column('product_offers', 'last_fetch_status')
    op.drop_column('product_offers', 'admin_note')
    op.drop_column('product_offers', 'display_priority')
    op.drop_column('product_offers', 'platform_image_url')

    # Drop products columns
    op.drop_index('idx_products_completion_status', table_name='products')
    op.drop_index('idx_products_active_updated', table_name='products')
    op.execute("""
        DO $$
        BEGIN
          IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_products_last_admin_user') THEN
            ALTER TABLE products DROP CONSTRAINT fk_products_last_admin_user;
          END IF;
        END$$;
    """)
    op.drop_column('products', 'archived_at')
    op.drop_column('products', 'last_admin_user_id')
    op.drop_column('products', 'last_admin_updated_at')
    op.drop_column('products', 'completion_status')
    op.drop_column('products', 'manufacturer_code')
    op.drop_column('products', 'official_url')
    op.drop_column('products', 'admin_memo')
    op.drop_column('products', 'images')
    op.drop_column('products', 'thumbnail_url')
    op.drop_column('products', 'primary_image_url')

    # Drop ENUM types (only if no other tables use them)
    # Note: This is risky if other tables use these enums, so we'll skip it in downgrade
    # op.execute("DROP TYPE IF EXISTS product_completion_status")
    # op.execute("DROP TYPE IF EXISTS admin_audit_action")
    # op.execute("DROP TYPE IF EXISTS admin_import_status")
    # op.execute("DROP TYPE IF EXISTS admin_import_type")
    # op.execute("DROP TYPE IF EXISTS offer_fetch_status")