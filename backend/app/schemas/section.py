"""마켓 섹션 관련 스키마"""
from pydantic import BaseModel, Field
from typing import Optional, List
from uuid import UUID
from datetime import datetime

from app.models.section import SectionType, ProductCategory
from app.schemas.product import ProductRead


class SectionRequest(BaseModel):
    """섹션 조회 요청"""
    type: SectionType
    category: ProductCategory = ProductCategory.ALL
    limit: Optional[int] = Field(None, ge=1, le=50)
    offset: Optional[int] = Field(None, ge=0)
    time_range: Optional[str] = Field(None, description="인기 섹션용: 24h, 7d, 30d")
    days: Optional[int] = Field(None, description="신상품 섹션용: 신상품 기준 일수")
    min_reviews: Optional[int] = Field(None, description="리뷰 베스트 섹션용: 최소 리뷰 수")
    user_id: Optional[UUID] = Field(None, description="개인화 섹션용: 사용자 ID")
    pet_id: Optional[UUID] = Field(None, description="개인화 섹션용: 펫 ID")


class SectionResponse(BaseModel):
    """섹션 조회 응답"""
    type: SectionType
    category: ProductCategory
    products: List[ProductRead]
    total: int
    limit: int
    offset: int
    cached: bool = False
    cached_at: Optional[datetime] = None


class BatchSectionRequest(BaseModel):
    """배치 섹션 조회 요청"""
    sections: List[SectionRequest]


class BatchSectionResponse(BaseModel):
    """배치 섹션 조회 응답"""
    sections: List[SectionResponse]
