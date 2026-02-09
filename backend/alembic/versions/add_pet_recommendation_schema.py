"""add pet recommendation schema

Revision ID: add_pet_recommendation
Revises: 4e2cb404e17a
Create Date: 2025-02-09 14:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'add_pet_recommendation'
down_revision = '4e2cb404e17a'  # 최신 마이그레이션
branch_labels = None
depends_on = None


def upgrade() -> None:
    # =========================================================
    # 0) 사전: 확장 함수 (gen_random_uuid 사용 중이면 필요)
    # =========================================================
    op.execute("CREATE EXTENSION IF NOT EXISTS pgcrypto;")

    # =========================================================
    # 1) ENUM 추가 (이미 있으면 스킵)
    # =========================================================
    
    # activitylevel
    op.execute("""
        DO $$ BEGIN
            CREATE TYPE activitylevel AS ENUM ('LOW', 'MEDIUM', 'HIGH');
        EXCEPTION
            WHEN duplicate_object THEN NULL;
        END $$;
    """)
    
    # healthconditioncode
    op.execute("""
        DO $$ BEGIN
            CREATE TYPE healthconditioncode AS ENUM (
                'SKIN', 'JOINT', 'GI', 'KIDNEY', 'URINARY', 'DENTAL',
                'DIABETES', 'HEART', 'LIVER', 'OBESITY', 'UNDERWEIGHT'
            );
        EXCEPTION
            WHEN duplicate_object THEN NULL;
        END $$;
    """)
    
    # avoidlevel
    op.execute("""
        DO $$ BEGIN
            CREATE TYPE avoidlevel AS ENUM ('CONFIRMED', 'SUSPECTED', 'PREFERENCE');
        EXCEPTION
            WHEN duplicate_object THEN NULL;
        END $$;
    """)
    
    # infosource
    op.execute("""
        DO $$ BEGIN
            CREATE TYPE infosource AS ENUM ('OWNER', 'VET', 'TRIAL', 'LAB', 'UNKNOWN');
        EXCEPTION
            WHEN duplicate_object THEN NULL;
        END $$;
    """)
    
    # tastepreference
    op.execute("""
        DO $$ BEGIN
            CREATE TYPE tastepreference AS ENUM ('LIKE', 'DISLIKE', 'NEUTRAL');
        EXCEPTION
            WHEN duplicate_object THEN NULL;
        END $$;
    """)

    # =========================================================
    # 2) pets 테이블 보완
    # =========================================================
    op.add_column('pets', sa.Column('activity_level', postgresql.ENUM('LOW', 'MEDIUM', 'HIGH', name='activitylevel', create_type=False), nullable=True))
    op.add_column('pets', sa.Column('current_product_id', postgresql.UUID(as_uuid=True), nullable=True))
    op.add_column('pets', sa.Column('current_food_started_at', sa.Date(), nullable=True))
    op.add_column('pets', sa.Column('note', sa.Text(), nullable=True))
    
    # is_neutered NULL 처리
    op.execute("""
        UPDATE pets
        SET is_neutered = FALSE
        WHERE is_neutered IS NULL;
    """)
    
    op.alter_column('pets', 'is_neutered',
                    existing_type=sa.Boolean(),
                    nullable=False,
                    server_default='false')
    
    # FK 및 인덱스
    op.create_foreign_key(
        'fk_pets_current_product',
        'pets', 'products',
        ['current_product_id'], ['id'],
        ondelete='SET NULL'
    )
    op.create_index('idx_pets_current_product_id', 'pets', ['current_product_id'])
    op.create_index('idx_pets_species_age_stage', 'pets', ['species', 'age_stage'])

    # =========================================================
    # 3) 건강 상태 태그 테이블
    # =========================================================
    op.create_table(
        'pet_health_conditions',
        sa.Column('pet_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('condition_code', postgresql.ENUM('SKIN', 'JOINT', 'GI', 'KIDNEY', 'URINARY', 'DENTAL', 'DIABETES', 'HEART', 'LIVER', 'OBESITY', 'UNDERWEIGHT', name='healthconditioncode', create_type=False), nullable=False),
        sa.Column('severity', sa.SmallInteger(), nullable=False, server_default='50'),
        sa.Column('source', postgresql.ENUM('OWNER', 'VET', 'TRIAL', 'LAB', 'UNKNOWN', name='infosource', create_type=False), nullable=False, server_default='OWNER'),
        sa.Column('note', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('NOW()')),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('NOW()')),
        sa.ForeignKeyConstraint(['pet_id'], ['pets.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('pet_id', 'condition_code'),
        sa.CheckConstraint('severity BETWEEN 0 AND 100', name='pet_health_conditions_severity_check')
    )
    op.create_index('idx_pet_health_conditions_pet', 'pet_health_conditions', ['pet_id'])
    op.create_index('idx_pet_health_conditions_condition', 'pet_health_conditions', ['condition_code'])

    # =========================================================
    # 4) 회피/알레르기 성분 테이블
    # =========================================================
    op.create_table(
        'pet_avoid_allergens',
        sa.Column('pet_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('allergen_code', sa.String(50), nullable=False),
        sa.Column('level', postgresql.ENUM('CONFIRMED', 'SUSPECTED', 'PREFERENCE', name='avoidlevel', create_type=False), nullable=False, server_default='SUSPECTED'),
        sa.Column('confidence', sa.SmallInteger(), nullable=False, server_default='80'),
        sa.Column('source', postgresql.ENUM('OWNER', 'VET', 'TRIAL', 'LAB', 'UNKNOWN', name='infosource', create_type=False), nullable=False, server_default='OWNER'),
        sa.Column('note', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('NOW()')),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('NOW()')),
        sa.ForeignKeyConstraint(['pet_id'], ['pets.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('pet_id', 'allergen_code'),
        sa.CheckConstraint('confidence BETWEEN 0 AND 100', name='pet_avoid_allergens_confidence_check')
    )
    
    # allergen_codes FK (테이블이 있는 경우)
    op.execute("""
        DO $$ BEGIN
            ALTER TABLE pet_avoid_allergens
                ADD CONSTRAINT fk_pet_avoid_allergens_code
                FOREIGN KEY (allergen_code) REFERENCES allergen_codes(code);
        EXCEPTION
            WHEN undefined_table THEN NULL;
            WHEN duplicate_object THEN NULL;
        END $$;
    """)
    
    op.create_index('idx_pet_avoid_allergens_pet', 'pet_avoid_allergens', ['pet_id'])
    op.create_index('idx_pet_avoid_allergens_code', 'pet_avoid_allergens', ['allergen_code'])

    # =========================================================
    # 5) 제품 선호/비선호 테이블
    # =========================================================
    op.create_table(
        'pet_product_preferences',
        sa.Column('pet_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('product_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('preference', postgresql.ENUM('LIKE', 'DISLIKE', 'NEUTRAL', name='tastepreference', create_type=False), nullable=False, server_default='NEUTRAL'),
        sa.Column('reason', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('NOW()')),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('NOW()')),
        sa.ForeignKeyConstraint(['pet_id'], ['pets.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('pet_id', 'product_id')
    )
    
    # products FK
    op.execute("""
        DO $$ BEGIN
            ALTER TABLE pet_product_preferences
                ADD CONSTRAINT fk_pet_product_preferences_product
                FOREIGN KEY (product_id) REFERENCES products(id);
        EXCEPTION
            WHEN undefined_table THEN NULL;
            WHEN duplicate_object THEN NULL;
        END $$;
    """)
    
    op.create_index('idx_pet_product_preferences_pet', 'pet_product_preferences', ['pet_id'])
    op.create_index('idx_pet_product_preferences_product', 'pet_product_preferences', ['product_id'])

    # =========================================================
    # 6) updated_at 자동 갱신 트리거
    # =========================================================
    op.execute("""
        CREATE OR REPLACE FUNCTION set_updated_at()
        RETURNS TRIGGER AS $$
        BEGIN
          NEW.updated_at = NOW();
          RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
    """)
    
    # pets
    op.execute("""
        DO $$ BEGIN
            CREATE TRIGGER trg_pets_set_updated_at
            BEFORE UPDATE ON pets
            FOR EACH ROW
            EXECUTE FUNCTION set_updated_at();
        EXCEPTION
            WHEN duplicate_object THEN NULL;
        END $$;
    """)
    
    # pet_health_conditions
    op.execute("""
        DO $$ BEGIN
            CREATE TRIGGER trg_pet_health_conditions_set_updated_at
            BEFORE UPDATE ON pet_health_conditions
            FOR EACH ROW
            EXECUTE FUNCTION set_updated_at();
        EXCEPTION
            WHEN duplicate_object THEN NULL;
        END $$;
    """)
    
    # pet_avoid_allergens
    op.execute("""
        DO $$ BEGIN
            CREATE TRIGGER trg_pet_avoid_allergens_set_updated_at
            BEFORE UPDATE ON pet_avoid_allergens
            FOR EACH ROW
            EXECUTE FUNCTION set_updated_at();
        EXCEPTION
            WHEN duplicate_object THEN NULL;
        END $$;
    """)
    
    # pet_product_preferences
    op.execute("""
        DO $$ BEGIN
            CREATE TRIGGER trg_pet_product_preferences_set_updated_at
            BEFORE UPDATE ON pet_product_preferences
            FOR EACH ROW
            EXECUTE FUNCTION set_updated_at();
        EXCEPTION
            WHEN duplicate_object THEN NULL;
        END $$;
    """)


def downgrade() -> None:
    # 트리거 제거
    op.execute("DROP TRIGGER IF EXISTS trg_pet_product_preferences_set_updated_at ON pet_product_preferences;")
    op.execute("DROP TRIGGER IF EXISTS trg_pet_avoid_allergens_set_updated_at ON pet_avoid_allergens;")
    op.execute("DROP TRIGGER IF EXISTS trg_pet_health_conditions_set_updated_at ON pet_health_conditions;")
    op.execute("DROP TRIGGER IF EXISTS trg_pets_set_updated_at ON pets;")
    op.execute("DROP FUNCTION IF EXISTS set_updated_at();")
    
    # 테이블 제거
    op.drop_table('pet_product_preferences')
    op.drop_table('pet_avoid_allergens')
    op.drop_table('pet_health_conditions')
    
    # pets 테이블 컬럼 제거
    op.drop_index('idx_pets_species_age_stage', table_name='pets')
    op.drop_index('idx_pets_current_product_id', table_name='pets')
    op.drop_constraint('fk_pets_current_product', 'pets', type_='foreignkey')
    op.alter_column('pets', 'is_neutered',
                    existing_type=sa.Boolean(),
                    nullable=True,
                    server_default=None)
    op.drop_column('pets', 'note')
    op.drop_column('pets', 'current_food_started_at')
    op.drop_column('pets', 'current_product_id')
    op.drop_column('pets', 'activity_level')
    
    # ENUM 제거
    op.execute("DROP TYPE IF EXISTS tastepreference;")
    op.execute("DROP TYPE IF EXISTS infosource;")
    op.execute("DROP TYPE IF EXISTS avoidlevel;")
    op.execute("DROP TYPE IF EXISTS healthconditioncode;")
    op.execute("DROP TYPE IF EXISTS activitylevel;")
