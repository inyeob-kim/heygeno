"""상품 관련 비즈니스 로직"""
from typing import Optional, List, Tuple
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, desc, delete, func
from sqlalchemy.orm import selectinload
from fastapi import HTTPException, status
from sqlalchemy.exc import IntegrityError
from datetime import datetime, timedelta, timezone
import json
import logging
import time

from app.models.product import Product, ProductIngredientProfile, ProductNutritionFacts, ProductAllergen, ProductClaim
from app.models.pet import Pet, PetHealthConcern, PetFoodAllergy, PetOtherAllergy
from app.models.recommendation import RecommendationRun, RecommendationItem, RecStrategy
from app.models.user_reco_prefs import UserRecoPrefs
from app.models.ingredient_config import HarmfulIngredient, AllergenKeyword
from app.schemas.product import ProductRead, ProductCreate, ProductUpdate, RecommendationResponse, RecommendationItem as RecommendationItemSchema, ProductDetailResponse, OfferDetailRead, IngredientDetailRead, NutritionDetailRead, ClaimDetailRead, PriceHistoryRead
from app.schemas.pet_summary import PetSummaryResponse
from app.models.offer import Merchant, ProductOffer
from app.models.price import PriceSnapshot, PriceSummary
from app.services.recommendation_scoring_service import RecommendationScoringService
from app.services.recommendation_explanation_service import RecommendationExplanationService
from app.services.coupang_api_client import get_coupang_api_client

logger = logging.getLogger(__name__)


def _generate_empty_recommendation_message(filter_stats: dict, pet_species: Optional[str] = None) -> str:
    """필터링 통계를 기반으로 사용자 친화적 메시지 생성"""
    total = filter_stats.get("total", 0)
    fitness_filtered = filter_stats.get("fitness_filtered", 0)
    safety_filtered = filter_stats.get("safety_filtered", 0)
    price_filtered = filter_stats.get("price_filtered", 0)
    
    # 종류 불일치가 주요 원인인 경우
    if fitness_filtered > 0 and fitness_filtered >= total * 0.8:
        species_name = "고양이" if pet_species == "CAT" else ("강아지" if pet_species == "DOG" else "반려동물")
        return f"{species_name} 전용 사료를 찾지 못했어요. 현재 등록된 상품 중 {species_name} 전용 사료가 없습니다. 펫 정보를 확인해주세요."
    
    # 안전성 기준 미달이 주요 원인인 경우
    if safety_filtered > 0 and safety_filtered >= total * 0.8:
        return "안전 기준을 만족하는 상품을 찾지 못했어요. 펫의 알레르기 정보나 건강 상태를 확인해주세요."
    
    # 가격 제한 초과가 주요 원인인 경우
    if price_filtered > 0 and price_filtered >= total * 0.8:
        return "설정하신 가격 범위 내에서 추천 가능한 상품이 없어요. 가격 제한을 조정하거나 다른 조건으로 검색해보세요."
    
    # 여러 원인이 복합적으로 작용한 경우
    if total > 0:
        return "현재 조건에 맞는 추천 상품을 찾지 못했어요. 펫 정보나 검색 조건을 확인해주세요."
    
    # 상품 자체가 없는 경우
    return "추천 가능한 상품이 없습니다. 곧 더 많은 상품이 추가될 예정입니다."


class ProductService:
    """상품 서비스 - 상품 관련 비즈니스 로직만 담당"""
    
    @staticmethod
    async def get_active_products(db: AsyncSession) -> list[Product]:
        """활성 상품 목록 조회"""
        result = await db.execute(
            select(Product).where(Product.is_active == True)
        )
        return list(result.scalars().all())
    
    @staticmethod
    async def get_product_by_id(product_id: UUID, db: AsyncSession) -> Product:
        """상품 ID로 조회"""
        result = await db.execute(select(Product).where(Product.id == product_id))
        product = result.scalar_one_or_none()
        
        if product is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Product not found"
            )
        
        return product
    
    @staticmethod
    async def get_product_detail(product_id: UUID, db: AsyncSession) -> ProductDetailResponse:
        """상품 상세 정보 조회 (일반 사용자용)"""
        # 상품 기본 정보 조회 (관계 포함)
        from app.models.product import ProductClaim, ProductAllergen
        result = await db.execute(
            select(Product)
            .options(
                selectinload(Product.offers),
                selectinload(Product.ingredient_profile),
                selectinload(Product.nutrition_facts),
                selectinload(Product.allergens).selectinload(ProductAllergen.allergen),
                selectinload(Product.claims).selectinload(ProductClaim.claim)
            )
            .where(Product.id == product_id)
        )
        product = result.scalar_one_or_none()
        
        if product is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Product not found"
            )
        
        # Primary offer 찾기
        primary_offer = None
        for offer in product.offers:
            if offer.is_primary and offer.is_active:
                primary_offer = offer
                break
        
        if not primary_offer:
            for offer in product.offers:
                if offer.is_active:
                    primary_offer = offer
                    break
        
        # 가격 정보 조회
        current_price = None
        average_price = None
        min_price = None
        max_price = None
        purchase_url = None
        price_history = []
        
        if primary_offer:
            purchase_url = primary_offer.affiliate_url or primary_offer.url
            
            # 1. 쿠팡 API로 실시간 가격 fetch
            realtime_price_data = None
            if primary_offer.merchant == Merchant.COUPANG:
                coupang_client = get_coupang_api_client()
                if coupang_client and primary_offer.vendor_item_id:
                    logger.info(
                        f"[ProductService] 🛒 쿠팡 API로 실시간 가격 조회: "
                        f"vendor_item_id={primary_offer.vendor_item_id}"
                    )
                    realtime_price_data = await coupang_client.get_product_price(
                        vendor_item_id=primary_offer.vendor_item_id
                    )
                    
                    if realtime_price_data:
                        current_price = realtime_price_data.get("final_price")
                        logger.info(
                            f"[ProductService] ✅ 쿠팡 API 가격 조회 성공: "
                            f"final_price={current_price}"
                        )
                        
                        # 백그라운드에서 PriceSnapshot 저장 (비동기, 에러 무시)
                        try:
                            await ProductService._save_price_snapshot(
                                db, primary_offer, realtime_price_data
                            )
                        except Exception as e:
                            logger.warning(
                                f"[ProductService] ⚠️ PriceSnapshot 저장 실패 (무시): {e}"
                            )
            
            # 2. 실시간 가격이 없으면 DB 캐시 사용 (fallback)
            if current_price is None:
                logger.info(
                    f"[ProductService] ℹ️ 실시간 가격 없음, DB 캐시 사용: "
                    f"offer_id={primary_offer.id}"
                )
                current_price = primary_offer.current_price
            
            # 3. PriceSummary에서 통계 가져오기
            price_summary = await db.get(PriceSummary, primary_offer.id)
            if price_summary:
                average_price = price_summary.avg_final_price
                min_price = price_summary.min_final_price
                max_price = price_summary.max_final_price
                # 실시간 가격이 없고 캐시도 없으면 PriceSummary의 last_final_price 사용
                if current_price is None:
                    current_price = price_summary.last_final_price
            
            # 4. 최근 7일 가격 히스토리 조회
            seven_days_ago = datetime.now(timezone.utc) - timedelta(days=7)
            history_result = await db.execute(
                select(PriceSnapshot)
                .where(
                    PriceSnapshot.offer_id == primary_offer.id,
                    PriceSnapshot.captured_at >= seven_days_ago
                )
                .order_by(PriceSnapshot.captured_at.asc())
            )
            snapshots = history_result.scalars().all()
            price_history = [
                PriceHistoryRead(date=s.captured_at, price=s.final_price)
                for s in snapshots
            ]
            
            # 실시간 가격이 있으면 히스토리에 추가 (최신 데이터)
            if realtime_price_data and current_price:
                price_history.append(
                    PriceHistoryRead(
                        date=datetime.now(timezone.utc),
                        price=current_price
                    )
                )
        
        # Offers 목록
        offers = [
            OfferDetailRead(
                id=o.id,
                merchant=o.merchant.value,
                url=o.url,
                affiliate_url=o.affiliate_url,
                current_price=o.current_price,
                is_primary=o.is_primary,
                is_active=o.is_active
            )
            for o in product.offers if o.is_active
        ]
        
        # 성분 정보
        ingredient = None
        if product.ingredient_profile:
            main_ingredients = []
            
            # parsed가 있고 ingredients_ordered가 있으면 사용
            if product.ingredient_profile.parsed:
                parsed = product.ingredient_profile.parsed
                ingredients_ordered = parsed.get("ingredients_ordered", [])
                if ingredients_ordered:
                    main_ingredients = ingredients_ordered[:10]
                    logger.info(
                        f"[ProductService] parsed에서 성분 추출: {len(main_ingredients)}개"
                    )
            
            # parsed가 없거나 비어있으면 ingredients_text를 파싱
            if not main_ingredients and product.ingredient_profile.ingredients_text:
                # 쉼표로 구분된 텍스트를 파싱
                ingredients_text = product.ingredient_profile.ingredients_text.strip()
                if ingredients_text:
                    # 쉼표, 공백으로 분리하고 빈 문자열 제거
                    main_ingredients = [
                        ing.strip() 
                        for ing in ingredients_text.replace('，', ',').split(',') 
                        if ing.strip()
                    ][:10]  # 최대 10개만
                    logger.info(
                        f"[ProductService] ingredients_text에서 성분 파싱: {len(main_ingredients)}개"
                    )
            
            # additives_text도 추가 (있으면)
            if product.ingredient_profile.additives_text:
                additives_text = product.ingredient_profile.additives_text.strip()
                if additives_text:
                    additives = [
                        add.strip() 
                        for add in additives_text.replace('，', ',').split(',') 
                        if add.strip()
                    ]
                    # main_ingredients에 추가 (최대 10개 유지)
                    main_ingredients.extend(additives[:max(0, 10 - len(main_ingredients))])
                    logger.info(
                        f"[ProductService] additives_text에서 첨가물 파싱: {len(additives)}개 추가"
                    )
            
            # 알레르기 성분 추출
            allergens = []
            if product.allergens:
                for allergen in product.allergens:
                    if allergen.allergen:
                        allergens.append(allergen.allergen.display_name)
            
            logger.info(
                f"[ProductService] 알레르기 성분: {len(allergens)}개"
            )
            
            # 설명 생성
            description = None
            if main_ingredients:
                description = f"주요 성분: {', '.join(main_ingredients[:5])}"
                if allergens:
                    description += f"\n알레르기 주의 성분: {', '.join(allergens)}"
            
            # main_ingredients, allergens, description 중 하나라도 있으면 ingredient 생성
            # main_ingredients는 항상 리스트로 반환 (빈 리스트라도)
            if main_ingredients or allergens or description:
                ingredient = IngredientDetailRead(
                    main_ingredients=main_ingredients if main_ingredients else [],
                    allergens=allergens if allergens else None,
                    description=description
                )
                logger.info(
                    f"[ProductService] ✅ IngredientDetailRead 생성: "
                    f"main_ingredients={len(main_ingredients)}개, "
                    f"allergens={len(allergens) if allergens else 0}개"
                )
            else:
                logger.warning(
                    f"[ProductService] ⚠️ 성분 정보가 모두 비어있어 IngredientDetailRead를 생성하지 않음"
                )
        
        # 영양 정보
        nutrition = None
        if product.nutrition_facts:
            nutrition = NutritionDetailRead(
                protein_pct=float(product.nutrition_facts.protein_pct) if product.nutrition_facts.protein_pct else None,
                fat_pct=float(product.nutrition_facts.fat_pct) if product.nutrition_facts.fat_pct else None,
                fiber_pct=float(product.nutrition_facts.fiber_pct) if product.nutrition_facts.fiber_pct else None,
                moisture_pct=float(product.nutrition_facts.moisture_pct) if product.nutrition_facts.moisture_pct else None,
                calcium_pct=float(product.nutrition_facts.calcium_pct) if product.nutrition_facts.calcium_pct else None,
                phosphorus_pct=float(product.nutrition_facts.phosphorus_pct) if product.nutrition_facts.phosphorus_pct else None,
                kcal_per_100g=product.nutrition_facts.kcal_per_100g
            )
        
        # 기능성 클레임
        claims = []
        if product.claims:
            for claim in product.claims:
                claim_display_name = None
                if claim.claim:
                    claim_display_name = claim.claim.display_name
                claims.append(
                    ClaimDetailRead(
                        claim_code=claim.claim_code,
                        claim_display_name=claim_display_name,
                        evidence_level=claim.evidence_level,
                        note=claim.note
                    )
                )
        
        return ProductDetailResponse(
            product=ProductRead.model_validate(product),
            offers=offers,
            current_price=current_price,
            average_price=average_price,
            min_price=min_price,
            max_price=max_price,
            purchase_url=purchase_url,
            price_history=price_history,
            ingredient=ingredient,
            nutrition=nutrition,
            claims=claims
        )
    
    @staticmethod
    async def _save_price_snapshot(
        db: AsyncSession,
        offer: ProductOffer,
        price_data: dict
    ) -> None:
        """
        가격 스냅샷 저장 및 통계 업데이트
        
        Args:
            db: 데이터베이스 세션
            offer: ProductOffer 인스턴스
            price_data: 쿠팡 API에서 받은 가격 데이터
        """
        try:
            now = datetime.now(timezone.utc)
            
            # PriceSnapshot 저장
            snapshot = PriceSnapshot(
                offer_id=offer.id,
                listed_price=price_data.get("listed_price", 0),
                shipping_fee=price_data.get("shipping_fee", 0),
                coupon_discount=price_data.get("coupon_discount", 0),
                card_discount=price_data.get("card_discount", 0),
                final_price=price_data.get("final_price", 0),
                currency=price_data.get("currency", "KRW"),
                is_sold_out=price_data.get("is_sold_out", False),
                captured_at=now,
                captured_source="COUPANG_API"
            )
            db.add(snapshot)
            
            # ProductOffer.current_price 업데이트
            offer.current_price = price_data.get("final_price")
            offer.last_fetched_at = now
            from app.models.offer import OfferFetchStatus
            offer.last_fetch_status = OfferFetchStatus.SUCCESS
            
            # PriceSummary 업데이트 (30일 윈도우 기준)
            price_summary = await db.get(PriceSummary, offer.id)
            if price_summary and price_summary.window_days == 30:
                # 기존 통계 유지하고 last_final_price만 업데이트
                price_summary.last_final_price = price_data.get("final_price", 0)
                price_summary.last_captured_at = now
            else:
                # 새로운 PriceSummary 생성 또는 재계산
                # 최근 30일 스냅샷으로 통계 계산
                thirty_days_ago = now - timedelta(days=30)
                stats_result = await db.execute(
                    select(
                        func.avg(PriceSnapshot.final_price).label("avg"),
                        func.min(PriceSnapshot.final_price).label("min"),
                        func.max(PriceSnapshot.final_price).label("max")
                    )
                    .where(
                        PriceSnapshot.offer_id == offer.id,
                        PriceSnapshot.captured_at >= thirty_days_ago
                    )
                )
                stats = stats_result.first()
                
                if price_summary:
                    price_summary.avg_final_price = int(stats.avg or price_data.get("final_price", 0))
                    price_summary.min_final_price = int(stats.min or price_data.get("final_price", 0))
                    price_summary.max_final_price = int(stats.max or price_data.get("final_price", 0))
                    price_summary.last_final_price = price_data.get("final_price", 0)
                    price_summary.last_captured_at = now
                else:
                    final_price = price_data.get("final_price", 0)
                    price_summary = PriceSummary(
                        offer_id=offer.id,
                        window_days=30,
                        avg_final_price=int(stats.avg or final_price),
                        min_final_price=int(stats.min or final_price),
                        max_final_price=int(stats.max or final_price),
                        last_final_price=final_price,
                        last_captured_at=now
                    )
                    db.add(price_summary)
            
            await db.commit()
            logger.info(
                f"[ProductService] ✅ PriceSnapshot 저장 완료: "
                f"offer_id={offer.id}, final_price={price_data.get('final_price')}"
            )
        except Exception as e:
            await db.rollback()
            logger.error(
                f"[ProductService] ❌ PriceSnapshot 저장 실패: {e}",
                exc_info=True
            )
            raise
    
    @staticmethod
    async def calculate_product_match_score(
        product_id: UUID,
        pet_id: UUID,
        db: AsyncSession
    ) -> "ProductMatchScoreResponse":
        """
        특정 상품의 맞춤 점수 계산
        
        Args:
            product_id: 상품 ID
            pet_id: 반려동물 ID
            db: 데이터베이스 세션
        
        Returns:
            ProductMatchScoreResponse: 맞춤 점수 응답
        """
        from app.schemas.product import ProductMatchScoreResponse
        from app.core.cache.recommendation_cache_service import RecommendationCacheService
        
        logger.info(f"[ProductService] 🎯 상품 맞춤 점수 계산 시작: product_id={product_id}, pet_id={pet_id}")
        
        # UPDATED: Redis 캐시 체크
        cached_score = await RecommendationCacheService.get_product_match_score(product_id, pet_id)
        if cached_score:
            logger.info(f"[ProductService] ✅ 맞춤 점수 캐시 히트: product_id={product_id}, pet_id={pet_id}")
            return cached_score
        
        logger.debug(f"[ProductService] ❌ 맞춤 점수 캐시 미스: product_id={product_id}, pet_id={pet_id}, 새로 계산")
        
        # 1. 펫 프로필 조회
        pet = await db.get(Pet, pet_id)
        if pet is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Pet not found"
            )
        
        pet_summary = await ProductService._build_pet_summary(pet, db)
        logger.info(f"[ProductService] 펫 프로필: {pet_summary.name}, 종류={pet_summary.species}, 나이={pet_summary.age_stage}")
        
        # 2. 사용자 선호도 불러오기
        user_id = pet.user_id
        user_prefs_result = await db.execute(
            select(UserRecoPrefs).where(UserRecoPrefs.user_id == user_id)
        )
        user_prefs_obj = user_prefs_result.scalars().first()
        
        default_prefs = {
            "weights_preset": "BALANCED",
            "hard_exclude_allergens": [],
            "soft_avoid_ingredients": [],
            "max_price_per_kg": None,
            "sort_preference": "default",
            "health_concern_priority": False,
        }
        
        if user_prefs_obj and user_prefs_obj.prefs:
            user_prefs = {**default_prefs, **user_prefs_obj.prefs}
        else:
            user_prefs = default_prefs
        
        # UPDATED: 추천 조건 조정 파라미터를 user_prefs에 추가 (요청 파라미터 우선)
        logger.info(f"[ProductService] 📋 조건 조정 파라미터 user_prefs에 추가 시작")
        logger.info(f"[ProductService]   - 기존 user_prefs: {user_prefs}")
        
        if min_daily_amount is not None:
            user_prefs["min_daily_amount"] = min_daily_amount
            logger.info(f"[ProductService] ✅ min_daily_amount 추가: {min_daily_amount}g")
        else:
            logger.info(f"[ProductService] ⏭️ min_daily_amount 없음 (기본값 사용)")
            
        if max_daily_amount is not None:
            user_prefs["max_daily_amount"] = max_daily_amount
            logger.info(f"[ProductService] ✅ max_daily_amount 추가: {max_daily_amount}g")
        else:
            logger.info(f"[ProductService] ⏭️ max_daily_amount 없음 (기본값 사용)")
            
        if max_monthly_budget is not None:
            # USD를 원화로 변환 (price_per_kg가 원/kg 단위이므로)
            # 환율: 1 USD ≈ 1,330 KRW (2024년 기준)
            USD_TO_KRW_RATE = 1330.0
            max_monthly_budget_krw = int(max_monthly_budget * USD_TO_KRW_RATE)
            user_prefs["max_monthly_budget"] = max_monthly_budget_krw
            logger.info(f"[ProductService] ✅ max_monthly_budget 추가: {max_monthly_budget} USD (≈ {max_monthly_budget_krw}원)")
        else:
            logger.info(f"[ProductService] ⏭️ max_monthly_budget 없음 (기본값 사용)")
            
        if emphasized_concerns is not None:
            user_prefs["emphasized_concerns"] = emphasized_concerns
            logger.info(f"[ProductService] ✅ emphasized_concerns 추가: {emphasized_concerns}")
        else:
            logger.info(f"[ProductService] ⏭️ emphasized_concerns 없음 (기본값 사용)")
            
        if health_concern_priority:
            user_prefs["health_concern_priority"] = health_concern_priority
            logger.info(f"[ProductService] ✅ health_concern_priority 추가: {health_concern_priority}")
        elif emphasized_concerns and len(emphasized_concerns) > 0:
            # emphasized_concerns가 있으면 자동으로 health_concern_priority 활성화
            user_prefs["health_concern_priority"] = True
            logger.info(f"[ProductService] ✅ health_concern_priority 자동 활성화 (emphasized_concerns 있음)")
        else:
            logger.info(f"[ProductService] ⏭️ health_concern_priority 없음 (기본값 사용)")
        
        logger.info(f"[ProductService] ✅ 최종 user_prefs: {user_prefs}")
        
        # 3. 상품 정보 조회 (ingredient_profile, nutrition_facts 포함)
        result = await db.execute(
            select(Product)
            .options(
                selectinload(Product.ingredient_profile),
                selectinload(Product.nutrition_facts)
            )
            .where(Product.id == product_id)
        )
        product = result.scalar_one_or_none()
        
        if product is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Product not found"
            )
        
        if not product.ingredient_profile or product.ingredient_profile.parsed is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Product ingredient information is not available"
            )
        
        # 4. parsed JSON 파싱
        parsed = product.ingredient_profile.parsed
        if isinstance(parsed, str):
            parsed = json.loads(parsed)
        
        ingredients_text = product.ingredient_profile.ingredients_text or ""
        
        # 5. 유해 성분 캐시 로드
        harmful_ingredients_cache = await RecommendationScoringService._get_harmful_ingredients(db)
        
        # 6. 안전성 점수 계산
        safety_score, safety_reasons = await RecommendationScoringService.calculate_safety_score(
            pet_summary, product, parsed, ingredients_text, user_prefs, db, harmful_ingredients_cache
        )
        logger.info(f"[ProductService] 안전성 점수: {safety_score:.1f}")
        
        # 7. 적합성 점수 계산
        fitness_score, fitness_reasons, age_penalty = RecommendationScoringService.calculate_fitness_score(
            pet_summary, product, parsed, product.nutrition_facts, user_prefs
        )
        logger.info(f"[ProductService] 적합성 점수: {fitness_score:.1f}, 나이 패널티: {age_penalty:.1f}")
        
        # 8. 총점 계산
        total_score = RecommendationScoringService.calculate_total_score(
            safety_score, fitness_score, age_penalty, user_prefs
        )
        logger.info(f"[ProductService] 총점: {total_score:.1f}")
        
        # 9. 매칭 이유 합치기
        all_reasons = safety_reasons + fitness_reasons
        
        # 10. 세부 점수 분해
        score_components = {
            "safety_score": safety_score,
            "fitness_score": fitness_score,
            "age_penalty": age_penalty,
            "total_score": total_score,
        }
        
        result = ProductMatchScoreResponse(
            product_id=product_id,
            pet_id=pet_id,
            match_score=total_score,
            safety_score=safety_score,
            fitness_score=fitness_score,
            match_reasons=all_reasons,
            score_components=score_components,
            calculated_at=datetime.now(timezone.utc)
        )
        
        # UPDATED: Redis 캐시 저장
        await RecommendationCacheService.set_product_match_score(product_id, pet_id, result)
        logger.info(f"[ProductService] ✅ 맞춤 점수 계산 완료 및 캐시 저장: product_id={product_id}, pet_id={pet_id}")
        
        return result

    @staticmethod
    async def get_active_products_with_parsed(db: AsyncSession) -> List[Product]:
        """parsed JSON이 있는 활성 상품 목록 조회 (Quick 추천 / 풀 추천 공통 재사용)."""
        result = await db.execute(
            select(Product)
            .options(
                selectinload(Product.ingredient_profile),
                selectinload(Product.nutrition_facts),
                selectinload(Product.offers),
            )
            .where(
                and_(
                    Product.is_active == True,
                    Product.ingredient_profile.has(ProductIngredientProfile.parsed.isnot(None)),
                )
            )
        )
        return list(result.scalars().all())
    
    @staticmethod
    async def get_recommendations(
        pet_id: UUID,
        db: AsyncSession,
        force_refresh: bool = False,
        generate_explanation_only: bool = False,
        min_daily_amount: Optional[int] = None,
        max_daily_amount: Optional[int] = None,
        max_monthly_budget: Optional[int] = None,
        emphasized_concerns: Optional[List[str]] = None,
        health_concern_priority: bool = False,
    ) -> RecommendationResponse:
        """
        추천 상품 목록 조회 (룰베이스 기반, 항상 RAG 실행)
        
        설계 문서 기반 룰베이스 스코링 시스템:
        - 안전성 점수 (60%): 알레르기, 유해 성분, 품질
        - 적합성 점수 (40%): 종류, 나이, 건강 고민, 품종, 영양
        
        Args:
            pet_id: 반려동물 ID
            db: 데이터베이스 세션
            force_refresh: 캐시 무시하고 새로 계산 (RAG 강제 실행)
            generate_explanation_only: 기존 추천 결과에 RAG 설명만 생성 (전체 재계산 없음)
        """
        start_time = time.time()
        logger.info(f"[ProductService] 🎯 추천 요청 시작: pet_id={pet_id}, force_refresh={force_refresh}, generate_explanation_only={generate_explanation_only}")
        
        # UPDATED: RAG 설명만 생성하는 경우 (전체 재계산 없음)
        if generate_explanation_only:
            logger.info(f"[ProductService] 🎯 RAG 설명만 생성 모드: 기존 추천 결과에 explanation만 추가")
            return await ProductService._generate_explanations_only(pet_id, db)
        
        # UPDATED: Redis 캐시 체크 (force_refresh가 False일 때만)
        if not force_refresh:
            from app.core.cache.recommendation_cache_service import RecommendationCacheService
            
            cached_recommendation = await RecommendationCacheService.get_recommendation(pet_id)
            if cached_recommendation:
                logger.info(f"[ProductService] ✅ Redis 캐시 히트: pet_id={pet_id}")
                return cached_recommendation
            
            logger.debug(f"[ProductService] ❌ Redis 캐시 미스: pet_id={pet_id}, PostgreSQL 확인")
        
        # UPDATED: Caching & User Prefs for recommendation freshness - 캐싱 체크
        # force_refresh가 True면 캐싱 무시
        if not force_refresh:
            cache_threshold = datetime.now(timezone.utc) - timedelta(days=7)
            latest_run_result = await db.execute(
                select(RecommendationRun)
                .where(RecommendationRun.pet_id == pet_id)
                .order_by(desc(RecommendationRun.created_at))
                .limit(1)
            )
            latest_run = latest_run_result.scalar_one_or_none()
            
            # datetime 비교 시 timezone-aware로 통일
            if latest_run:
                # latest_run.created_at이 timezone-aware인지 확인
                latest_created_at = latest_run.created_at
                if latest_created_at.tzinfo is None:
                    # timezone-naive인 경우 UTC로 가정
                    latest_created_at = latest_created_at.replace(tzinfo=timezone.utc)
                
                if latest_created_at >= cache_threshold:
                    # 캐싱된 추천 반환 (7일 이내)
                    logger.info(f"[ProductService] 💾 캐싱된 추천 사용: run_id={latest_run.id}, created_at={latest_run.created_at}")
                    logger.info(f"[ProductService] ⚠️ RAG 호출 스킵됨 (캐싱된 결과 사용). RAG를 테스트하려면 force_refresh=true 파라미터 사용")
                
                # RecommendationItem들 조회
                items_result = await db.execute(
                    select(RecommendationItem)
                    .where(RecommendationItem.run_id == latest_run.id)
                    .order_by(RecommendationItem.rank.asc())
                    .limit(10)
                )
                db_items = items_result.scalars().all()
                logger.info(f"[ProductService] 📦 캐시에서 가져온 추천 아이템: run_id={latest_run.id}, 개수={len(db_items)}개")
                
                # Product 정보 eager load
                product_ids = [item.product_id for item in db_items]
                logger.info(f"[ProductService] 🔍 조회할 product_ids: {product_ids}")
                products_result = await db.execute(
                    select(Product)
                    .options(
                        selectinload(Product.offers),
                        selectinload(Product.ingredient_profile),
                        selectinload(Product.nutrition_facts)
                    )
                    .where(Product.id.in_(product_ids))
                )
                products = {p.id: p for p in products_result.scalars().all()}
                logger.info(f"[ProductService] 🔍 조회된 products: {list(products.keys())}, 개수={len(products)}개")
                
                # RecommendationItemSchema로 변환
                recommendation_items = []
                filtered_count = 0
                for db_item in db_items:
                    product = products.get(db_item.product_id)
                    if not product:
                        logger.warning(f"[ProductService] ⚠️ Product를 찾을 수 없음: product_id={db_item.product_id}, rank={db_item.rank}")
                        filtered_count += 1
                        continue
                    
                    # Primary offer 찾기
                    primary_offer = None
                    for offer in product.offers:
                        if offer.is_primary and offer.is_active:
                            primary_offer = offer
                            break
                    
                    if not primary_offer:
                        for offer in product.offers:
                            if offer.is_active:
                                primary_offer = offer
                                break
                    
                    if not primary_offer:
                        offer_merchant = Merchant.COUPANG
                        current_price = 0
                        avg_price = 0
                        delta_percent = None
                        is_new_low = False
                    else:
                        offer_merchant = primary_offer.merchant
                        current_price = 0
                        avg_price = 0
                        delta_percent = None
                        is_new_low = False
                    
                    # score_components에서 점수 추출
                    score_components = db_item.score_components or {}
                    safety_score = score_components.get("safety_score", 0.0)
                    fitness_score = score_components.get("fitness_score", 0.0)
                    total_score = float(db_item.score)
                    
                    # 저장된 explanation은 없으므로 None (히스토리에서는 제외했었음)
                    # 하지만 캐싱된 경우라도 explanation을 저장했다면 사용 가능
                    explanation = None
                    
                    # v1.1.0: 캐싱된 경우 새 필드 기본값 설정
                    # (실제 데이터는 없으므로 기본값 사용)
                    animation_explanation = None
                    safety_badges = None
                    confidence_score = 75.0  # 기본 신뢰도
                    
                    recommendation_items.append(
                        RecommendationItemSchema(
                            product=ProductRead.model_validate(product),
                            offer_merchant=offer_merchant,
                            current_price=current_price,
                            avg_price=avg_price,
                            delta_percent=delta_percent,
                            is_new_low=is_new_low,
                            match_score=total_score,
                            safety_score=safety_score,
                            fitness_score=fitness_score,
                            match_reasons=db_item.reasons or [],
                            technical_explanation=None,  # 캐싱된 경우에는 없음 (나중에 생성 가능)
                            expert_explanation=None,  # 캐싱된 경우에는 없음 (나중에 생성 가능)
                            explanation=None,  # 하위 호환성: None
                            # v1.1.0 추가 필드 (캐싱된 경우 기본값)
                            animation_explanation=animation_explanation,
                            safety_badges=safety_badges,
                            confidence_score=confidence_score,
                        )
                    )
                
                logger.info(f"[ProductService] 📊 최종 recommendation_items: {len(recommendation_items)}개 (필터링됨: {filtered_count}개)")
                
                # 캐싱된 응답 생성
                recommendation_response = RecommendationResponse(
                    pet_id=pet_id,
                    items=recommendation_items,
                    is_cached=True,
                    last_recommended_at=latest_run.created_at
                )
                
                # UPDATED: PostgreSQL에서 가져온 결과를 Redis에 저장
                from app.core.cache.recommendation_cache_service import RecommendationCacheService
                await RecommendationCacheService.set_recommendation(pet_id, recommendation_response)
                logger.info(f"[ProductService] ✅ PostgreSQL → Redis 캐시 저장 완료")
                
                return recommendation_response
        else:
            logger.info(f"[ProductService] 🔄 force_refresh=true: 캐시 무시하고 새로 계산")
        
        # 캐싱되지 않은 경우 또는 force_refresh인 경우: 풀 스코링 진행
        logger.info(f"[ProductService] 🔄 새로운 추천 계산 시작 (캐시 없음 또는 만료 또는 force_refresh)")
        
        # 1. 펫 프로필 조회
        pet = await db.get(Pet, pet_id)
        if pet is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Pet not found"
            )
        
        # PetSummaryResponse 생성
        pet_summary = await ProductService._build_pet_summary(pet, db)
        logger.info(f"[ProductService] 펫 프로필: {pet_summary.name}, 종류={pet_summary.species}, 나이={pet_summary.age_stage}")
        
        # ADDED: User Prefs Customization - 사용자 선호도 불러오기
        user_id = pet.user_id
        user_prefs_result = await db.execute(
            select(UserRecoPrefs).where(UserRecoPrefs.user_id == user_id)
        )
        user_prefs_obj = user_prefs_result.scalars().first()
        
        # 기본 선호도 설정
        default_prefs = {
            "weights_preset": "BALANCED",
            "hard_exclude_allergens": [],
            "soft_avoid_ingredients": [],
            "max_price_per_kg": None,
            "sort_preference": "default",
            "health_concern_priority": False,
        }
        
        if user_prefs_obj and user_prefs_obj.prefs:
            user_prefs = {**default_prefs, **user_prefs_obj.prefs}
        else:
            user_prefs = default_prefs
        
        logger.info(f"[ProductService] 사용자 선호도: {user_prefs.get('weights_preset', 'BALANCED')} 모드")
        
        # 2. parsed JSON이 있는 활성 상품 조회 (재사용 메서드)
        products = await ProductService.get_active_products_with_parsed(db)
        logger.info(f"[ProductService] parsed JSON이 있는 상품 수: {len(products)}")
        
        if not products:
            logger.warning("[ProductService] 추천 가능한 상품 없음 (parsed JSON이 있는 상품 없음)")
            pet_species = pet_summary.species if pet_summary.species else None
            message = "상품 정보가 준비되지 않았습니다. 잠시 후 다시 시도해주세요."
            return RecommendationResponse(
                pet_id=pet_id, 
                items=[],
                is_cached=False,
                last_recommended_at=None,
                message=message
            )
        
        # 3. 빠른 종류 체크 (스코링 전 종류 불일치 100% 확인)
        logger.info(f"[ProductService] 🔍 빠른 종류 체크 시작: {len(products)}개 상품")
        species_matched_count = 0
        for product in products:
            try:
                species_match_result = RecommendationScoringService._match_species(pet_summary, product)
                if species_match_result[0] > 0:  # 종류 매칭됨 (0점이 아니면)
                    species_matched_count += 1
            except Exception as e:
                logger.debug(f"[ProductService] 종류 체크 중 에러 (무시하고 계속): {str(e)}")
                continue
        
        # 종류 불일치가 100%면 바로 종료
        if species_matched_count == 0:
            logger.warning(f"[ProductService] 모든 상품이 종류 불일치 ({len(products)}개 상품 모두 제외)")
            species_name = "고양이" if pet_summary.species == "CAT" else ("강아지" if pet_summary.species == "DOG" else "반려동물")
            message = f"{species_name} 전용 사료를 찾지 못했어요. 현재 등록된 상품 중 {species_name} 전용 사료가 없습니다. 펫 정보를 확인해주세요."
            return RecommendationResponse(
                pet_id=pet_id,
                items=[],
                is_cached=False,
                last_recommended_at=None,
                message=message
            )
        
        logger.info(f"[ProductService] ✅ 종류 매칭된 상품: {species_matched_count}/{len(products)}개, 스코링 진행")
        
        # 3.5. DB에서 유해 성분 및 알레르기 키워드 캐시 로드 (성능 최적화)
        logger.info("[ProductService] 🔍 유해 성분 및 알레르기 키워드 로드 중...")
        harmful_ingredients_cache = await RecommendationScoringService._get_harmful_ingredients(db)
        logger.info(f"[ProductService] ✅ 유해 성분 {len(harmful_ingredients_cache)}개 로드 완료")
        
        # 알레르기 키워드 캐시 (allergen_code -> keywords)
        allergen_keywords_cache = {}
        pet_allergies = set(pet_summary.food_allergies or [])
        for allergen_code in pet_allergies:
            keywords = await RecommendationScoringService._get_allergen_keywords(db, allergen_code)
            if keywords:
                allergen_keywords_cache[allergen_code] = keywords
        logger.info(f"[ProductService] ✅ 알레르기 키워드 {len(allergen_keywords_cache)}개 코드 로드 완료")
        
        # 4. 각 상품에 대해 스코링
        scored_products: List[Tuple[Product, float, float, float, List[str]]] = []
        # (product, total_score, safety_score, fitness_score, reasons)
        
        # 필터링 통계 추적 (사용자 친화적 메시지 생성용)
        filter_stats = {
            "total": len(products),
            "safety_filtered": 0,  # 안전성 0점으로 제외
            "fitness_filtered": 0,  # 적합성 0점으로 제외 (종류 불일치 포함)
            "price_filtered": 0,  # 가격 제한 초과
            "total_score_filtered": 0,  # 총점 < 0으로 제외
            "parsed_none": 0,  # parsed JSON이 None
            "scoring_error": 0,  # 스코링 중 에러 발생
        }
        
        logger.info(f"[ProductService] 📊 상품 스코링 시작: {len(products)}개 상품")
        scoring_start_time = time.time()
        
        for idx, product in enumerate(products, 1):
            try:
                logger.debug(f"[ProductService] [{idx}/{len(products)}] 스코링 중: product_id={product.id}, brand={product.brand_name}, name={product.product_name}")
                
                # parsed JSON 파싱
                parsed = product.ingredient_profile.parsed
                if isinstance(parsed, str):
                    parsed = json.loads(parsed)
                elif parsed is None:
                    logger.debug(f"[ProductService] [{idx}/{len(products)}] ⏭️ parsed JSON이 None. 스킵.")
                    filter_stats["parsed_none"] += 1
                    continue
                
                ingredients_text = product.ingredient_profile.ingredients_text or ""
                
                # ADDED: User Prefs Customization - 안전성 점수 계산 (user_prefs 전달)
                safety_score, safety_reasons = await RecommendationScoringService.calculate_safety_score(
                    pet_summary, product, parsed, ingredients_text, user_prefs, db, harmful_ingredients_cache
                )
                logger.debug(f"[ProductService] [{idx}/{len(products)}] 안전성 점수: {safety_score:.1f}, 이유: {safety_reasons[:2] if safety_reasons else []}")
                
                # 안전성 점수가 0이면 제외
                if safety_score == 0:
                    logger.debug(f"[ProductService] [{idx}/{len(products)}] ❌ 안전성 0점으로 제외")
                    filter_stats["safety_filtered"] += 1
                    continue
                
                # ADDED: User Prefs Customization - 적합성 점수 계산 (user_prefs 전달)
                fitness_score, fitness_reasons, age_penalty = RecommendationScoringService.calculate_fitness_score(
                    pet_summary, product, parsed, product.nutrition_facts, user_prefs
                )
                logger.debug(f"[ProductService] [{idx}/{len(products)}] 적합성 점수: {fitness_score:.1f}, 나이 패널티: {age_penalty:.1f}, 이유: {fitness_reasons[:2] if fitness_reasons else []}")
                
                # 하루 권장 급여량 계산
                daily_amount_g = None
                try:
                    der = RecommendationScoringService._calculate_der(
                        pet_summary.weight_kg,
                        pet_summary.age_stage,
                        pet_summary.is_neutered,
                        pet_summary.species
                    )
                    
                    # kcal_per_kg 계산
                    kcal_per_kg = None
                    nutritional_profile = parsed.get("nutritional_profile", {})
                    if nutritional_profile:
                        if "kcal_per_kg" in nutritional_profile:
                            kcal_per_kg = nutritional_profile["kcal_per_kg"]
                        elif "kcal_per_100g" in nutritional_profile:
                            kcal_per_kg = nutritional_profile["kcal_per_100g"] * 10
                    
                    if kcal_per_kg is None and product.nutrition_facts and product.nutrition_facts.kcal_per_100g:
                        kcal_per_kg = float(product.nutrition_facts.kcal_per_100g) * 10
                    
                    if kcal_per_kg is not None and kcal_per_kg > 0:
                        # UPDATED: 사용자 지정 급여량 범위가 있으면 중간값 사용, 없으면 DER 기반 계산
                        user_min = user_prefs.get("min_daily_amount")
                        user_max = user_prefs.get("max_daily_amount")
                        if user_min is not None and user_max is not None:
                            # 사용자 지정 범위의 중간값을 추천용 daily_amount_g로 사용
                            daily_amount_g = (user_min + user_max) / 2
                            logger.debug(f"[ProductService] [{idx}/{len(products)}] 급여량 계산: 사용자 지정 범위 중간값 사용 ({user_min}g ~ {user_max}g → {daily_amount_g:.1f}g)")
                        else:
                            # 기존 DER 기반 계산
                            daily_amount_g = (der / kcal_per_kg) * 1000
                            logger.debug(f"[ProductService] [{idx}/{len(products)}] 급여량 계산: DER={der:.1f}kcal, kcal_per_kg={kcal_per_kg:.1f}, daily_amount={daily_amount_g:.1f}g")
                except Exception as e:
                    logger.warning(f"[ProductService] [{idx}/{len(products)}] 급여량 계산 실패: {str(e)}")
                    daily_amount_g = None
                
                # 종류 점수가 0이면 제외
                if fitness_score == 0:
                    logger.debug(f"[ProductService] [{idx}/{len(products)}] ❌ 적합성 0점으로 제외")
                    filter_stats["fitness_filtered"] += 1
                    continue
                
                # ADDED: User Prefs Customization - 총점 계산 (user_prefs 전달)
                total_score = RecommendationScoringService.calculate_total_score(
                    safety_score, fitness_score, age_penalty, user_prefs
                )
                
                # ADDED: User Prefs Customization - max_price_per_kg 페널티 적용
                max_price_per_kg = user_prefs.get("max_price_per_kg")
                price_exceeded = False
                if max_price_per_kg is not None and product.price_per_kg is not None:
                    price_per_kg = float(product.price_per_kg)
                    if price_per_kg > max_price_per_kg:
                        total_score -= 30.0
                        price_exceeded = True
                        all_reasons.append(f"가격 제한 초과 ({price_per_kg:.0f}원/kg > {max_price_per_kg}원/kg)")
                
                # all_reasons 초기화 (월 예산 필터링에서 사용하기 위해)
                all_reasons = safety_reasons + fitness_reasons
                
                # UPDATED: 월 예산 필터링/페널티 적용
                max_monthly_budget = user_prefs.get("max_monthly_budget")
                monthly_budget_exceeded = False
                if max_monthly_budget is not None and daily_amount_g is not None and product.price_per_kg is not None:
                    # 월 비용 계산: daily_amount_g (g) * 30일 * (price_per_kg / 1000) (원/g)
                    # price_per_kg는 원/kg 단위, max_monthly_budget은 원화로 변환된 값
                    monthly_cost = daily_amount_g * 30 * (float(product.price_per_kg) / 1000)
                    logger.debug(f"[ProductService] [{idx}/{len(products)}] 💰 월 예산 체크: max_budget={max_monthly_budget}원, monthly_cost={monthly_cost:.0f}원, daily_amount_g={daily_amount_g:.1f}g, price_per_kg={product.price_per_kg}원/kg")
                    
                    if monthly_cost > max_monthly_budget * 1.2:
                        # 120% 초과 → 하드 필터링 (후보 제외)
                        logger.debug(f"[ProductService] [{idx}/{len(products)}] ❌ 월 예산 120% 초과로 제외: {monthly_cost:.0f}원 > {max_monthly_budget * 1.2:.0f}원")
                        filter_stats["monthly_budget_filtered"] += 1
                        continue
                    elif monthly_cost > max_monthly_budget:
                        # 초과 ~ 120% → 소프트 페널티
                        over_ratio = (monthly_cost - max_monthly_budget) / max_monthly_budget
                        penalty = 20 + (over_ratio / 0.2) * 10  # 20~30점
                        total_score -= penalty
                        monthly_budget_exceeded = True
                        all_reasons.append(f"월 예산 약간 초과: 예상 {monthly_cost:.0f}원 > {max_monthly_budget}원 (-{penalty:.0f}점)")
                        logger.debug(f"[ProductService] [{idx}/{len(products)}] 월 예산 초과 페널티: {monthly_cost:.0f}원 > {max_monthly_budget}원, penalty={penalty:.0f}점")
                
                logger.debug(f"[ProductService] [{idx}/{len(products)}] 총점: {total_score:.1f} (안전: {safety_score:.1f}, 적합: {fitness_score:.1f})")
                
                # 총점이 -1이면 제외 (안전성 0점)
                if total_score < 0:
                    logger.debug(f"[ProductService] [{idx}/{len(products)}] ❌ 총점 < 0으로 제외")
                    if price_exceeded:
                        filter_stats["price_filtered"] += 1
                    elif monthly_budget_exceeded:
                        filter_stats["monthly_budget_filtered"] += 1
                    else:
                        filter_stats["total_score_filtered"] += 1
                    continue
                scored_products.append((product, total_score, safety_score, fitness_score, all_reasons))
                logger.debug(f"[ProductService] [{idx}/{len(products)}] ✅ 추천 목록에 추가: 총점={total_score:.1f}")
                
            except Exception as e:
                logger.error(f"[ProductService] [{idx}/{len(products)}] ❌ 상품 스코링 실패: product_id={product.id}, error={str(e)}", exc_info=True)
                filter_stats["scoring_error"] += 1
                continue
        
        scoring_duration_ms = int((time.time() - scoring_start_time) * 1000)
        logger.info(f"[ProductService] ✅ 스코링 완료: {len(scored_products)}개 상품 통과, 소요시간={scoring_duration_ms}ms")
        logger.info(f"[ProductService] 필터링 통계: {filter_stats}")
        
        if not scored_products:
            logger.warning("[ProductService] 추천 가능한 상품 없음 (모든 상품이 필터링됨)")
            
            # 사용자 친화적 메시지 생성
            message = _generate_empty_recommendation_message(
                filter_stats, pet_summary.species if pet_summary.species else None
            )
            
            return RecommendationResponse(
                pet_id=pet_id, 
                items=[],
                is_cached=False,
                last_recommended_at=None,
                message=message
            )
        
        # ADDED: User Prefs Customization - 정렬 (사용자 선호도 반영)
        logger.info(f"[ProductService] 🔄 상품 정렬 시작: {len(scored_products)}개")
        sort_preference = user_prefs.get("sort_preference", "default")
        
        if sort_preference == "price_asc":
            # total desc → price asc
            def sort_key(x):
                product, total_score, safety_score, fitness_score, reasons = x
                price_per_kg = float(product.price_per_kg) if product.price_per_kg is not None else float('inf')
                return (-total_score, price_per_kg)  # 총점 내림차순, 가격 오름차순
            
            scored_products.sort(key=sort_key)
            logger.info(f"[ProductService] 가격 우선 정렬 적용됨")
        else:
            # 기본 정렬: 총점 내림차순, 동점 시 안전성 점수 내림차순
            scored_products.sort(key=lambda x: (x[1], x[2]), reverse=True)
        
        # 5. 상위 3개 선택 (최대 3개)
        max_products = min(3, len(scored_products))
        top_products = scored_products[:max_products]
        logger.info(f"[ProductService] 📋 상위 {len(top_products)}개 상품 선택 완료 (총 {len(scored_products)}개 중, 최대 3개)")
        for idx, (product, total_score, safety_score, fitness_score, reasons) in enumerate(top_products, 1):
            logger.info(f"[ProductService]   {idx}. {product.brand_name} {product.product_name}: 총점={total_score:.1f}, 안전={safety_score:.1f}, 적합={fitness_score:.1f}")
        
        # 6. RecommendationItem 생성 (LLM 설명 포함)
        logger.info(f"[ProductService] 🤖 LLM 설명 생성 시작: {len(top_products)}개 상품")
        llm_start_time = time.time()
        recommendation_items = []
        for idx, (product, total_score, safety_score, fitness_score, reasons) in enumerate(top_products, 1):
            logger.debug(f"[ProductService] [{idx}/{len(top_products)}] LLM 설명 생성 중: product_id={product.id}")
            # Primary offer 찾기
            primary_offer = None
            for offer in product.offers:
                if offer.is_primary and offer.is_active:
                    primary_offer = offer
                    break
            
            # Primary offer가 없으면 첫 번째 활성 offer 사용
            if not primary_offer:
                for offer in product.offers:
                    if offer.is_active:
                        primary_offer = offer
                        break
            
            # Offer가 없으면 기본값 사용
            if not primary_offer:
                offer_merchant = Merchant.COUPANG
                current_price = 0
                avg_price = 0
                delta_percent = None
                is_new_low = False
            else:
                offer_merchant = primary_offer.merchant
                # TODO: 가격 정보는 PriceSnapshot에서 가져오기 (현재는 기본값)
                current_price = 0
                avg_price = 0
                delta_percent = None
                is_new_low = False
            
            # ADDED: User Prefs Customization - 기술적 설명만 생성 (빠름, RAG 없음)
            technical_explanation = None
            expert_explanation = None
            logger.info(f"[ProductService] [{idx}/{len(top_products)}] 🔧 기술적 설명 생성 시작: product_id={product.id}")
            try:
                explanation_start = time.time()
                technical_explanation = await RecommendationExplanationService.generate_technical_explanation(
                    pet_name=pet_summary.name,
                    pet_species=pet_summary.species,
                    pet_age_stage=pet_summary.age_stage,
                    pet_weight=pet_summary.weight_kg,
                    pet_breed=pet_summary.breed_code,
                    pet_neutered=pet_summary.is_neutered,
                    health_concerns=pet_summary.health_concerns or [],
                    allergies=pet_summary.food_allergies or [],
                    brand_name=product.brand_name,
                    product_name=product.product_name,
                    technical_reasons=reasons,
                    user_prefs=user_prefs
                )
                explanation_duration_ms = int((time.time() - explanation_start) * 1000)
                logger.debug(f"[ProductService] [{idx}/{len(top_products)}] ✅ 기술적 설명 생성 완료: 소요시간={explanation_duration_ms}ms, 길이={len(technical_explanation) if technical_explanation else 0}자")
            except Exception as e:
                explanation_duration_ms = int((time.time() - explanation_start) * 1000)
                logger.error(f"[ProductService] [{idx}/{len(top_products)}] ❌ 기술적 설명 생성 실패: product_id={product.id}, error={str(e)}, 소요시간={explanation_duration_ms}ms")
                # 실패해도 계속 진행 (technical_explanation은 None)
            
            # 하위 호환성: explanation 필드에 technical_explanation 값 설정
            explanation = technical_explanation
            
            # ADDED: 애니메이션용 상세 분석 데이터 추출
            parsed = product.ingredient_profile.parsed if product.ingredient_profile else {}
            if isinstance(parsed, str):
                parsed = json.loads(parsed)
            elif parsed is None:
                parsed = {}
            
            ingredients_ordered = parsed.get("ingredients_ordered", [])
            ingredient_count = len(ingredients_ordered) if ingredients_ordered else 0
            
            # 주요 성분 추출 (상위 6개)
            main_ingredients = ingredients_ordered[:6] if ingredients_ordered else []
            
            # 알레르기 성분 추출 (DB에서 키워드 조회)
            allergy_ingredients = []
            pet_allergies = set(pet_summary.food_allergies or [])
            ingredients_lower = " ".join(ingredients_ordered).lower() + " " + (product.ingredient_profile.ingredients_text or "").lower()
            
            for allergen_code in pet_allergies:
                # 캐시에서 키워드 가져오기 (없으면 DB 조회)
                keywords = allergen_keywords_cache.get(allergen_code)
                if keywords is None:
                    keywords = await RecommendationScoringService._get_allergen_keywords(db, allergen_code)
                    allergen_keywords_cache[allergen_code] = keywords
                
                for keyword in keywords:
                    if keyword.lower() in ingredients_lower:
                        allergy_ingredients.append(keyword)
                        break
            
            # 유해 성분 추출 (캐시 사용)
            harmful_ingredients = []
            for harmful in harmful_ingredients_cache:
                if harmful.lower() in ingredients_lower:
                    harmful_ingredients.append(harmful)
            
            # 품질 체크리스트 생성
            quality_checklist = []
            if parsed.get("first_ingredient_is_meat", False):
                first_ingredient = ingredients_ordered[0] if ingredients_ordered else "동물성 단백질"
                quality_checklist.append(f"첫 성분: 동물성 단백질 ({first_ingredient})")
            else:
                quality_checklist.append("첫 성분: 동물성 단백질")
            
            protein_quality = parsed.get("protein_source_quality", "low")
            if protein_quality == "high":
                quality_checklist.append("단백질 함량: 적정 수준")
            else:
                quality_checklist.append("단백질 함량: 적정 수준")
            
            # 급여량 계산된 값 사용
            if daily_amount_g is not None:
                quality_checklist.append(f"하루 권장 급여량: 약 {daily_amount_g:.0f}g")
            else:
                quality_checklist.append("하루 권장 급여량: 계산 불가 (칼로리 정보 없음)")
            
            # v1.1.0: 애니메이션용 짧은 설명 생성
            animation_explanation = None
            if main_ingredients:
                first_ingredient = main_ingredients[0] if main_ingredients else ""
                if not allergy_ingredients:
                    animation_explanation = f"{first_ingredient} ZERO, 단일단백질"
                else:
                    animation_explanation = f"{first_ingredient} 기반"
            
            # v1.1.0: 안전성 배지 생성
            safety_badges = []
            if not allergy_ingredients:
                safety_badges.append("알레르기 안전")
            if not harmful_ingredients:
                safety_badges.append("유해성분 없음")
            if safety_score >= 90:
                safety_badges.append("고품질")
            
            # v1.1.0: RAG 신뢰도 점수 (임시로 explanation이 있으면 높은 점수, 없으면 낮은 점수)
            # TODO: 실제 RAG 구현 시 Confidence Score 계산 로직 추가
            confidence_score = 85.0 if explanation else 70.0
            
            recommendation_items.append(
                RecommendationItemSchema(
                    product=ProductRead.model_validate(product),
                    offer_merchant=offer_merchant,
                    current_price=current_price,
                    avg_price=avg_price,
                    delta_percent=delta_percent,
                    is_new_low=is_new_low,
                    match_score=total_score,  # 총점
                    safety_score=safety_score,  # 안전성 점수
                    fitness_score=fitness_score,  # 적합성 점수
                    match_reasons=reasons,  # 기술적 이유 리스트
                    technical_explanation=technical_explanation,  # 기술적 설명 (빠름)
                    expert_explanation=expert_explanation,  # 전문가 설명 (RAG 기반, 느림)
                    explanation=explanation,  # 하위 호환성: technical_explanation과 동일
                    # 애니메이션용 상세 분석 데이터
                    ingredient_count=ingredient_count,
                    main_ingredients=main_ingredients,
                    allergy_ingredients=allergy_ingredients,
                    harmful_ingredients=harmful_ingredients,
                    quality_checklist=quality_checklist,
                    daily_amount_g=daily_amount_g,
                    # v1.1.0 추가 필드
                    animation_explanation=animation_explanation,
                    safety_badges=safety_badges if safety_badges else None,
                    confidence_score=confidence_score,
                )
            )
        
        llm_duration_ms = int((time.time() - llm_start_time) * 1000)
        total_duration_ms = int((time.time() - start_time) * 1000)
        logger.info(f"[ProductService] ✅ 추천 완료: {len(recommendation_items)}개 상품 반환, LLM 소요시간={llm_duration_ms}ms, 전체 소요시간={total_duration_ms}ms")
        
        # 7. 추천 히스토리 저장
        try:
            save_start_time = time.time()
            # PetSummary를 JSON으로 직렬화하여 context에 저장
            context = {
                "pet_id": str(pet_summary.id),
                "pet_name": pet_summary.name,
                "species": pet_summary.species,
                "age_stage": pet_summary.age_stage,
                "weight_kg": float(pet_summary.weight_kg),
                "breed_code": pet_summary.breed_code,
                "is_neutered": pet_summary.is_neutered,
                "sex": pet_summary.sex,
                "health_concerns": pet_summary.health_concerns or [],
                "food_allergies": pet_summary.food_allergies or [],
                "other_allergies": pet_summary.other_allergies,
            }
            
            # ADDED: User Prefs Customization - RecommendationRun 생성 (prefs_snapshot 포함)
            recommendation_run = RecommendationRun(
                user_id=pet.user_id,
                pet_id=pet_id,
                strategy=RecStrategy.RULE_V1,
                context={
                    **context,
                    "prefs_snapshot": user_prefs  # 사용자 선호도 스냅샷 저장
                }
            )
            db.add(recommendation_run)
            await db.flush()  # run_id를 얻기 위해 flush
            
            # RecommendationItem 생성
            for rank, item in enumerate(recommendation_items, 1):
                db_item = RecommendationItem(
                    run_id=recommendation_run.id,
                    product_id=item.product.id,
                    rank=rank,
                    score=item.match_score,
                    reasons=item.match_reasons or [],
                    score_components={
                        "safety_score": item.safety_score,
                        "fitness_score": item.fitness_score,
                        "total_score": item.match_score,
                    }
                )
                db.add(db_item)
            
            await db.commit()
            save_duration_ms = int((time.time() - save_start_time) * 1000)
            logger.info(f"[ProductService] 💾 추천 히스토리 저장 완료: run_id={recommendation_run.id}, items={len(recommendation_items)}개, 소요시간={save_duration_ms}ms")
            
            # 저장된 아이템 개수 확인
            saved_items_result = await db.execute(
                select(RecommendationItem)
                .where(RecommendationItem.run_id == recommendation_run.id)
            )
            saved_items_count = len(saved_items_result.scalars().all())
            logger.info(f"[ProductService] ✅ DB에 실제 저장된 아이템 개수 확인: run_id={recommendation_run.id}, 저장된 개수={saved_items_count}개")
        except Exception as e:
            await db.rollback()
            logger.error(f"[ProductService] ❌ 추천 히스토리 저장 실패: {str(e)}", exc_info=True)
            # 히스토리 저장 실패해도 추천 결과는 반환
        
        # UPDATED: Caching & User Prefs for recommendation freshness - 응답에 캐싱 정보 포함
        recommendation_response = RecommendationResponse(
            pet_id=pet_id,
            items=recommendation_items,
            is_cached=False,
            last_recommended_at=datetime.now(timezone.utc) if recommendation_items else None
        )
        
        # UPDATED: 새로 계산한 결과를 Redis에 저장
        from app.core.cache.recommendation_cache_service import RecommendationCacheService
        await RecommendationCacheService.set_recommendation(pet_id, recommendation_response)
        logger.info(f"[ProductService] ✅ 새 추천 계산 → Redis 캐시 저장 완료")
        
        return recommendation_response
    
    @staticmethod
    async def _generate_explanations_only(
        pet_id: UUID,
        db: AsyncSession
    ) -> RecommendationResponse:
        """
        기존 추천 결과에 RAG 설명만 생성 (전체 재계산 없음)
        
        Args:
            pet_id: 반려동물 ID
            db: 데이터베이스 세션
        
        Returns:
            RecommendationResponse: 기존 추천 결과 + RAG 설명
        """
        logger.info(f"[ProductService] 🎯 RAG 설명만 생성 모드 시작: pet_id={pet_id}")
        
        # 1. 펫 프로필 조회 (RAG 설명 생성에 필요)
        pet = await db.get(Pet, pet_id)
        if pet is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Pet not found"
            )
        
        pet_summary = await ProductService._build_pet_summary(pet, db)
        logger.info(f"[ProductService] 펫 프로필: {pet_summary.name}, 종류={pet_summary.species}, 나이={pet_summary.age_stage}")
        
        # 2. 사용자 선호도 불러오기
        user_id = pet.user_id
        user_prefs_result = await db.execute(
            select(UserRecoPrefs).where(UserRecoPrefs.user_id == user_id)
        )
        user_prefs_obj = user_prefs_result.scalars().first()
        
        default_prefs = {
            "weights_preset": "BALANCED",
            "hard_exclude_allergens": [],
            "soft_avoid_ingredients": [],
            "max_price_per_kg": None,
            "sort_preference": "default",
            "health_concern_priority": False,
        }
        
        if user_prefs_obj and user_prefs_obj.prefs:
            user_prefs = {**default_prefs, **user_prefs_obj.prefs}
        else:
            user_prefs = default_prefs
        
        # 3. 캐시된 추천 결과 가져오기
        cache_threshold = datetime.now(timezone.utc) - timedelta(days=7)
        latest_run_result = await db.execute(
            select(RecommendationRun)
            .where(RecommendationRun.pet_id == pet_id)
            .order_by(desc(RecommendationRun.created_at))
            .limit(1)
        )
        latest_run = latest_run_result.scalar_one_or_none()
        
        if not latest_run:
            logger.warning(f"[ProductService] ⚠️ 캐시된 추천 결과 없음: pet_id={pet_id}")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No cached recommendation found. Please run full recommendation first."
            )
        
        # datetime 비교 시 timezone-aware로 통일
        latest_created_at = latest_run.created_at
        if latest_created_at.tzinfo is None:
            latest_created_at = latest_created_at.replace(tzinfo=timezone.utc)
        
        if latest_created_at < cache_threshold:
            logger.warning(f"[ProductService] ⚠️ 캐시 만료: pet_id={pet_id}, created_at={latest_created_at}")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Cached recommendation expired. Please run full recommendation first."
            )
        
        logger.info(f"[ProductService] 💾 캐시된 추천 사용: run_id={latest_run.id}, created_at={latest_run.created_at}")
        
        # 4. RecommendationItem들 조회
        items_result = await db.execute(
            select(RecommendationItem)
            .where(RecommendationItem.run_id == latest_run.id)
            .order_by(RecommendationItem.rank.asc())
            .limit(10)
        )
        db_items = items_result.scalars().all()
        
        if not db_items:
            logger.warning(f"[ProductService] ⚠️ 추천 아이템 없음: run_id={latest_run.id}")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No recommendation items found."
            )
        
        # 5. Product 정보 eager load
        product_ids = [item.product_id for item in db_items]
        products_result = await db.execute(
            select(Product)
            .options(
                selectinload(Product.offers),
                selectinload(Product.ingredient_profile),
                selectinload(Product.nutrition_facts)
            )
            .where(Product.id.in_(product_ids))
        )
        products = {p.id: p for p in products_result.scalars().all()}
        
        # 6. 기존 추천 결과에 RAG 설명만 추가
        logger.info(f"[ProductService] 🤖 RAG 설명 생성 시작: {len(db_items)}개 상품")
        recommendation_items = []
        
        for idx, db_item in enumerate(db_items, 1):
            product = products.get(db_item.product_id)
            if not product:
                continue
            
            # Primary offer 찾기
            primary_offer = None
            for offer in product.offers:
                if offer.is_primary and offer.is_active:
                    primary_offer = offer
                    break
            
            if not primary_offer:
                for offer in product.offers:
                    if offer.is_active:
                        primary_offer = offer
                        break
            
            if not primary_offer:
                offer_merchant = Merchant.COUPANG
                current_price = 0
                avg_price = 0
                delta_percent = None
                is_new_low = False
            else:
                offer_merchant = primary_offer.merchant
                current_price = 0
                avg_price = 0
                delta_percent = None
                is_new_low = False
            
            # score_components에서 점수 추출
            score_components = db_item.score_components or {}
            safety_score = score_components.get("safety_score", 0.0)
            fitness_score = score_components.get("fitness_score", 0.0)
            total_score = float(db_item.score)
            
            # 전문가 설명(RAG) 생성 (기존 추천 결과의 reasons 사용)
            reasons = db_item.reasons or []
            expert_explanation = None
            logger.info(f"[ProductService] [{idx}/{len(db_items)}] 🎓 전문가 설명(RAG) 생성 시작: product_id={product.id}")
            try:
                explanation_start = time.time()
                expert_explanation = await RecommendationExplanationService.generate_expert_explanation(
                    pet_name=pet_summary.name,
                    pet_species=pet_summary.species,
                    pet_age_stage=pet_summary.age_stage,
                    pet_weight=pet_summary.weight_kg,
                    pet_breed=pet_summary.breed_code,
                    pet_neutered=pet_summary.is_neutered,
                    health_concerns=pet_summary.health_concerns or [],
                    allergies=pet_summary.food_allergies or [],
                    brand_name=product.brand_name,
                    product_name=product.product_name,
                    technical_reasons=reasons,
                    user_prefs=user_prefs
                )
                explanation_duration_ms = int((time.time() - explanation_start) * 1000)
                logger.info(f"[ProductService] [{idx}/{len(db_items)}] ✅ 전문가 설명(RAG) 생성 완료: 소요시간={explanation_duration_ms}ms, 길이={len(expert_explanation) if expert_explanation else 0}자")
            except Exception as e:
                explanation_duration_ms = int((time.time() - explanation_start) * 1000)
                logger.error(f"[ProductService] [{idx}/{len(db_items)}] ❌ 전문가 설명(RAG) 생성 실패: product_id={product.id}, error={str(e)}, 소요시간={explanation_duration_ms}ms")
                # 실패해도 계속 진행 (expert_explanation은 None)
            
            # 기존 필드들 유지하고 expert_explanation만 추가
            logger.info(f"[ProductService] [{idx}/{len(db_items)}] 📦 RecommendationItemSchema 생성: expert_explanation={'있음' if expert_explanation else '없음'}, 길이={len(expert_explanation) if expert_explanation else 0}")
            recommendation_items.append(
                RecommendationItemSchema(
                    product=ProductRead.model_validate(product),
                    offer_merchant=offer_merchant,
                    current_price=current_price,
                    avg_price=avg_price,
                    delta_percent=delta_percent,
                    is_new_low=is_new_low,
                    match_score=total_score,
                    safety_score=safety_score,
                    fitness_score=fitness_score,
                    match_reasons=reasons,
                    technical_explanation=None,  # 기존 추천에는 기술적 설명 없음
                    expert_explanation=expert_explanation,  # 새로 생성된 전문가 설명(RAG)
                    explanation=expert_explanation,  # 하위 호환성: expert_explanation과 동일
                    # v1.1.0 추가 필드 (기본값)
                    animation_explanation=None,
                    safety_badges=None,
                    confidence_score=85.0 if expert_explanation else 70.0,
                )
            )
            logger.info(f"[ProductService] [{idx}/{len(db_items)}] ✅ RecommendationItemSchema 생성 완료: expert_explanation={'있음' if expert_explanation else '없음'}")
        
        logger.info(f"[ProductService] ✅ RAG 설명 생성 완료: {len(recommendation_items)}개 상품")
        
        return RecommendationResponse(
            pet_id=pet_id,
            items=recommendation_items,
            is_cached=True,  # 캐시된 결과에 설명만 추가했으므로 is_cached=True
            last_recommended_at=latest_run.created_at
        )
    
    @staticmethod
    async def get_recent_recommendation_history(
        pet_id: UUID,
        limit: int = 10,
        db: AsyncSession = None
    ) -> List[RecommendationItemSchema]:
        """
        최근 추천 히스토리 조회 (저장된 히스토리에서 조회)
        """
        logger.info(f"[ProductService] 📚 최근 추천 히스토리 조회 시작: pet_id={pet_id}, limit={limit}")
        
        # 가장 최근 추천 실행 조회
        result = await db.execute(
            select(RecommendationRun)
            .where(RecommendationRun.pet_id == pet_id)
            .order_by(RecommendationRun.created_at.desc())
            .limit(1)
        )
        latest_run = result.scalar_one_or_none()
        
        if not latest_run:
            logger.info(f"[ProductService] 📚 추천 히스토리 없음: pet_id={pet_id}")
            return []
        
        # 해당 실행의 추천 아이템들 조회 (상위 N개)
        items_result = await db.execute(
            select(RecommendationItem)
            .where(RecommendationItem.run_id == latest_run.id)
            .order_by(RecommendationItem.rank.asc())
            .limit(limit)
        )
        db_items = items_result.scalars().all()
        
        # Product 정보를 eager load
        product_ids = [item.product_id for item in db_items]
        products_result = await db.execute(
            select(Product)
            .options(
                selectinload(Product.offers),
                selectinload(Product.ingredient_profile),
                selectinload(Product.nutrition_facts)
            )
            .where(Product.id.in_(product_ids))
        )
        products = {p.id: p for p in products_result.scalars().all()}
        
        # RecommendationItemSchema로 변환
        recommendation_items = []
        for db_item in db_items:
            product = products.get(db_item.product_id)
            if not product:
                continue
            
            # Primary offer 찾기
            primary_offer = None
            for offer in product.offers:
                if offer.is_primary and offer.is_active:
                    primary_offer = offer
                    break
            
            if not primary_offer:
                for offer in product.offers:
                    if offer.is_active:
                        primary_offer = offer
                        break
            
            # Offer가 없으면 기본값 사용
            if not primary_offer:
                offer_merchant = Merchant.COUPANG
                current_price = 0
                avg_price = 0
                delta_percent = None
                is_new_low = False
            else:
                offer_merchant = primary_offer.merchant
                # TODO: 가격 정보는 PriceSnapshot에서 가져오기 (현재는 기본값)
                current_price = 0
                avg_price = 0
                delta_percent = None
                is_new_low = False
            
            # score_components에서 점수 추출
            score_components = db_item.score_components or {}
            safety_score = score_components.get("safety_score", 0.0)
            fitness_score = score_components.get("fitness_score", 0.0)
            total_score = float(db_item.score)
            
            recommendation_items.append(
                RecommendationItemSchema(
                    product=ProductRead.model_validate(product),
                    offer_merchant=offer_merchant,
                    current_price=current_price,
                    avg_price=avg_price,
                    delta_percent=delta_percent,
                    is_new_low=is_new_low,
                    match_score=total_score,
                    safety_score=safety_score,
                    fitness_score=fitness_score,
                    match_reasons=db_item.reasons or [],
                    explanation=None,  # 히스토리에서는 LLM 설명 제외 (용량 절약)
                )
            )
        
        logger.info(f"[ProductService] 📚 최근 추천 히스토리 조회 완료: {len(recommendation_items)}개")
        return recommendation_items
    
    @staticmethod
    async def _build_pet_summary(pet: Pet, db: AsyncSession) -> PetSummaryResponse:
        """Pet 모델을 PetSummaryResponse로 변환 (캐시 활용)"""
        from app.core.cache.recommendation_cache_service import RecommendationCacheService
        
        # UPDATED: Redis 캐시 체크
        cached_summary = await RecommendationCacheService.get_pet_summary(pet.id)
        if cached_summary:
            logger.debug(f"[ProductService] ✅ 펫 프로필 캐시 히트: pet_id={pet.id}")
            return PetSummaryResponse(**cached_summary)
        
        logger.debug(f"[ProductService] ❌ 펫 프로필 캐시 미스: pet_id={pet.id}, DB 조회")
        
        # Health concerns 조회
        result = await db.execute(
            select(PetHealthConcern.concern_code).where(
                PetHealthConcern.pet_id == pet.id
            )
        )
        health_concerns = [row[0] for row in result.all()]
        
        # Food allergies 조회
        result = await db.execute(
            select(PetFoodAllergy.allergen_code).where(
                PetFoodAllergy.pet_id == pet.id
            )
        )
        food_allergies = [row[0] for row in result.all()]
        
        # Other allergies 조회
        result = await db.execute(
            select(PetOtherAllergy.other_text).where(
                PetOtherAllergy.pet_id == pet.id
            )
        )
        other_allergy_row = result.first()
        other_allergies = other_allergy_row[0] if other_allergy_row else None
        
        pet_summary = PetSummaryResponse(
            id=pet.id,
            name=pet.name,
            species=pet.species.value,
            age_stage=pet.age_stage.value if pet.age_stage else None,
            approx_age_months=pet.approx_age_months,
            weight_kg=float(pet.weight_kg),
            health_concerns=health_concerns,
            photo_url=pet.photo_url,
            breed_code=pet.breed_code,
            is_neutered=pet.is_neutered,
            sex=pet.sex.value if pet.sex else None,
            food_allergies=food_allergies,
            other_allergies=other_allergies,
        )
        
        # UPDATED: Redis 캐시 저장
        await RecommendationCacheService.set_pet_summary(
            pet.id,
            pet_summary.model_dump(mode='json')
        )
        logger.debug(f"[ProductService] ✅ 펫 프로필 캐시 저장: pet_id={pet.id}")
        
        return pet_summary
    
    @staticmethod
    async def create_product(
        product_data: ProductCreate,
        db: AsyncSession
    ) -> Product:
        """상품 생성"""
        # 중복 체크 (unique constraint)
        result = await db.execute(
            select(Product).where(
                Product.brand_name == product_data.brand_name,
                Product.product_name == product_data.product_name,
                Product.size_label == product_data.size_label
            )
        )
        if result.scalar_one_or_none() is not None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Product with same brand_name, product_name, and size_label already exists"
            )
        
        product = Product(
            brand_name=product_data.brand_name,
            product_name=product_data.product_name,
            size_label=product_data.size_label,
            category=product_data.category,
            species=product_data.species,
            is_active=product_data.is_active,
        )
        
        db.add(product)
        try:
            await db.commit()
            await db.refresh(product)
        except IntegrityError as e:
            await db.rollback()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Failed to create product: {str(e)}"
            )
        
        return product
    
    @staticmethod
    async def update_product(
        product_id: UUID,
        product_data: ProductUpdate,
        db: AsyncSession
    ) -> Product:
        """상품 수정 (캐시 무효화 포함)"""
        from app.core.cache.recommendation_cache_service import RecommendationCacheService
        
        product = await ProductService.get_product_by_id(product_id, db)
        
        # 업데이트할 필드만 적용
        if product_data.brand_name is not None:
            product.brand_name = product_data.brand_name
        if product_data.product_name is not None:
            product.product_name = product_data.product_name
        if product_data.size_label is not None:
            product.size_label = product_data.size_label
        if product_data.category is not None:
            product.category = product_data.category
        if product_data.species is not None:
            product.species = product_data.species
        if product_data.is_active is not None:
            product.is_active = product_data.is_active
        
        try:
            await db.commit()
            await db.refresh(product)
            
            # UPDATED: 상품 업데이트 시 태그 기반 캐시 무효화
            # 해당 상품의 모든 맞춤 점수 캐시 삭제 (모든 펫에 대해)
            deleted_count = await RecommendationCacheService.invalidate_product_match_score(product_id)
            logger.info(f"[ProductService] ✅ 상품 업데이트 후 맞춤 점수 캐시 무효화: product_id={product_id}, deleted={deleted_count}개")
            
        except IntegrityError as e:
            await db.rollback()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Failed to update product: {str(e)}"
            )
        
        return product
    
    @staticmethod
    async def delete_product(product_id: UUID, db: AsyncSession) -> None:
        """상품 삭제 (소프트 삭제)"""
        product = await ProductService.get_product_by_id(product_id, db)
        product.is_active = False
        await db.commit()
    
    @staticmethod
    async def get_all_products(db: AsyncSession, include_inactive: bool = False) -> list[Product]:
        """모든 상품 목록 조회 (관리자용)"""
        query = select(Product)
        if not include_inactive:
            query = query.where(Product.is_active == True)
        result = await db.execute(query)
        return list(result.scalars().all())
    
    @staticmethod
    async def get_products_with_filters(
        db: AsyncSession,
        query: Optional[str] = None,
        species: Optional[str] = None,
        active: Optional[str] = None,  # 'ACTIVE', 'ARCHIVED', 'ALL'
        completion_status: Optional[str] = None,
        has_image: Optional[str] = None,  # 'YES', 'NO', 'ALL'
        has_offers: Optional[str] = None,  # 'YES', 'NO', 'ALL'
        sort: str = 'UPDATED_DESC',  # 'UPDATED_DESC', 'BRAND_ASC', 'INCOMPLETE_FIRST'
        page: int = 1,
        size: int = 30
    ) -> tuple[list[Product], int]:
        """상품 목록 조회 (필터링/정렬/페이지네이션)"""
        from sqlalchemy import func, or_, and_
        from sqlalchemy.orm import selectinload
        
        # Base query with relationships for computed fields
        # Eager load relationships to avoid lazy loading issues
        base_query = select(Product).options(
            selectinload(Product.offers),
            selectinload(Product.ingredient_profile),
            selectinload(Product.nutrition_facts)
        )
        
        # Filters
        conditions = []
        
        # Active filter
        if active == 'ACTIVE':
            conditions.append(Product.is_active == True)
        elif active == 'ARCHIVED':
            conditions.append(Product.is_active == False)
        # 'ALL' or None: no filter
        
        # Species filter
        if species and species != 'ALL':
            conditions.append(Product.species == species)
        
        # Query text filter (brand_name, product_name, size_label)
        if query:
            search_term = f"%{query}%"
            conditions.append(
                or_(
                    Product.brand_name.ilike(search_term),
                    Product.product_name.ilike(search_term),
                    Product.size_label.ilike(search_term)
                )
            )
        
        # Completion status filter (if column exists)
        if completion_status and completion_status != 'ALL':
            # Note: This assumes the column exists after migration
            try:
                conditions.append(Product.completion_status == completion_status)
            except AttributeError:
                pass  # Column not yet added
        
        if conditions:
            base_query = base_query.where(and_(*conditions))
        
        # Count total (before pagination) - 별도 쿼리로 생성 (selectinload 제외)
        count_base = select(Product)
        if conditions:
            count_base = count_base.where(and_(*conditions))
        count_query = select(func.count()).select_from(count_base.subquery())
        total_result = await db.execute(count_query)
        total = total_result.scalar() or 0
        
        # Sorting
        if sort == 'BRAND_ASC':
            base_query = base_query.order_by(Product.brand_name.asc(), Product.product_name.asc())
        elif sort == 'INCOMPLETE_FIRST':
            # Sort by completion_status (incomplete first), then by updated_at
            # Note: This assumes the column exists after migration
            try:
                from sqlalchemy import case
                base_query = base_query.order_by(
                    case(
                        (Product.completion_status == 'COMPLETE', 1),
                        else_=0
                    ).asc(),
                    Product.last_admin_updated_at.desc().nulls_last()
                )
            except AttributeError:
                base_query = base_query.order_by(Product.brand_name.asc())
        else:  # UPDATED_DESC (default)
            try:
                base_query = base_query.order_by(Product.last_admin_updated_at.desc().nulls_last())
            except AttributeError:
                base_query = base_query.order_by(Product.created_at.desc())
        
        # Pagination
        offset = (page - 1) * size
        base_query = base_query.offset(offset).limit(size)
        
        # Execute
        result = await db.execute(base_query)
        products = list(result.scalars().all())
        
        # Post-filter for has_image and has_offers (after fetching)
        if has_image == 'YES':
            products = [p for p in products if p.primary_image_url or p.thumbnail_url]
        elif has_image == 'NO':
            products = [p for p in products if not (p.primary_image_url or p.thumbnail_url)]
        
        if has_offers == 'YES':
            # Need to check offers count
            products_with_offers = []
            for p in products:
                offers_count = len(p.offers) if p.offers else 0
                if offers_count > 0:
                    products_with_offers.append(p)
            products = products_with_offers
        elif has_offers == 'NO':
            products_without_offers = []
            for p in products:
                offers_count = len(p.offers) if p.offers else 0
                if offers_count == 0:
                    products_without_offers.append(p)
            products = products_without_offers
        
        return products, total
    
    @staticmethod
    async def clear_recommendation_cache(
        pet_id: UUID,
        db: AsyncSession
    ) -> int:
        """
        추천 캐시 제거 (추천 재계산 없이 캐시만 삭제)
        
        Args:
            pet_id: 반려동물 ID
            db: 데이터베이스 세션
        
        Returns:
            삭제된 RecommendationRun 개수
        """
        logger.info(f"[ProductService] 🗑️ 캐시 제거 시작: pet_id={pet_id}")
        
        try:
            # 해당 pet_id의 모든 RecommendationRun 조회
            runs_result = await db.execute(
                select(RecommendationRun)
                .where(RecommendationRun.pet_id == pet_id)
            )
            runs = runs_result.scalars().all()
            
            deleted_count = len(runs)
            
            if deleted_count == 0:
                logger.info(f"[ProductService] 💾 삭제할 캐시 없음: pet_id={pet_id}")
                return 0
            
            # RecommendationRun 삭제 (cascade로 RecommendationItem도 자동 삭제됨)
            await db.execute(
                delete(RecommendationRun).where(RecommendationRun.pet_id == pet_id)
            )
            
            await db.commit()
            logger.info(f"[ProductService] ✅ 캐시 제거 완료: pet_id={pet_id}, deleted_runs={deleted_count}개")
            
            return deleted_count
        except Exception as e:
            await db.rollback()
            logger.error(f"[ProductService] ❌ 캐시 제거 실패: pet_id={pet_id}, error={str(e)}", exc_info=True)
            raise