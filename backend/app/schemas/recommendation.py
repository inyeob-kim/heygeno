"""Quick recommendation schemas (anonymous, no auth)"""
from pydantic import BaseModel, Field
from typing import Optional, List
from uuid import UUID


class QuickRecommendationRequest(BaseModel):
    """Request for anonymous quick recommendation"""
    species: str = Field(..., description="DOG or CAT")
    life_stage: str = Field(..., description="PUPPY, ADULT, or SENIOR")
    health_concern_primary: Optional[str] = Field(None, description="Primary health concern code")
    food_allergies: Optional[List[str]] = Field(default_factory=list, description="Allergen codes")
    request_id: Optional[str] = Field(None, description="Client-generated UUID for logging/tracking")


class QuickRecommendationItem(BaseModel):
    """Simplified recommendation item for quick flow"""
    id: UUID
    name: str
    brand: str
    match_score: float
    safety_score: float
    fitness_score: float
    summary: Optional[str] = None  # Short reason summary


class QuickRecommendationResponse(BaseModel):
    """Response for quick recommendation"""
    recommended_items: List[QuickRecommendationItem]
    disclaimer: str = "Quick recommendations are based on basic criteria. Sign in for personalized recommendations."
