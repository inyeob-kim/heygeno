"""관리자용 스키마"""
from pydantic import BaseModel, Field
from typing import Optional, List
from uuid import UUID
from decimal import Decimal


# 성분 정보 스키마
class IngredientProfileRead(BaseModel):
    """성분 정보 조회"""
    product_id: UUID
    ingredients_text: Optional[str] = None
    additives_text: Optional[str] = None
    parsed: Optional[dict] = None
    source: Optional[str] = None
    version: int = 1
    updated_at: Optional[str] = None

    model_config = {"from_attributes": True}


class IngredientProfileCreate(BaseModel):
    """성분 정보 생성"""
    ingredients_text: Optional[str] = None
    additives_text: Optional[str] = None
    parsed: Optional[dict] = None
    source: Optional[str] = Field(None, max_length=200)


class IngredientProfileUpdate(BaseModel):
    """성분 정보 수정"""
    ingredients_text: Optional[str] = None
    additives_text: Optional[str] = None
    parsed: Optional[dict] = None
    source: Optional[str] = Field(None, max_length=200)


# 영양 정보 스키마
class NutritionFactsRead(BaseModel):
    """영양 정보 조회"""
    product_id: UUID
    protein_pct: Optional[Decimal] = None
    fat_pct: Optional[Decimal] = None
    fiber_pct: Optional[Decimal] = None
    moisture_pct: Optional[Decimal] = None
    ash_pct: Optional[Decimal] = None
    kcal_per_100g: Optional[int] = None
    calcium_pct: Optional[Decimal] = None
    phosphorus_pct: Optional[Decimal] = None
    aafco_statement: Optional[str] = None
    version: int = 1
    updated_at: Optional[str] = None

    model_config = {"from_attributes": True}


class NutritionFactsCreate(BaseModel):
    """영양 정보 생성"""
    protein_pct: Optional[Decimal] = Field(None, ge=0, le=100)
    fat_pct: Optional[Decimal] = Field(None, ge=0, le=100)
    fiber_pct: Optional[Decimal] = Field(None, ge=0, le=100)
    moisture_pct: Optional[Decimal] = Field(None, ge=0, le=100)
    ash_pct: Optional[Decimal] = Field(None, ge=0, le=100)
    kcal_per_100g: Optional[int] = Field(None, ge=0)
    calcium_pct: Optional[Decimal] = Field(None, ge=0, le=100)
    phosphorus_pct: Optional[Decimal] = Field(None, ge=0, le=100)
    aafco_statement: Optional[str] = None


class NutritionFactsUpdate(BaseModel):
    """영양 정보 수정"""
    protein_pct: Optional[Decimal] = Field(None, ge=0, le=100)
    fat_pct: Optional[Decimal] = Field(None, ge=0, le=100)
    fiber_pct: Optional[Decimal] = Field(None, ge=0, le=100)
    moisture_pct: Optional[Decimal] = Field(None, ge=0, le=100)
    ash_pct: Optional[Decimal] = Field(None, ge=0, le=100)
    kcal_per_100g: Optional[int] = Field(None, ge=0)
    calcium_pct: Optional[Decimal] = Field(None, ge=0, le=100)
    phosphorus_pct: Optional[Decimal] = Field(None, ge=0, le=100)
    aafco_statement: Optional[str] = None


# 알레르겐 스키마
class AllergenCodeRead(BaseModel):
    """알레르겐 코드 조회"""
    code: str
    display_name: str

    model_config = {"from_attributes": True}


class ProductAllergenRead(BaseModel):
    """상품 알레르겐 조회"""
    product_id: UUID
    allergen_code: str
    allergen_display_name: Optional[str] = None
    confidence: int = 80
    source: Optional[str] = None

    model_config = {"from_attributes": True}


class ProductAllergenCreate(BaseModel):
    """상품 알레르겐 생성"""
    allergen_code: str = Field(..., max_length=30)
    confidence: int = Field(80, ge=0, le=100)
    source: Optional[str] = Field(None, max_length=200)


class ProductAllergenUpdate(BaseModel):
    """상품 알레르겐 수정"""
    confidence: Optional[int] = Field(None, ge=0, le=100)
    source: Optional[str] = Field(None, max_length=200)


# 클레임 스키마
class ClaimCodeRead(BaseModel):
    """클레임 코드 조회"""
    code: str
    display_name: str

    model_config = {"from_attributes": True}


class ProductClaimRead(BaseModel):
    """상품 클레임 조회"""
    product_id: UUID
    claim_code: str
    claim_display_name: Optional[str] = None
    evidence_level: int = 50
    note: Optional[str] = None

    model_config = {"from_attributes": True}


class ProductClaimCreate(BaseModel):
    """상품 클레임 생성"""
    claim_code: str = Field(..., max_length=30)
    evidence_level: int = Field(50, ge=0, le=100)
    note: Optional[str] = None


class ProductClaimUpdate(BaseModel):
    """상품 클레임 수정"""
    evidence_level: Optional[int] = Field(None, ge=0, le=100)
    note: Optional[str] = None
