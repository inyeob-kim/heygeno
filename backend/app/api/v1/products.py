"""상품 API 라우터 - 라우팅만 담당"""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID
from sqlalchemy import select
import logging
import time

from app.db.session import get_db
from app.schemas.product import ProductRead, RecommendationResponse
from app.services.product_service import ProductService
from app.models.offer import ProductOffer

logger = logging.getLogger(__name__)
router = APIRouter()


@router.get("/", response_model=list[ProductRead])
async def get_products(db: AsyncSession = Depends(get_db)):
    """상품 목록 조회"""
    products = await ProductService.get_active_products(db)
    return [ProductRead.model_validate(p) for p in products]


@router.get("/recommendations", response_model=RecommendationResponse)
async def get_recommendations(
    pet_id: UUID = Query(..., description="반려동물 ID"),
    db: AsyncSession = Depends(get_db)
):
    """추천 상품 목록 조회 (실시간 계산 + 히스토리 저장)"""
    start_time = time.time()
    logger.info(f"[Products API] 📥 추천 요청 수신: pet_id={pet_id}")
    
    try:
        result = await ProductService.get_recommendations(pet_id, db)
        duration_ms = int((time.time() - start_time) * 1000)
        logger.info(f"[Products API] ✅ 추천 응답 반환: pet_id={pet_id}, items={len(result.items)}개, 소요시간={duration_ms}ms")
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


@router.get("/{product_id}", response_model=ProductRead)
async def get_product(
    product_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """상품 상세 조회"""
    product = await ProductService.get_product_by_id(product_id, db)
    return ProductRead.model_validate(product)


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
