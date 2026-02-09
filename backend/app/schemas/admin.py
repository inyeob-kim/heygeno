from pydantic import BaseModel, Field
from typing import Optional, List
from uuid import UUID
from datetime import datetime

# Admin Schemas for Product Ingredient Profile
class IngredientProfileRead(BaseModel):
    product_id: UUID
    ingredients_text: Optional[str] = None
    additives_text: Optional[str] = None
    parsed: Optional[dict] = None
    source: Optional[str] = None
    version: int
    updated_at: str

    model_config = {"from_attributes": True}

class IngredientProfileCreate(BaseModel):
    ingredients_text: Optional[str] = None
    additives_text: Optional[str] = None
    source: Optional[str] = None

class IngredientProfileUpdate(BaseModel):
    ingredients_text: Optional[str] = None
    additives_text: Optional[str] = None
    parsed: Optional[dict] = None
    source: Optional[str] = None
    version: Optional[int] = None

# Admin Schemas for Product Nutrition Facts
class NutritionFactsRead(BaseModel):
    product_id: UUID
    protein_pct: Optional[float] = None
    fat_pct: Optional[float] = None
    fiber_pct: Optional[float] = None
    moisture_pct: Optional[float] = None
    ash_pct: Optional[float] = None
    kcal_per_100g: Optional[int] = None
    calcium_pct: Optional[float] = None
    phosphorus_pct: Optional[float] = None
    aafco_statement: Optional[str] = None
    version: int
    updated_at: str

    model_config = {"from_attributes": True}

class NutritionFactsCreate(BaseModel):
    protein_pct: Optional[float] = None
    fat_pct: Optional[float] = None
    fiber_pct: Optional[float] = None
    moisture_pct: Optional[float] = None
    ash_pct: Optional[float] = None
    kcal_per_100g: Optional[int] = None
    calcium_pct: Optional[float] = None
    phosphorus_pct: Optional[float] = None
    aafco_statement: Optional[str] = None

class NutritionFactsUpdate(BaseModel):
    protein_pct: Optional[float] = None
    fat_pct: Optional[float] = None
    fiber_pct: Optional[float] = None
    moisture_pct: Optional[float] = None
    ash_pct: Optional[float] = None
    kcal_per_100g: Optional[int] = None
    calcium_pct: Optional[float] = None
    phosphorus_pct: Optional[float] = None
    aafco_statement: Optional[str] = None
    version: Optional[int] = None

# Admin Schemas for Product Allergens
class AllergenCodeRead(BaseModel):
    code: str
    display_name: str

    model_config = {"from_attributes": True}

class ProductAllergenRead(BaseModel):
    product_id: UUID
    allergen_code: str
    allergen_display_name: Optional[str] = None # For display purposes
    confidence: int
    source: Optional[str] = None

    model_config = {"from_attributes": True}

class ProductAllergenCreate(BaseModel):
    allergen_code: str
    confidence: int = Field(80, ge=0, le=100)
    source: Optional[str] = None

class ProductAllergenUpdate(BaseModel):
    confidence: Optional[int] = Field(None, ge=0, le=100)
    source: Optional[str] = None

# Admin Schemas for Product Claims
class ClaimCodeRead(BaseModel):
    code: str
    display_name: str

    model_config = {"from_attributes": True}

class ProductClaimRead(BaseModel):
    product_id: UUID
    claim_code: str
    claim_display_name: Optional[str] = None # For display purposes
    evidence_level: int
    note: Optional[str] = None

    model_config = {"from_attributes": True}

class ProductClaimCreate(BaseModel):
    claim_code: str
    evidence_level: int = Field(50, ge=0, le=100)
    note: Optional[str] = None

class ProductClaimUpdate(BaseModel):
    evidence_level: Optional[int] = Field(None, ge=0, le=100)
    note: Optional[str] = None

# Admin Schemas for Product List (with computed fields)
class ProductListRead(BaseModel):
    """상품 목록 조회 응답 (computed 필드 포함)"""
    id: UUID
    brand_name: str
    product_name: str
    size_label: Optional[str] = None
    is_active: bool
    category: Optional[str] = None
    species: Optional[str] = None
    primary_image_url: Optional[str] = None
    thumbnail_url: Optional[str] = None
    admin_memo: Optional[str] = None
    completion_status: Optional[str] = None
    last_admin_updated_at: Optional[datetime] = None
    # Computed fields
    offers_count: int = 0
    ingredient_exists: bool = False
    nutrition_exists: bool = False
    has_image: bool = False

    model_config = {"from_attributes": True}

class ProductListResponse(BaseModel):
    """상품 목록 페이지네이션 응답"""
    items: List[ProductListRead]
    total: int
    page: int
    size: int

# Admin Schemas for Product Images
class ProductImagesUpdate(BaseModel):
    primary_image_url: Optional[str] = Field(None, max_length=500)
    thumbnail_url: Optional[str] = Field(None, max_length=500)
    images: Optional[List[str]] = Field(None, description="Additional images array")

# Admin Schemas for Product Offers
from app.models.offer import Merchant

class OfferRead(BaseModel):
    id: UUID
    product_id: UUID
    merchant: Merchant
    merchant_product_id: str
    vendor_item_id: Optional[int] = None
    normalized_key: Optional[str] = None
    url: str
    affiliate_url: Optional[str] = None
    seller_name: Optional[str] = None
    platform_image_url: Optional[str] = None
    display_priority: int = 10
    admin_note: Optional[str] = None
    last_fetch_status: Optional[str] = None
    last_fetch_error: Optional[str] = None
    last_fetched_at: Optional[datetime] = None
    current_price: Optional[int] = None
    currency: str = "KRW"
    last_seen_price: Optional[int] = None
    is_primary: bool = False
    is_active: bool = True

    model_config = {"from_attributes": True}

class OfferCreate(BaseModel):
    merchant: Merchant
    merchant_product_id: str = Field(..., max_length=255)
    vendor_item_id: Optional[int] = None
    normalized_key: Optional[str] = Field(None, max_length=255)
    url: str = Field(..., max_length=500)
    affiliate_url: Optional[str] = Field(None, max_length=500)
    seller_name: Optional[str] = Field(None, max_length=120)
    platform_image_url: Optional[str] = Field(None, max_length=500)
    display_priority: int = Field(10, ge=0)
    admin_note: Optional[str] = None
    current_price: Optional[int] = None
    currency: str = Field("KRW", max_length=3)
    is_primary: bool = False
    is_active: bool = True

class OfferUpdate(BaseModel):
    merchant: Optional[Merchant] = None
    merchant_product_id: Optional[str] = Field(None, max_length=255)
    vendor_item_id: Optional[int] = None
    normalized_key: Optional[str] = Field(None, max_length=255)
    url: Optional[str] = Field(None, max_length=500)
    affiliate_url: Optional[str] = Field(None, max_length=500)
    seller_name: Optional[str] = Field(None, max_length=120)
    platform_image_url: Optional[str] = Field(None, max_length=500)
    display_priority: Optional[int] = Field(None, ge=0)
    admin_note: Optional[str] = None
    current_price: Optional[int] = None
    currency: Optional[str] = Field(None, max_length=3)
    is_primary: Optional[bool] = None
    is_active: Optional[bool] = None

# Admin Schemas for Imports
from enum import Enum

class ImportType(str, Enum):
    PRODUCTS = "PRODUCTS"
    OFFERS = "OFFERS"
    INGREDIENTS = "INGREDIENTS"
    ALLERGENS = "ALLERGENS"
    CLAIMS = "CLAIMS"
    BULK_UPDATE = "BULK_UPDATE"

class ImportStatus(str, Enum):
    PENDING = "PENDING"
    PROCESSING = "PROCESSING"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"

class ImportLogRead(BaseModel):
    id: UUID
    import_type: ImportType
    filename: str
    row_count: int = 0
    success_count: int = 0
    failed_count: int = 0
    error_summary: Optional[str] = None
    admin_user_id: Optional[UUID] = None
    started_at: datetime
    finished_at: Optional[datetime] = None
    status: ImportStatus

    model_config = {"from_attributes": True}

class ImportLogRowRead(BaseModel):
    id: UUID
    import_log_id: UUID
    row_number: int
    raw_row: dict
    error_message: Optional[str] = None
    created_at: datetime

    model_config = {"from_attributes": True}
