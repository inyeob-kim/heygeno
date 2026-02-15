"""마켓 섹션별 서비스"""
import logging
from typing import List, Optional
from uuid import UUID
from datetime import datetime, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_, desc, func, case
from sqlalchemy.orm import selectinload

from app.models.product import Product, PetSpecies
from app.models.offer import ProductOffer
from app.models.section import SectionType, ProductCategory, SectionConfig
from app.schemas.section import SectionRequest, SectionResponse
from app.schemas.product import ProductRead
from app.services.section_cache_service import SectionCacheService

logger = logging.getLogger(__name__)


class SectionService:
    """마켓 섹션별 비즈니스 로직 서비스"""
    
    @staticmethod
    def _apply_category_filter(query, category: ProductCategory):
        """카테고리 필터 적용"""
        if category == ProductCategory.DOG:
            # DOG 전용 또는 species가 NULL인 상품 (공용)
            return query.where(
                or_(
                    Product.species == PetSpecies.DOG,
                    Product.species.is_(None)
                )
            )
        elif category == ProductCategory.CAT:
            # CAT 전용 또는 species가 NULL인 상품 (공용)
            return query.where(
                or_(
                    Product.species == PetSpecies.CAT,
                    Product.species.is_(None)
                )
            )
        # ALL인 경우 필터링 없음
        return query
    
    @staticmethod
    async def get_hot_deal_section(
        db: AsyncSession,
        category: ProductCategory,
        limit: int,
        offset: int = 0
    ) -> List[Product]:
        """오늘의 핫딜 섹션 조회"""
        # 할인이 있는 상품 우선, 없으면 일반 상품도 포함
        query = (
            select(Product)
            .outerjoin(ProductOffer, and_(
                Product.id == ProductOffer.product_id,
                ProductOffer.is_active == True,
                ProductOffer.is_primary == True
            ))
            .where(Product.is_active == True)
        )
        
        query = SectionService._apply_category_filter(query, category)
        
        # 할인율 계산 및 정렬
        # 할인이 있는 상품 우선, 없으면 가격 오름차순
        discount_percent = case(
            (
                and_(
                    ProductOffer.current_price.isnot(None),
                    ProductOffer.last_seen_price.isnot(None),
                    ProductOffer.last_seen_price > 0,
                    ProductOffer.current_price < ProductOffer.last_seen_price
                ),
                (ProductOffer.last_seen_price - ProductOffer.current_price) * 100.0 / ProductOffer.last_seen_price
            ),
            else_=0
        )
        
        # 할인율 내림차순, 가격 오름차순
        query = query.order_by(
            desc(discount_percent),
            ProductOffer.current_price.asc().nulls_last(),
            Product.created_at.desc()
        ).limit(limit).offset(offset)
        
        result = await db.execute(query)
        return list(result.scalars().all())
    
    @staticmethod
    async def get_popular_section(
        db: AsyncSession,
        category: ProductCategory,
        limit: int,
        offset: int = 0,
        time_range: str = "24h"
    ) -> List[Product]:
        """실시간 인기 사료 섹션 조회"""
        # TODO: 실제 조회수/클릭수 집계 테이블이 있으면 사용
        # 현재는 최근 생성된 상품 순으로 정렬 (임시)
        query = select(Product).where(Product.is_active == True)
        query = SectionService._apply_category_filter(query, category)
        
        # 최근 생성된 순으로 정렬
        query = query.order_by(desc(Product.created_at)).limit(limit).offset(offset)
        
        result = await db.execute(query)
        return list(result.scalars().all())
    
    @staticmethod
    async def get_new_section(
        db: AsyncSession,
        category: ProductCategory,
        limit: int,
        offset: int = 0,
        days: int = 30
    ) -> List[Product]:
        """신상품 섹션 조회"""
        cutoff_date = datetime.utcnow() - timedelta(days=days)
        
        query = select(Product).where(
            and_(
                Product.is_active == True,
                Product.created_at >= cutoff_date
            )
        )
        query = SectionService._apply_category_filter(query, category)
        query = query.order_by(desc(Product.created_at)).limit(limit).offset(offset)
        
        result = await db.execute(query)
        return list(result.scalars().all())
    
    @staticmethod
    async def get_review_best_section(
        db: AsyncSession,
        category: ProductCategory,
        limit: int,
        offset: int = 0,
        min_reviews: int = 10
    ) -> List[Product]:
        """리뷰 베스트 섹션 조회"""
        # TODO: 실제 리뷰 테이블이 있으면 사용
        # 현재는 임시로 최근 생성된 상품 순으로 정렬
        query = select(Product).where(Product.is_active == True)
        query = SectionService._apply_category_filter(query, category)
        query = query.order_by(desc(Product.created_at)).limit(limit).offset(offset)
        
        result = await db.execute(query)
        return list(result.scalars().all())
    
    @staticmethod
    async def get_personalized_section(
        db: AsyncSession,
        category: ProductCategory,
        limit: int,
        offset: int = 0,
        user_id: Optional[UUID] = None,
        pet_id: Optional[UUID] = None
    ) -> List[Product]:
        """사용자 맞춤 추천 섹션 조회"""
        # TODO: 실제 개인화 로직 구현 (구매 이력, 관심사 등)
        # 현재는 최근 생성된 상품 순으로 정렬 (임시)
        query = select(Product).where(Product.is_active == True)
        query = SectionService._apply_category_filter(query, category)
        query = query.order_by(desc(Product.created_at)).limit(limit).offset(offset)
        
        result = await db.execute(query)
        return list(result.scalars().all())
    
    @staticmethod
    async def get_section_products(
        db: AsyncSession,
        request: SectionRequest
    ) -> SectionResponse:
        """섹션별 상품 조회 (캐싱 포함)"""
        section_type = request.type
        category = request.category
        limit = request.limit or SectionConfig.get_default_limit(section_type)
        limit = min(limit, SectionConfig.get_max_limit(section_type))
        offset = request.offset or 0
        
        # 캐시 조회
        cache_kwargs = {}
        if request.time_range:
            cache_kwargs["time_range"] = request.time_range
        if request.days:
            cache_kwargs["days"] = str(request.days)
        if request.min_reviews:
            cache_kwargs["min_reviews"] = str(request.min_reviews)
        if request.user_id:
            cache_kwargs["user_id"] = str(request.user_id)
        if request.pet_id:
            cache_kwargs["pet_id"] = str(request.pet_id)
        
        cached_products = await SectionCacheService.get_cached_section(
            section_type, category, limit, offset, **cache_kwargs
        )
        
        if cached_products:
            logger.debug(f"[SectionService] 캐시에서 조회: {section_type.value}")
            return SectionResponse(
                type=section_type,
                category=category,
                products=cached_products,
                total=len(cached_products),
                limit=limit,
                offset=offset,
                cached=True,
                cached_at=datetime.utcnow()
            )
        
        # DB 조회
        products: List[Product]
        if section_type == SectionType.HOT_DEAL:
            products = await SectionService.get_hot_deal_section(
                db, category, limit, offset
            )
        elif section_type == SectionType.POPULAR:
            products = await SectionService.get_popular_section(
                db, category, limit, offset, request.time_range or "24h"
            )
        elif section_type == SectionType.NEW:
            products = await SectionService.get_new_section(
                db, category, limit, offset, request.days or 30
            )
        elif section_type == SectionType.REVIEW_BEST:
            products = await SectionService.get_review_best_section(
                db, category, limit, offset, request.min_reviews or 10
            )
        elif section_type == SectionType.PERSONALIZED:
            products = await SectionService.get_personalized_section(
                db, category, limit, offset, request.user_id, request.pet_id
            )
        else:
            raise ValueError(f"Unknown section type: {section_type}")
        
        # ProductRead로 변환
        product_reads = [ProductRead.model_validate(p) for p in products]
        
        # 캐시 저장
        await SectionCacheService.set_cached_section(
            section_type, category, product_reads, limit, offset, **cache_kwargs
        )
        
        return SectionResponse(
            type=section_type,
            category=category,
            products=product_reads,
            total=len(product_reads),
            limit=limit,
            offset=offset,
            cached=False
        )
    
    @staticmethod
    async def get_batch_sections(
        db: AsyncSession,
        requests: List[SectionRequest]
    ) -> List[SectionResponse]:
        """배치 섹션 조회"""
        # 병렬 처리로 모든 섹션 조회
        import asyncio
        tasks = [SectionService.get_section_products(db, req) for req in requests]
        return await asyncio.gather(*tasks)
