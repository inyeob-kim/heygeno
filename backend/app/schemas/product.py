from pydantic import BaseModel, Field
from typing import Optional, List
from uuid import UUID
from datetime import datetime

from app.models.offer import Merchant
from app.models.product import PetSpecies


class ProductRead(BaseModel):
    """상품 조회 응답"""
    id: UUID
    brand_name: str
    product_name: str
    size_label: Optional[str] = None
    is_active: bool
    category: Optional[str] = None
    species: Optional[PetSpecies] = None

    model_config = {"from_attributes": True}


class ProductCreate(BaseModel):
    """상품 생성 요청"""
    brand_name: str = Field(..., min_length=1, max_length=100)
    product_name: str = Field(..., min_length=1, max_length=255)
    size_label: Optional[str] = Field(None, max_length=50)
    category: str = Field(default="FOOD", max_length=30)
    species: Optional[PetSpecies] = None
    is_active: bool = Field(default=True)


class ProductUpdate(BaseModel):
    """상품 수정 요청"""
    brand_name: Optional[str] = Field(None, min_length=1, max_length=100)
    product_name: Optional[str] = Field(None, min_length=1, max_length=255)
    size_label: Optional[str] = Field(None, max_length=50)
    category: Optional[str] = Field(None, max_length=30)
    species: Optional[PetSpecies] = None
    is_active: Optional[bool] = None


class PriceSummaryRead(BaseModel):
    """가격 요약 조회 응답"""
    offer_id: UUID
    window_days: int
    avg_price: int
    min_price: int
    max_price: int
    last_price: int
    last_captured_at: datetime

    model_config = {"from_attributes": True}


class RecommendationItem(BaseModel):
    """추천 상품 아이템"""
    product: ProductRead
    offer_merchant: Merchant = Field(..., description="판매처")
    current_price: int = Field(..., description="현재 가격")
    avg_price: int = Field(..., description="평균 가격")
    delta_percent: Optional[float] = Field(None, description="평균 대비 변동률 (%)")
    is_new_low: bool = Field(..., description="최저가 여부")


class RecommendationResponse(BaseModel):
    """추천 상품 목록 응답"""
    pet_id: UUID
    items: List[RecommendationItem]

