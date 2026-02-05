"""
사료 테스트 데이터 생성 스크립트
"""
import asyncio
import sys
from pathlib import Path
import random

# 프로젝트 루트를 Python path에 추가
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy import text
from decimal import Decimal
from app.models.product import (
    Product, 
    PetSpecies,
    ProductAllergen,
    ProductIngredientProfile,
    ProductNutritionFacts,
    ProductClaim,
)
from app.models.offer import ProductOffer, Merchant
from app.core.config import settings


def _get_default_allergens(brand_name: str, product_name: str) -> list[str]:
    """브랜드와 제품명에 따라 기본 알레르겐 반환"""
    # 로얄캐닌, 힐스: 닭고기, 계란, 밀/글루텐
    if "로얄캐닌" in brand_name or "힐스" in brand_name:
        return ["CHICKEN", "EGG", "WHEAT"]
    # 오리젠, 아카나: 닭고기, 생선, 계란
    elif "오리젠" in brand_name or "아카나" in brand_name:
        return ["CHICKEN", "FISH", "EGG"]
    # 네츄럴밸런스: 제한된 알레르겐 (닭고기만)
    elif "네츄럴밸런스" in brand_name:
        return ["CHICKEN"]
    # 기본: 닭고기, 계란
    else:
        return ["CHICKEN", "EGG"]


def _get_default_ingredients(brand_name: str, product_name: str, species: PetSpecies) -> dict:
    """기본 성분 프로필 반환"""
    if species == PetSpecies.DOG:
        ingredients = "옥수수, 닭고기분, 밀, 동물성 지방, 쌀, 비트펄프, 계란, 어분, 소맥분"
        additives = "비타민 A, 비타민 D3, 비타민 E, 철분, 아연, 구리, 망간"
    else:  # CAT
        ingredients = "옥수수, 닭고기분, 밀글루텐, 동물성 지방, 쌀, 비트펄프, 계란, 어분, 소맥분"
        additives = "비타민 A, 비타민 D3, 비타민 E, 타우린, 철분, 아연"
    
    if "오리젠" in brand_name or "아카나" in brand_name:
        ingredients = "닭고기, 칠면조, 연어, 계란, 완두콩, 렌틸콩, 병아리콩"
        additives = "비타민 A, 비타민 D3, 비타민 E, 오메가-3 지방산, 오메가-6 지방산"
    
    return {
        "ingredients_text": ingredients,
        "additives_text": additives,
        "source": "테스트 데이터",
    }


def _get_default_nutrition(brand_name: str, product_name: str, species: PetSpecies) -> dict:
    """기본 영양 정보 반환"""
    # 퍼피/키튼: 단백질 높음
    if "퍼피" in product_name or "키튼" in product_name or "주니어" in product_name:
        protein = Decimal("32.0")
        fat = Decimal("18.0")
        kcal = 420
    # 시니어: 단백질 중간, 칼로리 낮음
    elif "시니어" in product_name or "SENIOR" in product_name.upper():
        protein = Decimal("26.0")
        fat = Decimal("12.0")
        kcal = 350
    # 라이트/다이어트: 칼로리 낮음
    elif "라이트" in product_name or "다이어트" in product_name or "웨이트" in product_name:
        protein = Decimal("28.0")
        fat = Decimal("10.0")
        kcal = 320
    # 기본 어덜트
    else:
        protein = Decimal("28.0")
        fat = Decimal("15.0")
        kcal = 380
    
    # 오리젠, 아카나: 단백질 더 높음
    if "오리젠" in brand_name or "아카나" in brand_name:
        protein = Decimal(str(float(protein) + 4.0))
        fat = Decimal(str(float(fat) + 2.0))
        kcal += 30
    
    return {
        "protein_pct": protein,
        "fat_pct": fat,
        "fiber_pct": Decimal("3.5"),
        "moisture_pct": Decimal("10.0"),
        "ash_pct": Decimal("7.0"),
        "kcal_per_100g": kcal,
        "calcium_pct": Decimal("1.2"),
        "phosphorus_pct": Decimal("1.0"),
        "aafco_statement": "AAFCO 기준 충족",
    }


def _get_default_claims(brand_name: str, product_name: str, species: PetSpecies) -> list[str]:
    """기본 기능성 클레임 반환"""
    claims = []
    
    if "퍼피" in product_name or "키튼" in product_name or "주니어" in product_name:
        claims.append("PUPPY")
    if "시니어" in product_name or "SENIOR" in product_name.upper():
        claims.append("SENIOR")
    if "라이트" in product_name or "다이어트" in product_name or "웨이트" in product_name:
        claims.append("WEIGHT")
    if "인도어" in product_name or "인도" in product_name:
        claims.append("URINARY")
    if "치아" in product_name or "덴탈" in product_name.lower():
        claims.append("DENTAL")
    
    # 기본 클레임
    if not claims:
        claims.append("DIGESTIVE")
    
    return claims


# 테스트 데이터
TEST_PRODUCTS = [
    # 강아지 사료
    {
        "brand_name": "로얄캐닌",
        "product_name": "로얄캐닌 미니 어덜트",
        "size_label": "3kg",
        "species": PetSpecies.DOG,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_royal_mini_3kg",
                "url": "https://www.coupang.com/vp/products/123456",
                "affiliate_url": "https://www.coupang.com/vp/products/123456?affiliateId=test",
                "seller_name": "로얄캐닌 공식몰",
                "is_primary": True,
            },
            {
                "merchant": Merchant.NAVER,
                "merchant_product_id": "naver_royal_mini_3kg",
                "url": "https://smartstore.naver.com/products/123456",
                "seller_name": "펫샵",
                "is_primary": False,
            },
        ],
    },
    {
        "brand_name": "로얄캐닌",
        "product_name": "로얄캐닌 미니 어덜트",
        "size_label": "7.5kg",
        "species": PetSpecies.DOG,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_royal_mini_7.5kg",
                "url": "https://www.coupang.com/vp/products/123457",
                "affiliate_url": "https://www.coupang.com/vp/products/123457?affiliateId=test",
                "seller_name": "로얄캐닌 공식몰",
                "is_primary": True,
            },
        ],
    },
    {
        "brand_name": "힐스",
        "product_name": "힐스 사이언스 다이어트 어덜트",
        "size_label": "3kg",
        "species": PetSpecies.DOG,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_hills_adult_3kg",
                "url": "https://www.coupang.com/vp/products/123458",
                "affiliate_url": "https://www.coupang.com/vp/products/123458?affiliateId=test",
                "seller_name": "힐스 공식몰",
                "is_primary": True,
            },
            {
                "merchant": Merchant.NAVER,
                "merchant_product_id": "naver_hills_adult_3kg",
                "url": "https://smartstore.naver.com/products/123458",
                "seller_name": "펫마트",
                "is_primary": False,
            },
        ],
    },
    {
        "brand_name": "오리젠",
        "product_name": "오리젠 오리지널 독",
        "size_label": "2.27kg",
        "species": PetSpecies.DOG,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_orijen_original_2.27kg",
                "url": "https://www.coupang.com/vp/products/123459",
                "affiliate_url": "https://www.coupang.com/vp/products/123459?affiliateId=test",
                "seller_name": "오리젠 공식몰",
                "is_primary": True,
            },
        ],
    },
    {
        "brand_name": "아카나",
        "product_name": "아카나 그래스랜드 독",
        "size_label": "2kg",
        "species": PetSpecies.DOG,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_acana_grassland_2kg",
                "url": "https://www.coupang.com/vp/products/123460",
                "affiliate_url": "https://www.coupang.com/vp/products/123460?affiliateId=test",
                "seller_name": "아카나 공식몰",
                "is_primary": True,
            },
            {
                "merchant": Merchant.NAVER,
                "merchant_product_id": "naver_acana_grassland_2kg",
                "url": "https://smartstore.naver.com/products/123460",
                "seller_name": "프리미엄펫샵",
                "is_primary": False,
            },
        ],
    },
    {
        "brand_name": "퍼피",
        "product_name": "퍼피 강아지 사료",
        "size_label": "3kg",
        "species": PetSpecies.DOG,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_puppy_3kg",
                "url": "https://www.coupang.com/vp/products/123461",
                "affiliate_url": "https://www.coupang.com/vp/products/123461?affiliateId=test",
                "seller_name": "퍼피 공식몰",
                "is_primary": True,
            },
        ],
    },
    {
        "brand_name": "네츄럴밸런스",
        "product_name": "네츄럴밸런스 리미티드 인그리디언트 독",
        "size_label": "2.5kg",
        "species": PetSpecies.DOG,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_natural_balance_2.5kg",
                "url": "https://www.coupang.com/vp/products/123462",
                "affiliate_url": "https://www.coupang.com/vp/products/123462?affiliateId=test",
                "seller_name": "네츄럴밸런스 공식몰",
                "is_primary": True,
            },
        ],
    },
    # 고양이 사료
    {
        "brand_name": "로얄캐닌",
        "product_name": "로얄캐닌 인도어 어덜트",
        "size_label": "3.5kg",
        "species": PetSpecies.CAT,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_royal_indoor_3.5kg",
                "url": "https://www.coupang.com/vp/products/123463",
                "affiliate_url": "https://www.coupang.com/vp/products/123463?affiliateId=test",
                "seller_name": "로얄캐닌 공식몰",
                "is_primary": True,
            },
            {
                "merchant": Merchant.NAVER,
                "merchant_product_id": "naver_royal_indoor_3.5kg",
                "url": "https://smartstore.naver.com/products/123463",
                "seller_name": "펫샵",
                "is_primary": False,
            },
        ],
    },
    {
        "brand_name": "힐스",
        "product_name": "힐스 사이언스 다이어트 인도어 고양이",
        "size_label": "3.5kg",
        "species": PetSpecies.CAT,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_hills_indoor_3.5kg",
                "url": "https://www.coupang.com/vp/products/123464",
                "affiliate_url": "https://www.coupang.com/vp/products/123464?affiliateId=test",
                "seller_name": "힐스 공식몰",
                "is_primary": True,
            },
        ],
    },
    {
        "brand_name": "오리젠",
        "product_name": "오리젠 캐츠 앤 키틴 프리",
        "size_label": "2.27kg",
        "species": PetSpecies.CAT,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_orijen_cats_2.27kg",
                "url": "https://www.coupang.com/vp/products/123465",
                "affiliate_url": "https://www.coupang.com/vp/products/123465?affiliateId=test",
                "seller_name": "오리젠 공식몰",
                "is_primary": True,
            },
            {
                "merchant": Merchant.NAVER,
                "merchant_product_id": "naver_orijen_cats_2.27kg",
                "url": "https://smartstore.naver.com/products/123465",
                "seller_name": "프리미엄펫샵",
                "is_primary": False,
            },
        ],
    },
    {
        "brand_name": "아카나",
        "product_name": "아카나 그래스랜드 캣",
        "size_label": "2kg",
        "species": PetSpecies.CAT,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_acana_grassland_cat_2kg",
                "url": "https://www.coupang.com/vp/products/123466",
                "affiliate_url": "https://www.coupang.com/vp/products/123466?affiliateId=test",
                "seller_name": "아카나 공식몰",
                "is_primary": True,
            },
        ],
    },
    # 추가 강아지 사료
    {
        "brand_name": "퍼피",
        "product_name": "퍼피 강아지 사료",
        "size_label": "5kg",
        "species": PetSpecies.DOG,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_puppy_5kg",
                "url": "https://www.coupang.com/vp/products/123467",
                "affiliate_url": "https://www.coupang.com/vp/products/123467?affiliateId=test",
                "seller_name": "퍼피 공식몰",
                "is_primary": True,
            },
        ],
    },
    {
        "brand_name": "로얄캐닌",
        "product_name": "로얄캐닌 미니 퍼피",
        "size_label": "3kg",
        "species": PetSpecies.DOG,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_royal_puppy_3kg",
                "url": "https://www.coupang.com/vp/products/123468",
                "affiliate_url": "https://www.coupang.com/vp/products/123468?affiliateId=test",
                "seller_name": "로얄캐닌 공식몰",
                "is_primary": True,
            },
        ],
    },
    {
        "brand_name": "힐스",
        "product_name": "힐스 사이언스 다이어트 퍼피",
        "size_label": "3kg",
        "species": PetSpecies.DOG,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_hills_puppy_3kg",
                "url": "https://www.coupang.com/vp/products/123469",
                "affiliate_url": "https://www.coupang.com/vp/products/123469?affiliateId=test",
                "seller_name": "힐스 공식몰",
                "is_primary": True,
            },
        ],
    },
    {
        "brand_name": "오리젠",
        "product_name": "오리젠 퍼피 라지",
        "size_label": "5.4kg",
        "species": PetSpecies.DOG,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_orijen_puppy_large_5.4kg",
                "url": "https://www.coupang.com/vp/products/123470",
                "affiliate_url": "https://www.coupang.com/vp/products/123470?affiliateId=test",
                "seller_name": "오리젠 공식몰",
                "is_primary": True,
            },
        ],
    },
    {
        "brand_name": "아카나",
        "product_name": "아카나 퍼피 앤 주니어",
        "size_label": "2kg",
        "species": PetSpecies.DOG,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_acana_puppy_2kg",
                "url": "https://www.coupang.com/vp/products/123471",
                "affiliate_url": "https://www.coupang.com/vp/products/123471?affiliateId=test",
                "seller_name": "아카나 공식몰",
                "is_primary": True,
            },
        ],
    },
    {
        "brand_name": "로얄캐닌",
        "product_name": "로얄캐닌 미니 어덜트",
        "size_label": "10kg",
        "species": PetSpecies.DOG,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_royal_mini_10kg",
                "url": "https://www.coupang.com/vp/products/123472",
                "affiliate_url": "https://www.coupang.com/vp/products/123472?affiliateId=test",
                "seller_name": "로얄캐닌 공식몰",
                "is_primary": True,
            },
        ],
    },
    {
        "brand_name": "힐스",
        "product_name": "힐스 사이언스 다이어트 어덜트",
        "size_label": "7kg",
        "species": PetSpecies.DOG,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_hills_adult_7kg",
                "url": "https://www.coupang.com/vp/products/123473",
                "affiliate_url": "https://www.coupang.com/vp/products/123473?affiliateId=test",
                "seller_name": "힐스 공식몰",
                "is_primary": True,
            },
        ],
    },
    {
        "brand_name": "오리젠",
        "product_name": "오리젠 시니어 독",
        "size_label": "2.27kg",
        "species": PetSpecies.DOG,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_orijen_senior_2.27kg",
                "url": "https://www.coupang.com/vp/products/123474",
                "affiliate_url": "https://www.coupang.com/vp/products/123474?affiliateId=test",
                "seller_name": "오리젠 공식몰",
                "is_primary": True,
            },
        ],
    },
    {
        "brand_name": "아카나",
        "product_name": "아카나 시니어 독",
        "size_label": "2kg",
        "species": PetSpecies.DOG,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_acana_senior_2kg",
                "url": "https://www.coupang.com/vp/products/123475",
                "affiliate_url": "https://www.coupang.com/vp/products/123475?affiliateId=test",
                "seller_name": "아카나 공식몰",
                "is_primary": True,
            },
        ],
    },
    {
        "brand_name": "로얄캐닌",
        "product_name": "로얄캐닌 미니 라이트 웨이트 케어",
        "size_label": "3kg",
        "species": PetSpecies.DOG,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_royal_light_3kg",
                "url": "https://www.coupang.com/vp/products/123476",
                "affiliate_url": "https://www.coupang.com/vp/products/123476?affiliateId=test",
                "seller_name": "로얄캐닌 공식몰",
                "is_primary": True,
            },
        ],
    },
    {
        "brand_name": "힐스",
        "product_name": "힐스 사이언스 다이어트 퍼펙트 웨이트",
        "size_label": "3kg",
        "species": PetSpecies.DOG,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_hills_perfect_weight_3kg",
                "url": "https://www.coupang.com/vp/products/123477",
                "affiliate_url": "https://www.coupang.com/vp/products/123477?affiliateId=test",
                "seller_name": "힐스 공식몰",
                "is_primary": True,
            },
        ],
    },
    {
        "brand_name": "오리젠",
        "product_name": "오리젠 식이섬유",
        "size_label": "2.27kg",
        "species": PetSpecies.DOG,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_orijen_fiber_2.27kg",
                "url": "https://www.coupang.com/vp/products/123478",
                "affiliate_url": "https://www.coupang.com/vp/products/123478?affiliateId=test",
                "seller_name": "오리젠 공식몰",
                "is_primary": True,
            },
        ],
    },
    {
        "brand_name": "아카나",
        "product_name": "아카나 리미티드 인그리디언트 독",
        "size_label": "2kg",
        "species": PetSpecies.DOG,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_acana_limited_2kg",
                "url": "https://www.coupang.com/vp/products/123479",
                "affiliate_url": "https://www.coupang.com/vp/products/123479?affiliateId=test",
                "seller_name": "아카나 공식몰",
                "is_primary": True,
            },
        ],
    },
    {
        "brand_name": "네츄럴밸런스",
        "product_name": "네츄럴밸런스 리미티드 인그리디언트 독",
        "size_label": "5kg",
        "species": PetSpecies.DOG,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_natural_balance_5kg",
                "url": "https://www.coupang.com/vp/products/123480",
                "affiliate_url": "https://www.coupang.com/vp/products/123480?affiliateId=test",
                "seller_name": "네츄럴밸런스 공식몰",
                "is_primary": True,
            },
        ],
    },
    {
        "brand_name": "퍼피",
        "product_name": "퍼피 강아지 사료",
        "size_label": "10kg",
        "species": PetSpecies.DOG,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_puppy_10kg",
                "url": "https://www.coupang.com/vp/products/123481",
                "affiliate_url": "https://www.coupang.com/vp/products/123481?affiliateId=test",
                "seller_name": "퍼피 공식몰",
                "is_primary": True,
            },
        ],
    },
    # 추가 고양이 사료
    {
        "brand_name": "로얄캐닌",
        "product_name": "로얄캐닌 인도어 어덜트",
        "size_label": "7kg",
        "species": PetSpecies.CAT,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_royal_indoor_7kg",
                "url": "https://www.coupang.com/vp/products/123482",
                "affiliate_url": "https://www.coupang.com/vp/products/123482?affiliateId=test",
                "seller_name": "로얄캐닌 공식몰",
                "is_primary": True,
            },
        ],
    },
    {
        "brand_name": "힐스",
        "product_name": "힐스 사이언스 다이어트 인도어 고양이",
        "size_label": "7kg",
        "species": PetSpecies.CAT,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_hills_indoor_7kg",
                "url": "https://www.coupang.com/vp/products/123483",
                "affiliate_url": "https://www.coupang.com/vp/products/123483?affiliateId=test",
                "seller_name": "힐스 공식몰",
                "is_primary": True,
            },
        ],
    },
    {
        "brand_name": "오리젠",
        "product_name": "오리젠 캐츠 앤 키틴 프리",
        "size_label": "5.4kg",
        "species": PetSpecies.CAT,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_orijen_cats_5.4kg",
                "url": "https://www.coupang.com/vp/products/123484",
                "affiliate_url": "https://www.coupang.com/vp/products/123484?affiliateId=test",
                "seller_name": "오리젠 공식몰",
                "is_primary": True,
            },
        ],
    },
    {
        "brand_name": "아카나",
        "product_name": "아카나 그래스랜드 캣",
        "size_label": "5.4kg",
        "species": PetSpecies.CAT,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_acana_grassland_cat_5.4kg",
                "url": "https://www.coupang.com/vp/products/123485",
                "affiliate_url": "https://www.coupang.com/vp/products/123485?affiliateId=test",
                "seller_name": "아카나 공식몰",
                "is_primary": True,
            },
        ],
    },
    {
        "brand_name": "로얄캐닌",
        "product_name": "로얄캐닌 키튼",
        "size_label": "3.5kg",
        "species": PetSpecies.CAT,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_royal_kitten_3.5kg",
                "url": "https://www.coupang.com/vp/products/123486",
                "affiliate_url": "https://www.coupang.com/vp/products/123486?affiliateId=test",
                "seller_name": "로얄캐닌 공식몰",
                "is_primary": True,
            },
        ],
    },
    {
        "brand_name": "힐스",
        "product_name": "힐스 사이언스 다이어트 키튼",
        "size_label": "3.5kg",
        "species": PetSpecies.CAT,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_hills_kitten_3.5kg",
                "url": "https://www.coupang.com/vp/products/123487",
                "affiliate_url": "https://www.coupang.com/vp/products/123487?affiliateId=test",
                "seller_name": "힐스 공식몰",
                "is_primary": True,
            },
        ],
    },
    {
        "brand_name": "오리젠",
        "product_name": "오리젠 키튼 앤 주니어",
        "size_label": "2.27kg",
        "species": PetSpecies.CAT,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_orijen_kitten_2.27kg",
                "url": "https://www.coupang.com/vp/products/123488",
                "affiliate_url": "https://www.coupang.com/vp/products/123488?affiliateId=test",
                "seller_name": "오리젠 공식몰",
                "is_primary": True,
            },
        ],
    },
    {
        "brand_name": "로얄캐닌",
        "product_name": "로얄캐닌 시니어",
        "size_label": "3.5kg",
        "species": PetSpecies.CAT,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_royal_senior_cat_3.5kg",
                "url": "https://www.coupang.com/vp/products/123489",
                "affiliate_url": "https://www.coupang.com/vp/products/123489?affiliateId=test",
                "seller_name": "로얄캐닌 공식몰",
                "is_primary": True,
            },
        ],
    },
    {
        "brand_name": "힐스",
        "product_name": "힐스 사이언스 다이어트 시니어 11+",
        "size_label": "3.5kg",
        "species": PetSpecies.CAT,
        "offers": [
            {
                "merchant": Merchant.COUPANG,
                "merchant_product_id": "coupang_hills_senior_3.5kg",
                "url": "https://www.coupang.com/vp/products/123490",
                "affiliate_url": "https://www.coupang.com/vp/products/123490?affiliateId=test",
                "seller_name": "힐스 공식몰",
                "is_primary": True,
            },
        ],
    },
]


async def seed_products():
    """사료 테스트 데이터 생성 (상품, 알레르겐, 성분, 영양 정보 포함)"""
    # DB 연결
    engine = create_async_engine(
        settings.DATABASE_URL,
        echo=True,
    )
    
    async_session = async_sessionmaker(
        engine,
        class_=AsyncSession,
        expire_on_commit=False,
    )
    
    async with async_session() as session:
        try:
            # 먼저 알레르겐 코드가 있는지 확인하고 없으면 생성
            allergen_codes = [
                ('BEEF', '소고기'),
                ('CHICKEN', '닭고기'),
                ('PORK', '돼지고기'),
                ('DUCK', '오리고기'),
                ('LAMB', '양고기'),
                ('FISH', '생선'),
                ('EGG', '계란'),
                ('DAIRY', '유제품'),
                ('WHEAT', '밀/글루텐'),
                ('CORN', '옥수수'),
                ('SOY', '콩'),
            ]
            
            for code, display_name in allergen_codes:
                result = await session.execute(
                    text("SELECT 1 FROM allergen_codes WHERE code = :code"),
                    {"code": code}
                )
                if result.scalar_one_or_none() is None:
                    await session.execute(
                        text("""
                            INSERT INTO allergen_codes (code, display_name)
                            VALUES (:code, :display_name)
                            ON CONFLICT (code) DO NOTHING
                        """),
                        {"code": code, "display_name": display_name}
                    )
                    print(f"✓ 알레르겐 코드 생성: {code} - {display_name}")
            
            await session.commit()
            
            created_count = 0
            allergen_count = 0
            nutrition_count = 0
            ingredient_count = 0
            claim_count = 0
            
            for product_data in TEST_PRODUCTS:
                brand_name = product_data["brand_name"]
                product_name = product_data["product_name"]
                species = product_data["species"]
                
                # 상품 생성
                product = Product(
                    category="FOOD",  # MVP는 FOOD만
                    brand_name=brand_name,
                    product_name=product_name,
                    size_label=product_data["size_label"],
                    species=species,
                    is_active=True,
                )
                session.add(product)
                await session.flush()  # ID 생성
                
                # 판매처 생성
                for offer_data in product_data["offers"]:
                    offer = ProductOffer(
                        product_id=product.id,
                        merchant=offer_data["merchant"],
                        merchant_product_id=offer_data["merchant_product_id"],
                        url=offer_data["url"],
                        affiliate_url=offer_data.get("affiliate_url"),
                        seller_name=offer_data.get("seller_name"),
                        is_primary=offer_data.get("is_primary", False),
                        is_active=True,
                    )
                    session.add(offer)
                
                # 알레르겐 정보 생성
                allergens = _get_default_allergens(brand_name, product_name)
                for allergen_code in allergens:
                    allergen = ProductAllergen(
                        product_id=product.id,
                        allergen_code=allergen_code,
                        confidence=85,  # 기본 신뢰도
                        source="테스트 데이터",
                    )
                    session.add(allergen)
                    allergen_count += 1
                
                # 성분 프로필 생성
                ingredient_profile_data = _get_default_ingredients(brand_name, product_name, species)
                ingredient_profile = ProductIngredientProfile(
                    product_id=product.id,
                    ingredients_text=ingredient_profile_data["ingredients_text"],
                    additives_text=ingredient_profile_data["additives_text"],
                    parsed=None,  # 파싱 결과는 나중에 추가
                    source=ingredient_profile_data["source"],
                )
                session.add(ingredient_profile)
                ingredient_count += 1
                
                # 영양 정보 생성
                nutrition_data = _get_default_nutrition(brand_name, product_name, species)
                nutrition_facts = ProductNutritionFacts(
                    product_id=product.id,
                    protein_pct=nutrition_data["protein_pct"],
                    fat_pct=nutrition_data["fat_pct"],
                    fiber_pct=nutrition_data["fiber_pct"],
                    moisture_pct=nutrition_data["moisture_pct"],
                    ash_pct=nutrition_data["ash_pct"],
                    kcal_per_100g=nutrition_data["kcal_per_100g"],
                    calcium_pct=nutrition_data["calcium_pct"],
                    phosphorus_pct=nutrition_data["phosphorus_pct"],
                    aafco_statement=nutrition_data["aafco_statement"],
                )
                session.add(nutrition_facts)
                nutrition_count += 1
                
                # 기능성 클레임 생성
                claims = _get_default_claims(brand_name, product_name, species)
                for claim_code in claims:
                    # claim_code가 존재하는지 확인
                    result = await session.execute(
                        text("SELECT 1 FROM claim_codes WHERE code = :code"),
                        {"code": claim_code}
                    )
                    if result.scalar_one_or_none() is None:
                        # claim_code가 없으면 생성
                        await session.execute(
                            text("""
                                INSERT INTO claim_codes (code, display_name)
                                VALUES (:code, :display_name)
                                ON CONFLICT (code) DO NOTHING
                            """),
                            {"code": claim_code, "display_name": _get_claim_display_name(claim_code)}
                        )
                    
                    claim = ProductClaim(
                        product_id=product.id,
                        claim_code=claim_code,
                        evidence_level=70,
                        note="테스트 데이터",
                    )
                    session.add(claim)
                    claim_count += 1
                
                created_count += 1
                print(f"✓ 생성됨: {product.brand_name} {product.product_name} {product.size_label}")
            
            await session.commit()
            print(f"\n총 {created_count}개의 상품이 생성되었습니다.")
            print(f"  - 판매처: {created_count * 2}개 (평균)")
            print(f"  - 알레르겐 정보: {allergen_count}개")
            print(f"  - 성분 프로필: {ingredient_count}개")
            print(f"  - 영양 정보: {nutrition_count}개")
            print(f"  - 기능성 클레임: {claim_count}개")
            
        except Exception as e:
            await session.rollback()
            print(f"❌ 오류 발생: {e}")
            import traceback
            traceback.print_exc()
            raise
        finally:
            await engine.dispose()


def _get_claim_display_name(code: str) -> str:
    """클레임 코드의 표시명 반환"""
    claim_names = {
        "DIGESTIVE": "장/소화 건강",
        "DENTAL": "치아/구강 건강",
        "SKIN": "피부/털 건강",
        "JOINT": "관절 건강",
        "WEIGHT": "체중 관리",
        "URINARY": "요로 건강",
        "SENIOR": "노령 관리",
        "PUPPY": "퍼피 성장",
        "IMMUNE": "면역력 강화",
        "COAT": "털 관리",
    }
    return claim_names.get(code, code)


if __name__ == "__main__":
    asyncio.run(seed_products())
