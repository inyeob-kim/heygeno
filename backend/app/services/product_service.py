"""상품 관련 비즈니스 로직"""
from typing import Optional, List, Tuple
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_
from sqlalchemy.orm import selectinload
from fastapi import HTTPException, status
from sqlalchemy.exc import IntegrityError
import json
import logging
import time

from app.models.product import Product, ProductIngredientProfile, ProductNutritionFacts
from app.models.pet import Pet, PetHealthConcern, PetFoodAllergy, PetOtherAllergy
from app.models.recommendation import RecommendationRun, RecommendationItem, RecStrategy
from app.schemas.product import ProductRead, ProductCreate, ProductUpdate, RecommendationResponse, RecommendationItem as RecommendationItemSchema
from app.schemas.pet_summary import PetSummaryResponse
from app.models.offer import Merchant, ProductOffer
from app.services.recommendation_scoring_service import RecommendationScoringService
from app.services.recommendation_explanation_service import RecommendationExplanationService

logger = logging.getLogger(__name__)


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
    async def get_recommendations(
        pet_id: UUID,
        db: AsyncSession
    ) -> RecommendationResponse:
        """
        추천 상품 목록 조회 (룰베이스 기반)
        
        설계 문서 기반 룰베이스 스코링 시스템:
        - 안전성 점수 (60%): 알레르기, 유해 성분, 품질
        - 적합성 점수 (40%): 종류, 나이, 건강 고민, 품종, 영양
        """
        start_time = time.time()
        logger.info(f"[ProductService] 🎯 추천 요청 시작: pet_id={pet_id}")
        
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
        
        # 2. parsed JSON이 있는 활성 상품 조회 (eager load)
        result = await db.execute(
            select(Product)
            .options(
                selectinload(Product.ingredient_profile),
                selectinload(Product.nutrition_facts),
                selectinload(Product.offers)
            )
            .where(
                and_(
                    Product.is_active == True,
                    Product.ingredient_profile.has(ProductIngredientProfile.parsed.isnot(None))
                )
            )
        )
        products = list(result.scalars().all())
        logger.info(f"[ProductService] parsed JSON이 있는 상품 수: {len(products)}")
        
        if not products:
            logger.warning("[ProductService] 추천 가능한 상품 없음 (parsed JSON이 있는 상품 없음)")
            return RecommendationResponse(pet_id=pet_id, items=[])
        
        # 3. 각 상품에 대해 스코링
        scored_products: List[Tuple[Product, float, float, float, List[str]]] = []
        # (product, total_score, safety_score, fitness_score, reasons)
        
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
                    continue
                
                ingredients_text = product.ingredient_profile.ingredients_text or ""
                
                # 안전성 점수 계산
                safety_score, safety_reasons = RecommendationScoringService.calculate_safety_score(
                    pet_summary, product, parsed, ingredients_text
                )
                logger.debug(f"[ProductService] [{idx}/{len(products)}] 안전성 점수: {safety_score:.1f}, 이유: {safety_reasons[:2] if safety_reasons else []}")
                
                # 안전성 점수가 0이면 제외
                if safety_score == 0:
                    logger.debug(f"[ProductService] [{idx}/{len(products)}] ❌ 안전성 0점으로 제외")
                    continue
                
                # 적합성 점수 계산
                fitness_score, fitness_reasons, age_penalty = RecommendationScoringService.calculate_fitness_score(
                    pet_summary, product, parsed, product.nutrition_facts
                )
                logger.debug(f"[ProductService] [{idx}/{len(products)}] 적합성 점수: {fitness_score:.1f}, 나이 패널티: {age_penalty:.1f}, 이유: {fitness_reasons[:2] if fitness_reasons else []}")
                
                # 종류 점수가 0이면 제외
                if fitness_score == 0:
                    logger.debug(f"[ProductService] [{idx}/{len(products)}] ❌ 적합성 0점으로 제외")
                    continue
                
                # 총점 계산
                total_score = RecommendationScoringService.calculate_total_score(
                    safety_score, fitness_score, age_penalty
                )
                logger.debug(f"[ProductService] [{idx}/{len(products)}] 총점: {total_score:.1f} (안전: {safety_score:.1f}, 적합: {fitness_score:.1f})")
                
                # 총점이 -1이면 제외 (안전성 0점)
                if total_score < 0:
                    logger.debug(f"[ProductService] [{idx}/{len(products)}] ❌ 총점 < 0으로 제외")
                    continue
                
                all_reasons = safety_reasons + fitness_reasons
                scored_products.append((product, total_score, safety_score, fitness_score, all_reasons))
                logger.debug(f"[ProductService] [{idx}/{len(products)}] ✅ 추천 목록에 추가: 총점={total_score:.1f}")
                
            except Exception as e:
                logger.error(f"[ProductService] [{idx}/{len(products)}] ❌ 상품 스코링 실패: product_id={product.id}, error={str(e)}", exc_info=True)
                continue
        
        scoring_duration_ms = int((time.time() - scoring_start_time) * 1000)
        logger.info(f"[ProductService] ✅ 스코링 완료: {len(scored_products)}개 상품 통과, 소요시간={scoring_duration_ms}ms")
        
        if not scored_products:
            logger.warning("[ProductService] 추천 가능한 상품 없음 (모든 상품이 필터링됨)")
            return RecommendationResponse(pet_id=pet_id, items=[])
        
        # 4. 정렬 (총점 내림차순, 동점 시 안전성 점수 내림차순)
        logger.info(f"[ProductService] 🔄 상품 정렬 시작: {len(scored_products)}개")
        scored_products.sort(key=lambda x: (x[1], x[2]), reverse=True)
        
        # 5. 상위 10개 선택
        top_products = scored_products[:10]
        logger.info(f"[ProductService] 📋 상위 {len(top_products)}개 상품 선택 완료")
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
            
            # LLM으로 추천 이유 설명 생성
            explanation = None
            try:
                explanation_start = time.time()
                explanation = await RecommendationExplanationService.generate_explanation(
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
                    technical_reasons=reasons
                )
                explanation_duration_ms = int((time.time() - explanation_start) * 1000)
                logger.debug(f"[ProductService] [{idx}/{len(top_products)}] ✅ LLM 설명 생성 완료: 소요시간={explanation_duration_ms}ms, 길이={len(explanation) if explanation else 0}자")
            except Exception as e:
                explanation_duration_ms = int((time.time() - explanation_start) * 1000)
                logger.error(f"[ProductService] [{idx}/{len(top_products)}] ❌ LLM 설명 생성 실패: product_id={product.id}, error={str(e)}, 소요시간={explanation_duration_ms}ms")
                # 실패해도 계속 진행 (explanation은 None)
            
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
                    explanation=explanation,  # 자연어 설명
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
            
            # RecommendationRun 생성
            recommendation_run = RecommendationRun(
                user_id=pet.user_id,
                pet_id=pet_id,
                strategy=RecStrategy.RULE_V1,
                context=context
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
            logger.info(f"[ProductService] 💾 추천 히스토리 저장 완료: run_id={recommendation_run.id}, 소요시간={save_duration_ms}ms")
        except Exception as e:
            await db.rollback()
            logger.error(f"[ProductService] ❌ 추천 히스토리 저장 실패: {str(e)}", exc_info=True)
            # 히스토리 저장 실패해도 추천 결과는 반환
        
        return RecommendationResponse(
            pet_id=pet_id,
            items=recommendation_items,
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
        """Pet 모델을 PetSummaryResponse로 변환"""
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
        
        return PetSummaryResponse(
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
        """상품 수정"""
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