"""섹션별 캐싱 서비스"""
import json
import logging
from typing import Optional, List
from datetime import datetime
from uuid import UUID

import redis.asyncio as redis

from app.core.redis import get_redis
from app.models.section import SectionType, ProductCategory, SectionConfig
from app.schemas.product import ProductRead

logger = logging.getLogger(__name__)


class SectionCacheService:
    """섹션별 Redis 캐싱 서비스"""
    
    @staticmethod
    def _generate_cache_key(
        section_type: SectionType,
        category: ProductCategory,
        limit: int,
        offset: int = 0,
        **kwargs
    ) -> str:
        """캐시 키 생성"""
        key_parts = [
            "sections",
            section_type.value,
            category.value,
            str(limit),
            str(offset),
        ]
        
        # 추가 파라미터가 있으면 포함
        if kwargs:
            sorted_kwargs = sorted(kwargs.items())
            key_parts.extend([f"{k}:{v}" for k, v in sorted_kwargs])
        
        return ":".join(key_parts)
    
    @staticmethod
    async def get_cached_section(
        section_type: SectionType,
        category: ProductCategory,
        limit: int,
        offset: int = 0,
        **kwargs
    ) -> Optional[List[ProductRead]]:
        """캐시된 섹션 데이터 조회"""
        try:
            redis_client = await get_redis()
            cache_key = SectionCacheService._generate_cache_key(
                section_type, category, limit, offset, **kwargs
            )
            
            cached_data = await redis_client.get(cache_key)
            if cached_data:
                logger.debug(f"[SectionCache] ✅ 캐시 히트: {cache_key}")
                products_data = json.loads(cached_data)
                return [ProductRead(**p) for p in products_data]
            
            logger.debug(f"[SectionCache] ❌ 캐시 미스: {cache_key}")
            return None
        except Exception as e:
            logger.warning(f"[SectionCache] 캐시 조회 실패: {e}", exc_info=True)
            return None
    
    @staticmethod
    async def set_cached_section(
        section_type: SectionType,
        category: ProductCategory,
        products: List[ProductRead],
        limit: int,
        offset: int = 0,
        **kwargs
    ) -> None:
        """섹션 데이터 캐싱"""
        try:
            redis_client = await get_redis()
            cache_key = SectionCacheService._generate_cache_key(
                section_type, category, limit, offset, **kwargs
            )
            ttl = SectionConfig.get_cache_ttl(section_type)
            
            products_data = [p.model_dump() for p in products]
            await redis_client.setex(
                cache_key,
                ttl,
                json.dumps(products_data, default=str)
            )
            logger.debug(f"[SectionCache] ✅ 캐시 저장: {cache_key}, TTL={ttl}초")
        except Exception as e:
            logger.warning(f"[SectionCache] 캐시 저장 실패: {e}", exc_info=True)
    
    @staticmethod
    async def invalidate_section(
        section_type: SectionType,
        category: Optional[ProductCategory] = None
    ) -> None:
        """섹션 캐시 무효화"""
        try:
            redis_client = await get_redis()
            
            if category:
                pattern = f"sections:{section_type.value}:{category.value}:*"
            else:
                pattern = f"sections:{section_type.value}:*"
            
            keys = []
            async for key in redis_client.scan_iter(match=pattern):
                keys.append(key)
            
            if keys:
                await redis_client.delete(*keys)
                logger.info(f"[SectionCache] ✅ 캐시 무효화: {len(keys)}개 키 삭제 (pattern={pattern})")
        except Exception as e:
            logger.warning(f"[SectionCache] 캐시 무효화 실패: {e}", exc_info=True)
