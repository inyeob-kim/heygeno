from pydantic import BaseModel, Field, model_validator
from typing import Optional, List
from datetime import date
from uuid import UUID


class AutoTrackConfig(BaseModel):
    enable: bool = False
    product_ids: Optional[List[UUID]] = None


class OnboardingCompleteRequest(BaseModel):
    device_uid: str = Field(..., min_length=1, description="Device UID (UUID v4)")
    nickname: str = Field(..., min_length=2, max_length=12, description="사용자 닉네임")
    
    # Pet 정보
    pet_name: str = Field(..., min_length=1, max_length=20)
    species: str = Field(..., pattern="^(DOG|CAT)$")
    
    # 나이
    age_mode: str = Field(..., pattern="^(BIRTHDATE|APPROX)$")
    birthdate: Optional[date] = None
    approx_age_months: Optional[int] = Field(None, ge=0, le=240)
    
    # 품종 (강아지 필수)
    breed_code: Optional[str] = None
    
    # 성별 및 중성화
    sex: str = Field(..., pattern="^(MALE|FEMALE)$")
    is_neutered: Optional[bool] = None  # null = 모름
    
    # 체중 및 체형
    weight_kg: float = Field(..., ge=0.1, le=99.9)
    body_condition_score: int = Field(..., ge=1, le=9)
    
    # 건강 및 알레르기
    health_concerns: List[str] = Field(default_factory=list)  # 코드 배열, 빈 배열 = "없어요"
    food_allergies: List[str] = Field(default_factory=list)  # 코드 배열, 빈 배열 = "없어요"
    other_allergy_text: Optional[str] = Field(None, max_length=200)
    
    # 사진
    photo_url: Optional[str] = None
    
    # 자동 추적 설정 (선택)
    auto_track: Optional[AutoTrackConfig] = None
    
    @model_validator(mode='after')
    def validate_fields(self):
        # 나이 필드 검증
        if self.age_mode == 'BIRTHDATE' and not self.birthdate:
            raise ValueError('birthdate is required when age_mode is BIRTHDATE')
        if self.age_mode == 'APPROX' and self.approx_age_months is None:
            raise ValueError('approx_age_months is required when age_mode is APPROX')
        
        # 품종 검증 (강아지 필수)
        if self.species == 'DOG' and not self.breed_code:
            raise ValueError('breed_code is required for DOG')
        
        return self


class OnboardingCompleteResponse(BaseModel):
    success: bool
    user_id: UUID
    pet_id: UUID
    message: str = "온보딩이 완료되었습니다."
