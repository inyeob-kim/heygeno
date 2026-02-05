"""관리자 API 라우터 - 상품 관리"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID

from app.db.session import get_db
from app.schemas.product import ProductRead, ProductCreate, ProductUpdate
from app.schemas.admin import (
    IngredientProfileRead, IngredientProfileCreate, IngredientProfileUpdate,
    NutritionFactsRead, NutritionFactsCreate, NutritionFactsUpdate,
    AllergenCodeRead, ProductAllergenRead, ProductAllergenCreate, ProductAllergenUpdate,
    ClaimCodeRead, ProductClaimRead, ProductClaimCreate, ProductClaimUpdate
)
from app.services.product_service import ProductService
from app.services.admin_service import AdminService

router = APIRouter()


@router.get("/products", response_model=list[ProductRead])
async def get_all_products(
    include_inactive: bool = Query(default=False, description="비활성 상품 포함 여부"),
    db: AsyncSession = Depends(get_db)
):
    """모든 상품 목록 조회 (관리자용)"""
    products = await ProductService.get_all_products(db, include_inactive=include_inactive)
    return [ProductRead.model_validate(p) for p in products]


@router.get("/products/{product_id}", response_model=ProductRead)
async def get_product(
    product_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """상품 상세 조회 (관리자용)"""
    product = await ProductService.get_product_by_id(product_id, db)
    return ProductRead.model_validate(product)


@router.post("/products", response_model=ProductRead, status_code=status.HTTP_201_CREATED)
async def create_product(
    product_data: ProductCreate,
    db: AsyncSession = Depends(get_db)
):
    """상품 생성"""
    product = await ProductService.create_product(product_data, db)
    return ProductRead.model_validate(product)


@router.put("/products/{product_id}", response_model=ProductRead)
async def update_product(
    product_id: UUID,
    product_data: ProductUpdate,
    db: AsyncSession = Depends(get_db)
):
    """상품 수정"""
    product = await ProductService.update_product(product_id, product_data, db)
    return ProductRead.model_validate(product)


@router.delete("/products/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_product(
    product_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """상품 삭제 (소프트 삭제)"""
    await ProductService.delete_product(product_id, db)
    return None


# ========== 성분 정보 ==========
@router.get("/products/{product_id}/ingredient", response_model=IngredientProfileRead | None)
async def get_ingredient_profile(
    product_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """성분 정보 조회"""
    profile = await AdminService.get_ingredient_profile(product_id, db)
    if profile is None:
        return None
    return IngredientProfileRead.model_validate(profile)


@router.put("/products/{product_id}/ingredient", response_model=IngredientProfileRead)
async def update_ingredient_profile(
    product_id: UUID,
    data: IngredientProfileUpdate,
    db: AsyncSession = Depends(get_db)
):
    """성분 정보 생성 또는 수정"""
    profile = await AdminService.create_or_update_ingredient_profile(product_id, data, db)
    return IngredientProfileRead.model_validate(profile)


# ========== 영양 정보 ==========
@router.get("/products/{product_id}/nutrition", response_model=NutritionFactsRead | None)
async def get_nutrition_facts(
    product_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """영양 정보 조회"""
    facts = await AdminService.get_nutrition_facts(product_id, db)
    if facts is None:
        return None
    return NutritionFactsRead.model_validate(facts)


@router.put("/products/{product_id}/nutrition", response_model=NutritionFactsRead)
async def update_nutrition_facts(
    product_id: UUID,
    data: NutritionFactsUpdate,
    db: AsyncSession = Depends(get_db)
):
    """영양 정보 생성 또는 수정"""
    facts = await AdminService.create_or_update_nutrition_facts(product_id, data, db)
    return NutritionFactsRead.model_validate(facts)


# ========== 알레르겐 ==========
@router.get("/allergen-codes", response_model=list[AllergenCodeRead])
async def get_allergen_codes(db: AsyncSession = Depends(get_db)):
    """알레르겐 코드 목록 조회"""
    codes = await AdminService.get_allergen_codes(db)
    return [AllergenCodeRead.model_validate(c) for c in codes]


@router.get("/products/{product_id}/allergens", response_model=list[ProductAllergenRead])
async def get_product_allergens(
    product_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """상품 알레르겐 목록 조회"""
    allergens = await AdminService.get_product_allergens(product_id, db)
    result = []
    for allergen in allergens:
        # 알레르겐 코드 정보 조회
        from sqlalchemy import select
        from app.models.product import AllergenCode
        code_result = await db.execute(
            select(AllergenCode).where(AllergenCode.code == allergen.allergen_code)
        )
        allergen_code = code_result.scalar_one_or_none()
        
        allergen_dict = {
            "product_id": allergen.product_id,
            "allergen_code": allergen.allergen_code,
            "allergen_display_name": allergen_code.display_name if allergen_code else None,
            "confidence": allergen.confidence,
            "source": allergen.source
        }
        result.append(ProductAllergenRead(**allergen_dict))
    
    return result


@router.post("/products/{product_id}/allergens", response_model=ProductAllergenRead, status_code=status.HTTP_201_CREATED)
async def add_product_allergen(
    product_id: UUID,
    data: ProductAllergenCreate,
    db: AsyncSession = Depends(get_db)
):
    """상품 알레르겐 추가"""
    allergen = await AdminService.add_product_allergen(product_id, data, db)
    
    # 알레르겐 코드 정보 조회
    from sqlalchemy import select
    from app.models.product import AllergenCode
    code_result = await db.execute(
        select(AllergenCode).where(AllergenCode.code == allergen.allergen_code)
    )
    allergen_code = code_result.scalar_one_or_none()
    
    return ProductAllergenRead(
        product_id=allergen.product_id,
        allergen_code=allergen.allergen_code,
        allergen_display_name=allergen_code.display_name if allergen_code else None,
        confidence=allergen.confidence,
        source=allergen.source
    )


@router.put("/products/{product_id}/allergens/{allergen_code}", response_model=ProductAllergenRead)
async def update_product_allergen(
    product_id: UUID,
    allergen_code: str,
    data: ProductAllergenUpdate,
    db: AsyncSession = Depends(get_db)
):
    """상품 알레르겐 수정"""
    allergen = await AdminService.update_product_allergen(product_id, allergen_code, data, db)
    
    # 알레르겐 코드 정보 조회
    from sqlalchemy import select
    from app.models.product import AllergenCode
    code_result = await db.execute(
        select(AllergenCode).where(AllergenCode.code == allergen.allergen_code)
    )
    allergen_code_obj = code_result.scalar_one_or_none()
    
    return ProductAllergenRead(
        product_id=allergen.product_id,
        allergen_code=allergen.allergen_code,
        allergen_display_name=allergen_code_obj.display_name if allergen_code_obj else None,
        confidence=allergen.confidence,
        source=allergen.source
    )


@router.delete("/products/{product_id}/allergens/{allergen_code}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_product_allergen(
    product_id: UUID,
    allergen_code: str,
    db: AsyncSession = Depends(get_db)
):
    """상품 알레르겐 삭제"""
    await AdminService.delete_product_allergen(product_id, allergen_code, db)
    return None


# ========== 클레임 ==========
@router.get("/claim-codes", response_model=list[ClaimCodeRead])
async def get_claim_codes(db: AsyncSession = Depends(get_db)):
    """클레임 코드 목록 조회"""
    codes = await AdminService.get_claim_codes(db)
    return [ClaimCodeRead.model_validate(c) for c in codes]


@router.get("/products/{product_id}/claims", response_model=list[ProductClaimRead])
async def get_product_claims(
    product_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """상품 클레임 목록 조회"""
    claims = await AdminService.get_product_claims(product_id, db)
    result = []
    for claim in claims:
        # 클레임 코드 정보 조회
        from sqlalchemy import select
        from app.models.product import ClaimCode
        code_result = await db.execute(
            select(ClaimCode).where(ClaimCode.code == claim.claim_code)
        )
        claim_code = code_result.scalar_one_or_none()
        
        claim_dict = {
            "product_id": claim.product_id,
            "claim_code": claim.claim_code,
            "claim_display_name": claim_code.display_name if claim_code else None,
            "evidence_level": claim.evidence_level,
            "note": claim.note
        }
        result.append(ProductClaimRead(**claim_dict))
    
    return result


@router.post("/products/{product_id}/claims", response_model=ProductClaimRead, status_code=status.HTTP_201_CREATED)
async def add_product_claim(
    product_id: UUID,
    data: ProductClaimCreate,
    db: AsyncSession = Depends(get_db)
):
    """상품 클레임 추가"""
    claim = await AdminService.add_product_claim(product_id, data, db)
    
    # 클레임 코드 정보 조회
    from sqlalchemy import select
    from app.models.product import ClaimCode
    code_result = await db.execute(
        select(ClaimCode).where(ClaimCode.code == claim.claim_code)
    )
    claim_code = code_result.scalar_one_or_none()
    
    return ProductClaimRead(
        product_id=claim.product_id,
        claim_code=claim.claim_code,
        claim_display_name=claim_code.display_name if claim_code else None,
        evidence_level=claim.evidence_level,
        note=claim.note
    )


@router.put("/products/{product_id}/claims/{claim_code}", response_model=ProductClaimRead)
async def update_product_claim(
    product_id: UUID,
    claim_code: str,
    data: ProductClaimUpdate,
    db: AsyncSession = Depends(get_db)
):
    """상품 클레임 수정"""
    claim = await AdminService.update_product_claim(product_id, claim_code, data, db)
    
    # 클레임 코드 정보 조회
    from sqlalchemy import select
    from app.models.product import ClaimCode
    code_result = await db.execute(
        select(ClaimCode).where(ClaimCode.code == claim.claim_code)
    )
    claim_code_obj = code_result.scalar_one_or_none()
    
    return ProductClaimRead(
        product_id=claim.product_id,
        claim_code=claim.claim_code,
        claim_display_name=claim_code_obj.display_name if claim_code_obj else None,
        evidence_level=claim.evidence_level,
        note=claim.note
    )


@router.delete("/products/{product_id}/claims/{claim_code}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_product_claim(
    product_id: UUID,
    claim_code: str,
    db: AsyncSession = Depends(get_db)
):
    """상품 클레임 삭제"""
    await AdminService.delete_product_claim(product_id, claim_code, db)
    return None
