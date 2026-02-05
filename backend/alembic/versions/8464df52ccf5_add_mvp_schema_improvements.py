"""add_mvp_schema_improvements

Revision ID: 8464df52ccf5
Revises: ea321c242d86
Create Date: 2026-02-05 17:44:10.530672

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = '8464df52ccf5'
down_revision = 'ea321c242d86'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # 1. product_offers 테이블에 쿠팡 vendorItemId를 위한 안정적 매핑 키 추가
    op.add_column('product_offers', sa.Column('vendor_item_id', sa.BigInteger(), nullable=True))
    op.add_column('product_offers', sa.Column('normalized_key', sa.String(length=255), nullable=True))
    op.create_unique_constraint('uq_product_offers_vendor_item_id', 'product_offers', ['vendor_item_id'])
    
    # 2. products 테이블 중복 방지 unique 제약
    op.create_unique_constraint('unique_brand_name_size', 'products', ['brand_name', 'product_name', 'size_label'])
    
    # 3. 성분/영양 정보 버전 관리 (포뮬러 변경 추적용)
    op.add_column('product_ingredient_profiles', sa.Column('version', sa.Integer(), nullable=False, server_default='1'))
    op.add_column('product_nutrition_facts', sa.Column('version', sa.Integer(), nullable=False, server_default='1'))
    
    # 4. 가격 스냅샷 출처 기록 (쿠팡 외 플랫폼 대비)
    op.add_column('price_snapshots', sa.Column('captured_source', sa.String(length=50), nullable=False, server_default='COUPANG_API'))


def downgrade() -> None:
    # 4. 가격 스냅샷 출처 기록 제거
    op.drop_column('price_snapshots', 'captured_source')
    
    # 3. 성분/영양 정보 버전 관리 제거
    op.drop_column('product_nutrition_facts', 'version')
    op.drop_column('product_ingredient_profiles', 'version')
    
    # 2. products 테이블 unique 제약 제거
    op.drop_constraint('unique_brand_name_size', 'products', type_='unique')
    
    # 1. product_offers 테이블 컬럼 제거
    op.drop_constraint('uq_product_offers_vendor_item_id', 'product_offers', type_='unique')
    op.drop_column('product_offers', 'normalized_key')
    op.drop_column('product_offers', 'vendor_item_id')
