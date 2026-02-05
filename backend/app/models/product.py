from sqlalchemy import Column, String, Boolean, ForeignKey, Enum as SQLEnum, Index, Text, SmallInteger, CheckConstraint, Integer, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.types import Numeric
from sqlalchemy.orm import relationship
import uuid
import enum

from app.db.base import Base, TimestampMixin


# PetSpecies는 pet.py와 공유하지만 순환 참조 방지를 위해 여기서도 정의
class PetSpecies(str, enum.Enum):
    DOG = "DOG"
    CAT = "CAT"


class Product(Base, TimestampMixin):
    __tablename__ = "products"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    category = Column(String(30), nullable=False, server_default='FOOD')  # MVP는 FOOD만
    brand_name = Column(String(100), nullable=False)
    product_name = Column(String(255), nullable=False)
    size_label = Column(String(50), nullable=True)  # 예: "3kg", "5kg"
    species = Column(SQLEnum(PetSpecies), nullable=True)  # DOG/CAT 전용 사료면 지정, 공용이면 NULL
    is_active = Column(Boolean, default=True, nullable=False)

    __table_args__ = (
        Index('idx_products_active', 'is_active'),
        Index('idx_products_brand', 'brand_name'),
        UniqueConstraint('brand_name', 'product_name', 'size_label', name='unique_brand_name_size'),
    )

    # Relationships
    offers = relationship("ProductOffer", back_populates="product", cascade="all, delete-orphan")
    trackings = relationship("Tracking", back_populates="product", cascade="all, delete-orphan")
    ingredient_profile = relationship("ProductIngredientProfile", back_populates="product", uselist=False, cascade="all, delete-orphan")
    nutrition_facts = relationship("ProductNutritionFacts", back_populates="product", uselist=False, cascade="all, delete-orphan")
    allergens = relationship("ProductAllergen", back_populates="product", cascade="all, delete-orphan")
    claims = relationship("ProductClaim", back_populates="product", cascade="all, delete-orphan")


# 원재료/성분표 원문 + 파싱 결과
class ProductIngredientProfile(Base):
    __tablename__ = "product_ingredient_profiles"
    
    product_id = Column(UUID(as_uuid=True), ForeignKey("products.id", ondelete="CASCADE"), primary_key=True)
    ingredients_text = Column(Text, nullable=True)  # "원재료" 원문
    additives_text = Column(Text, nullable=True)  # "첨가물" 원문
    parsed = Column(JSONB, nullable=True)  # JSONB: 토큰화/정규화 결과
    source = Column(String(200), nullable=True)  # 공식홈/포장지/크롤링 등
    version = Column(Integer, nullable=False, server_default='1')  # 포뮬러 변경 추적용
    updated_at = Column(String, nullable=False, server_default='now()')  # TimestampMixin의 updated_at과 별도
    
    # Relationships
    product = relationship("Product", back_populates="ingredient_profile")


# 보장성분/칼로리(정형)
class ProductNutritionFacts(Base):
    __tablename__ = "product_nutrition_facts"
    
    product_id = Column(UUID(as_uuid=True), ForeignKey("products.id", ondelete="CASCADE"), primary_key=True)
    protein_pct = Column(Numeric(5, 2), nullable=True)
    fat_pct = Column(Numeric(5, 2), nullable=True)
    fiber_pct = Column(Numeric(5, 2), nullable=True)
    moisture_pct = Column(Numeric(5, 2), nullable=True)
    ash_pct = Column(Numeric(5, 2), nullable=True)
    kcal_per_100g = Column(Integer, nullable=True)
    calcium_pct = Column(Numeric(5, 2), nullable=True)
    phosphorus_pct = Column(Numeric(5, 2), nullable=True)
    aafco_statement = Column(Text, nullable=True)
    version = Column(Integer, nullable=False, server_default='1')  # 포뮬러 변경 추적용
    updated_at = Column(String, nullable=False, server_default='now()')
    
    # Relationships
    product = relationship("Product", back_populates="nutrition_facts")


# 상품이 포함/배제하는 알레르겐(필터 핵심)
class ProductAllergen(Base):
    __tablename__ = "product_allergens"
    
    product_id = Column(UUID(as_uuid=True), ForeignKey("products.id", ondelete="CASCADE"), primary_key=True)
    allergen_code = Column(String(30), ForeignKey("allergen_codes.code"), primary_key=True)
    confidence = Column(SmallInteger, nullable=False, server_default='80')
    source = Column(String(200), nullable=True)
    
    __table_args__ = (
        CheckConstraint('confidence BETWEEN 0 AND 100', name='product_allergens_confidence_check'),
        Index('idx_product_allergens_allergen', 'allergen_code'),
    )
    
    # Relationships
    product = relationship("Product", back_populates="allergens")
    allergen = relationship("AllergenCode")


# 기능성/클레임 태그
class ClaimCode(Base):
    __tablename__ = "claim_codes"
    
    code = Column(String(30), primary_key=True)
    display_name = Column(String(50), nullable=False)


class ProductClaim(Base):
    __tablename__ = "product_claims"
    
    product_id = Column(UUID(as_uuid=True), ForeignKey("products.id", ondelete="CASCADE"), primary_key=True)
    claim_code = Column(String(30), ForeignKey("claim_codes.code"), primary_key=True)
    evidence_level = Column(SmallInteger, nullable=False, server_default='50')
    note = Column(Text, nullable=True)
    
    __table_args__ = (
        CheckConstraint('evidence_level BETWEEN 0 AND 100', name='product_claims_evidence_check'),
        Index('idx_product_claims_claim', 'claim_code'),
    )
    
    # Relationships
    product = relationship("Product", back_populates="claims")
    claim = relationship("ClaimCode")
