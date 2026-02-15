"""미션 스키마"""
from typing import Optional
from datetime import datetime
from uuid import UUID
from pydantic import BaseModel


class MissionRead(BaseModel):
    """미션 조회 응답"""
    id: str
    campaign_id: str
    title: str
    description: str
    reward_points: int
    current_value: int
    target_value: int
    status: str
    completed: bool
    can_claim: bool
    completed_at: Optional[str] = None
    started_at: Optional[str] = None
    
    class Config:
        from_attributes = True


class MissionClaimResponse(BaseModel):
    """미션 보상 받기 응답"""
    success: bool
    reward_points: int
    message: str
