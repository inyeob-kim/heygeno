"""Quick recommendation service (anonymous, no pet/user required)"""
import logging
import time
from typing import List, Optional
from uuid import uuid4
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.product import Product
from app.schemas.pet_summary import PetSummaryResponse
from app.schemas.recommendation import QuickRecommendationItem, QuickRecommendationResponse
from app.services.recommendation_scoring_service import RecommendationScoringService
from app.services.product_service import ProductService

logger = logging.getLogger(__name__)


class QuickRecommendationService:
    """Anonymous quick recommendation - no user/pet required"""

    @staticmethod
    def _build_virtual_pet_summary(
        species: str,
        life_stage: str,
        health_concern_primary: Optional[str],
        food_allergies: Optional[List[str]],
    ) -> PetSummaryResponse:
        """Build minimal PetSummaryResponse for scoring (no DB)"""
        health_concerns = [health_concern_primary] if health_concern_primary else []
        allergies = food_allergies or []
        return PetSummaryResponse(
            id=uuid4(),
            name="Quick",
            species=species.upper(),
            age_stage=life_stage.upper(),
            approx_age_months=None,
            weight_kg=10.0,
            health_concerns=health_concerns,
            photo_url=None,
            breed_code=None,
            is_neutered=None,
            sex=None,
            food_allergies=allergies,
            other_allergies=None,
            is_primary=False,
        )

    @staticmethod
    async def get_quick_recommendations(
        db: AsyncSession,
        species: str,
        life_stage: str,
        health_concern_primary: Optional[str] = None,
        food_allergies: Optional[List[str]] = None,
        request_id: Optional[str] = None,
    ) -> QuickRecommendationResponse:
        """
        Run quick recommendation (no user/pet required).
        Uses rule-based scoring only (no LLM, no DB writes).
        """
        start_time = time.time()
        logger.info(
            f"[QuickReco] Request: species={species}, life_stage={life_stage}, "
            f"health={health_concern_primary}, allergies={food_allergies}, request_id={request_id}"
        )

        pet_summary = QuickRecommendationService._build_virtual_pet_summary(
            species, life_stage, health_concern_primary, food_allergies
        )
        user_prefs = {
            "weights_preset": "BALANCED",
            "hard_exclude_allergens": [],
            "soft_avoid_ingredients": [],
            "sort_preference": "default",
            "health_concern_priority": bool(health_concern_primary),
        }

        # 상품 로딩·스코링 모두 재사용
        products = await ProductService.get_active_products_with_parsed(db)
        logger.info(f"[QuickReco] Loaded {len(products)} products with parsed JSON")

        if not products:
            return QuickRecommendationResponse(
                recommended_items=[],
                disclaimer="No products available. Please try again later.",
            )

        scored = await RecommendationScoringService.score_products(
            db, pet_summary, products, user_prefs
        )
        scored.sort(key=lambda x: x[1], reverse=True)
        top = scored[:10]

        items = []
        for product, total_score, safety_score, fitness_score, reasons in top:
            summary = "; ".join(reasons[:3]) if reasons else None
            items.append(
                QuickRecommendationItem(
                    id=product.id,
                    name=product.product_name or "",
                    brand=product.brand_name or "",
                    match_score=round(total_score, 1),
                    safety_score=round(safety_score, 1),
                    fitness_score=round(fitness_score, 1),
                    summary=summary,
                )
            )

        elapsed_ms = int((time.time() - start_time) * 1000)
        logger.info(f"[QuickReco] Done: {len(items)} items, {elapsed_ms}ms, request_id={request_id}")

        return QuickRecommendationResponse(
            recommended_items=items,
            disclaimer="Quick recommendations are based on basic criteria. Sign in for personalized recommendations.",
        )
