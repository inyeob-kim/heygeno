"""Recommendations API - Quick (anonymous) recommendations"""
import time
import logging
from collections import defaultdict
from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.schemas.recommendation import (
    QuickRecommendationRequest,
    QuickRecommendationResponse,
)
from app.services.quick_recommendation_service import QuickRecommendationService

logger = logging.getLogger(__name__)
router = APIRouter()

# Simple in-memory IP rate limit: 30 requests per minute
RATE_LIMIT_PER_MIN = 30
_rate_store: dict[str, list[float]] = defaultdict(list)


def _get_client_ip(request: Request) -> str:
    """Get client IP (X-Forwarded-For or direct)"""
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host if request.client else "unknown"


def _check_rate_limit(ip: str) -> None:
    """Raise 429 if over limit"""
    now = time.time()
    cutoff = now - 60
    _rate_store[ip] = [t for t in _rate_store[ip] if t > cutoff]
    if len(_rate_store[ip]) >= RATE_LIMIT_PER_MIN:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many requests. Please try again in a minute.",
        )
    _rate_store[ip].append(now)


@router.post("/quick", response_model=QuickRecommendationResponse)
async def post_quick_recommendation(
    body: QuickRecommendationRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    """
    Anonymous quick recommendation (no auth required).
    Rate limited by IP (30/min). Uses request_id for server-side logging.
    """
    ip = _get_client_ip(request)
    _check_rate_limit(ip)

    species_upper = body.species.upper()
    life_stage_upper = body.life_stage.upper()

    if species_upper not in ("DOG", "CAT"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="species must be DOG or CAT",
        )
    if life_stage_upper not in ("PUPPY", "ADULT", "SENIOR"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="life_stage must be PUPPY, ADULT, or SENIOR",
        )

    result = await QuickRecommendationService.get_quick_recommendations(
        db,
        species=species_upper,
        life_stage=life_stage_upper,
        health_concern_primary=body.health_concern_primary,
        food_allergies=body.food_allergies or [],
        request_id=body.request_id,
    )
    return result
