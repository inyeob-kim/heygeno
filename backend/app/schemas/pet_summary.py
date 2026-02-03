"""Primary Pet 요약 정보 스키마 (홈 화면용)"""
from pydantic import BaseModel
from typing import Optional, List
from uuid import UUID


class PetSummaryResponse(BaseModel):
    """Primary Pet 요약 정보 응답"""
    id: UUID
    name: str
    species: str  # 'DOG' | 'CAT'
    age_stage: Optional[str] = None  # 'PUPPY' | 'ADULT' | 'SENIOR'
    approx_age_months: Optional[int] = None
    weight_kg: float
    health_concerns: List[str] = []  # 빈 배열 = "특이사항 없음"
    photo_url: Optional[str] = None

    model_config = {"from_attributes": True}
