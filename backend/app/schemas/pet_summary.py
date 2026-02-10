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
    breed_code: Optional[str] = None  # 품종 코드
    is_neutered: Optional[bool] = None  # 중성화 여부
    sex: Optional[str] = None  # 'MALE' | 'FEMALE' | 'UNKNOWN'
    food_allergies: List[str] = []  # 음식 알레르기 코드 리스트
    other_allergies: Optional[str] = None  # 기타 알레르기 텍스트
    is_primary: bool = False  # 주 반려동물 여부

    model_config = {"from_attributes": True}
