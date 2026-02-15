"""마켓 섹션 관련 모델"""
import enum
from typing import Optional
from datetime import datetime, timedelta


class SectionType(str, enum.Enum):
    """마켓 섹션 타입"""
    HOT_DEAL = "hot_deal"  # 오늘의 핫딜
    POPULAR = "popular"  # 실시간 인기 사료
    NEW = "new"  # 신상품
    REVIEW_BEST = "review_best"  # 리뷰 베스트
    PERSONALIZED = "personalized"  # 사용자 맞춤 추천


class ProductCategory(str, enum.Enum):
    """상품 카테고리 필터"""
    ALL = "all"
    DOG = "dog"
    CAT = "cat"


class SectionConfig:
    """섹션별 설정"""
    
    # 섹션별 Redis TTL (초)
    CACHE_TTL = {
        SectionType.HOT_DEAL: 3600,  # 1시간
        SectionType.POPULAR: 300,  # 5분
        SectionType.NEW: 1800,  # 30분
        SectionType.REVIEW_BEST: 7200,  # 2시간
        SectionType.PERSONALIZED: 600,  # 10분
    }
    
    # 섹션별 기본 limit
    DEFAULT_LIMIT = {
        SectionType.HOT_DEAL: 5,
        SectionType.POPULAR: 5,
        SectionType.NEW: 10,
        SectionType.REVIEW_BEST: 5,
        SectionType.PERSONALIZED: 5,
    }
    
    # 섹션별 최대 limit
    MAX_LIMIT = {
        SectionType.HOT_DEAL: 20,
        SectionType.POPULAR: 20,
        SectionType.NEW: 50,
        SectionType.REVIEW_BEST: 20,
        SectionType.PERSONALIZED: 20,
    }
    
    @classmethod
    def get_cache_ttl(cls, section_type: SectionType) -> int:
        """섹션별 캐시 TTL 반환"""
        return cls.CACHE_TTL.get(section_type, 3600)
    
    @classmethod
    def get_default_limit(cls, section_type: SectionType) -> int:
        """섹션별 기본 limit 반환"""
        return cls.DEFAULT_LIMIT.get(section_type, 5)
    
    @classmethod
    def get_max_limit(cls, section_type: SectionType) -> int:
        """섹션별 최대 limit 반환"""
        return cls.MAX_LIMIT.get(section_type, 20)
