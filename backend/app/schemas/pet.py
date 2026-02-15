from pydantic import BaseModel, Field
from typing import Optional
from uuid import UUID
from datetime import datetime

from app.models.pet import AgeStage


class PetCreate(BaseModel):
    """반려동물 생성 요청"""
    name: Optional[str] = None
    breed_code: str = Field(..., description="견종 코드")
    weight_bucket_code: str = Field(..., description="체중 구간 코드 (예: '5-10kg')")
    age_stage: AgeStage = Field(..., description="나이 단계")
    is_neutered: Optional[bool] = Field(None, description="중성화 여부")
    is_primary: Optional[bool] = Field(False, description="주 반려동물 여부")


class PetUpdate(BaseModel):
    """반려동물 업데이트 요청 (변할 수 있는 정보만)"""
    weight_kg: Optional[float] = Field(None, ge=0.1, le=99.9, description="체중 (kg)")
    is_neutered: Optional[bool] = Field(None, description="중성화 여부")
    health_concerns: Optional[list[str]] = Field(None, description="건강 고민 코드 리스트")
    food_allergies: Optional[list[str]] = Field(None, description="음식 알레르기 코드 리스트")
    other_allergies: Optional[str] = Field(None, max_length=200, description="기타 알레르기 텍스트")


class PetRead(BaseModel):
    """반려동물 조회 응답"""
    id: UUID
    user_id: UUID
    name: Optional[str] = None
    breed_code: str
    weight_bucket_code: str
    age_stage: AgeStage
    is_neutered: Optional[bool] = None
    is_primary: bool
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}

