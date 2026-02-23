"""상품 API 라우터 - 라우팅만 담당"""
from fastapi import APIRouter, Depends, Query, Body, status, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID
from sqlalchemy import select, delete
from typing import List, Optional
import logging
import time

from app.db.session import get_db
from app.schemas.product import ProductRead, RecommendationResponse, ProductMatchScoreResponse, ProductDetailResponse
from app.schemas.section import (
    SectionRequest, SectionResponse, BatchSectionRequest, BatchSectionResponse
)
from app.services.product_service import ProductService
from app.services.section_service import SectionService
from app.models.offer import ProductOffer
from app.models.section import SectionType, ProductCategory

logger = logging.getLogger(__name__)
router = APIRouter()


@router.get("/", response_model=list[ProductRead])
async def get_products(db: AsyncSession = Depends(get_db)):
    """상품 목록 조회 (레거시 - 하위 호환성 유지)"""
    products = await ProductService.get_active_products(db)
    return [ProductRead.model_validate(p) for p in products]


@router.get("/sections/{section_type}", response_model=SectionResponse)
async def get_section(
    section_type: SectionType,
    category: ProductCategory = Query(ProductCategory.ALL, description="카테고리 필터"),
    limit: Optional[int] = Query(None, ge=1, le=50, description="조회할 상품 수"),
    offset: Optional[int] = Query(0, ge=0, description="페이지네이션 오프셋"),
    time_range: Optional[str] = Query(None, description="인기 섹션용: 24h, 7d, 30d"),
    days: Optional[int] = Query(None, description="신상품 섹션용: 신상품 기준 일수"),
    min_reviews: Optional[int] = Query(None, description="리뷰 베스트 섹션용: 최소 리뷰 수"),
    user_id: Optional[UUID] = Query(None, description="개인화 섹션용: 사용자 ID"),
    pet_id: Optional[UUID] = Query(None, description="개인화 섹션용: 펫 ID"),
    db: AsyncSession = Depends(get_db)
):
    """섹션별 상품 조회"""
    start_time = time.time()
    logger.info(
        f"[Products API] 📥 섹션 조회 요청: type={section_type.value}, "
        f"category={category.value}, limit={limit}, offset={offset}"
    )
    
    try:
        request = SectionRequest(
            type=section_type,
            category=category,
            limit=limit,
            offset=offset,
            time_range=time_range,
            days=days,
            min_reviews=min_reviews,
            user_id=user_id,
            pet_id=pet_id
        )
        
        result = await SectionService.get_section_products(db, request)
        duration_ms = int((time.time() - start_time) * 1000)
        logger.info(
            f"[Products API] ✅ 섹션 응답 반환: type={section_type.value}, "
            f"products={len(result.products)}개, cached={result.cached}, 소요시간={duration_ms}ms"
        )
        return result
    except Exception as e:
        duration_ms = int((time.time() - start_time) * 1000)
        logger.error(
            f"[Products API] ❌ 섹션 처리 실패: type={section_type.value}, "
            f"error={str(e)}, 소요시간={duration_ms}ms",
            exc_info=True
        )
        raise


@router.post("/sections/batch", response_model=BatchSectionResponse)
async def get_batch_sections(
    request: BatchSectionRequest = Body(...),
    db: AsyncSession = Depends(get_db)
):
    """배치 섹션 조회 (여러 섹션을 한 번에 조회)"""
    start_time = time.time()
    logger.info(
        f"[Products API] 📥 배치 섹션 조회 요청: sections={len(request.sections)}개"
    )
    
    try:
        results = await SectionService.get_batch_sections(db, request.sections)
        duration_ms = int((time.time() - start_time) * 1000)
        logger.info(
            f"[Products API] ✅ 배치 섹션 응답 반환: sections={len(results)}개, "
            f"소요시간={duration_ms}ms"
        )
        return BatchSectionResponse(sections=results)
    except Exception as e:
        duration_ms = int((time.time() - start_time) * 1000)
        logger.error(
            f"[Products API] ❌ 배치 섹션 처리 실패: error={str(e)}, 소요시간={duration_ms}ms",
            exc_info=True
        )
        raise


@router.get("/recommendations", response_model=RecommendationResponse)
async def get_recommendations(
    pet_id: UUID = Query(..., description="반려동물 ID"),
    force_refresh: bool = Query(False, description="캐시 무시하고 새로 계산 (RAG 강제 실행)"),
    generate_explanation_only: bool = Query(False, description="기존 추천 결과에 RAG 설명만 생성 (전체 재계산 없음)"),
    min_daily_amount: Optional[int] = Query(None, description="최소 하루 급여량 (g)"),
    max_daily_amount: Optional[int] = Query(None, description="최대 하루 급여량 (g)"),
    max_monthly_budget: Optional[int] = Query(None, description="최대 월 예산 (USD)"),
    emphasized_concerns: Optional[str] = Query(None, description="강조 건강 고민 (콤마로 구분, 예: '관절,피부')"),
    health_concern_priority: bool = Query(False, description="건강 고민 우선 모드"),
    db: AsyncSession = Depends(get_db)
):
    """추천 상품 목록 조회 (실시간 계산 + 히스토리 저장, 항상 RAG 실행)"""
    start_time = time.time()
    logger.info(f"[Products API] 📥 추천 요청 수신")
    logger.info(f"[Products API]   - pet_id: {pet_id}")
    logger.info(f"[Products API]   - force_refresh: {force_refresh}")
    logger.info(f"[Products API]   - generate_explanation_only: {generate_explanation_only}")
    logger.info(f"[Products API]   - min_daily_amount: {min_daily_amount}g" if min_daily_amount else "[Products API]   - min_daily_amount: None")
    logger.info(f"[Products API]   - max_daily_amount: {max_daily_amount}g" if max_daily_amount else "[Products API]   - max_daily_amount: None")
    logger.info(f"[Products API]   - max_monthly_budget: ${max_monthly_budget} USD" if max_monthly_budget else "[Products API]   - max_monthly_budget: None")
    logger.info(f"[Products API]   - emphasized_concerns: {emphasized_concerns}" if emphasized_concerns else "[Products API]   - emphasized_concerns: None")
    logger.info(f"[Products API]   - health_concern_priority: {health_concern_priority}")
    
    try:
        # emphasized_concerns 파싱 (콤마로 구분, 공백 trim)
        emphasized_concerns_list = None
        if emphasized_concerns:
            emphasized_concerns_list = [c.strip() for c in emphasized_concerns.split(",") if c.strip()]
            logger.info(f"[Products API] ✅ emphasized_concerns 파싱 완료: {emphasized_concerns_list}")
        else:
            logger.info(f"[Products API] ⏭️ emphasized_concerns 없음 (기본값 사용)")
        
        result = await ProductService.get_recommendations(
            pet_id, 
            db, 
            force_refresh=force_refresh,
            generate_explanation_only=generate_explanation_only,
            min_daily_amount=min_daily_amount,
            max_daily_amount=max_daily_amount,
            max_monthly_budget=max_monthly_budget,
            emphasized_concerns=emphasized_concerns_list,
            health_concern_priority=health_concern_priority,
        )
        duration_ms = int((time.time() - start_time) * 1000)
        logger.info(f"[Products API] ✅ 추천 응답 반환: pet_id={pet_id}, items={len(result.items)}개, is_cached={result.is_cached}, 소요시간={duration_ms}ms")
        return result
    except Exception as e:
        duration_ms = int((time.time() - start_time) * 1000)
        logger.error(f"[Products API] ❌ 추천 처리 실패: pet_id={pet_id}, error={str(e)}, 소요시간={duration_ms}ms", exc_info=True)
        raise


@router.get("/recommendations/history", response_model=RecommendationResponse)
async def get_recommendation_history(
    pet_id: UUID = Query(..., description="반려동물 ID"),
    limit: int = Query(10, description="조회할 추천 개수", ge=1, le=50),
    db: AsyncSession = Depends(get_db)
):
    """최근 추천 히스토리 조회 (저장된 히스토리에서 조회)"""
    start_time = time.time()
    logger.info(f"[Products API] 📚 최근 추천 히스토리 요청 수신: pet_id={pet_id}, limit={limit}")
    
    try:
        items = await ProductService.get_recent_recommendation_history(pet_id, limit, db)
        duration_ms = int((time.time() - start_time) * 1000)
        logger.info(f"[Products API] ✅ 히스토리 응답 반환: pet_id={pet_id}, items={len(items)}개, 소요시간={duration_ms}ms")
        return RecommendationResponse(pet_id=pet_id, items=items)
    except Exception as e:
        duration_ms = int((time.time() - start_time) * 1000)
        logger.error(f"[Products API] ❌ 히스토리 조회 실패: pet_id={pet_id}, error={str(e)}, 소요시간={duration_ms}ms", exc_info=True)
        raise


@router.delete("/recommendations/cache")
async def clear_recommendation_cache(
    pet_id: UUID = Query(..., description="반려동물 ID"),
    db: AsyncSession = Depends(get_db)
):
    """추천 캐시 제거 (Redis + PostgreSQL)"""
    start_time = time.time()
    logger.info(f"[Products API] 🗑️ 캐시 제거 요청 수신: pet_id={pet_id}")
    
    try:
        # UPDATED: Redis 캐시 삭제
        from app.core.cache.recommendation_cache_service import RecommendationCacheService
        redis_deleted = await RecommendationCacheService.invalidate_recommendation(pet_id)
        
        # PostgreSQL 캐시 삭제 (기존 로직)
        deleted_count = await ProductService.clear_recommendation_cache(pet_id, db)
        
        duration_ms = int((time.time() - start_time) * 1000)
        logger.info(f"[Products API] ✅ 캐시 제거 완료: pet_id={pet_id}, deleted_runs={deleted_count}, redis_keys_deleted={1 if redis_deleted else 0}, 소요시간={duration_ms}ms")
        return {
            "success": True,
            "pet_id": str(pet_id),
            "deleted_runs": deleted_count,
            "redis_keys_deleted": 1 if redis_deleted else 0
        }
    except Exception as e:
        duration_ms = int((time.time() - start_time) * 1000)
        logger.error(f"[Products API] ❌ 캐시 제거 실패: pet_id={pet_id}, error={str(e)}, 소요시간={duration_ms}ms", exc_info=True)
        raise


@router.delete("/recommendations/cache/all", status_code=status.HTTP_200_OK)
async def clear_all_recommendation_cache(
    db: AsyncSession = Depends(get_db)
):
    """전체 추천 캐시 제거 (모든 펫의 Redis + PostgreSQL 캐시)"""
    start_time = time.time()
    logger.info(f"[Products API] 🗑️ 전체 캐시 제거 요청 수신")
    
    try:
        # UPDATED: Redis 전체 캐시 삭제
        from app.core.cache.recommendation_cache_service import RecommendationCacheService
        redis_deleted = await RecommendationCacheService.invalidate_all_recommendations()
        
        # PostgreSQL 캐시 삭제 (모든 RecommendationRun 삭제)
        from app.models.recommendation import RecommendationRun
        delete_result = await db.execute(delete(RecommendationRun))
        await db.commit()
        db_deleted = delete_result.rowcount
        
        duration_ms = int((time.time() - start_time) * 1000)
        logger.info(f"[Products API] ✅ 전체 캐시 제거 완료: deleted_runs={db_deleted}, redis_keys_deleted={redis_deleted}, 소요시간={duration_ms}ms")
        return {
            "success": True,
            "deleted_runs": db_deleted,
            "redis_keys_deleted": redis_deleted
        }
    except Exception as e:
        await db.rollback()
        duration_ms = int((time.time() - start_time) * 1000)
        logger.error(f"[Products API] ❌ 전체 캐시 제거 실패: error={str(e)}, 소요시간={duration_ms}ms", exc_info=True)
        raise


@router.get("/{product_id}", response_model=ProductRead)
async def get_product(
    product_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """상품 상세 조회"""
    product = await ProductService.get_product_by_id(product_id, db)
    return ProductRead.model_validate(product)


@router.get("/{product_id}/detail", response_model=ProductDetailResponse)
async def get_product_detail(
    product_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """상품 상세 정보 조회 (가격, 성분, 영양, 클레임 포함)"""
    return await ProductService.get_product_detail(product_id, db)


@router.get("/{product_id}/offers")
async def get_product_offers(
    product_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """상품의 판매처 목록 조회"""
    result = await db.execute(
        select(ProductOffer).where(ProductOffer.product_id == product_id)
    )
    offers = result.scalars().all()
    return [{"id": str(o.id), "merchant": o.merchant.value, "url": o.url} for o in offers]


@router.get("/{product_id}/match-score", response_model=ProductMatchScoreResponse)
async def get_product_match_score(
    product_id: UUID,
    pet_id: UUID = Query(..., description="반려동물 ID"),
    db: AsyncSession = Depends(get_db)
):
    """특정 상품의 맞춤 점수 계산"""
    start_time = time.time()
    logger.info(f"[Products API] 📥 맞춤 점수 계산 요청: product_id={product_id}, pet_id={pet_id}")
    
    try:
        result = await ProductService.calculate_product_match_score(product_id, pet_id, db)
        duration_ms = int((time.time() - start_time) * 1000)
        logger.info(
            f"[Products API] ✅ 맞춤 점수 계산 완료: product_id={product_id}, pet_id={pet_id}, "
            f"match_score={result.match_score:.1f}, 소요시간={duration_ms}ms"
        )
        return result
    except HTTPException:
        raise
    except Exception as e:
        duration_ms = int((time.time() - start_time) * 1000)
        logger.error(
            f"[Products API] ❌ 맞춤 점수 계산 실패: product_id={product_id}, pet_id={pet_id}, "
            f"error={str(e)}, 소요시간={duration_ms}ms",
            exc_info=True
        )
        raise
