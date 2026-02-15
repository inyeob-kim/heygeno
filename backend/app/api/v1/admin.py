"""관리자 API 라우터 - 상품 관리"""
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID
import logging
from pydantic import BaseModel
from datetime import datetime, timezone

from app.db.session import get_db
from app.schemas.product import ProductRead, ProductCreate, ProductUpdate
from app.schemas.admin import (
    IngredientProfileRead, IngredientProfileCreate, IngredientProfileUpdate,
    NutritionFactsRead, NutritionFactsCreate, NutritionFactsUpdate,
    AllergenCodeRead, ProductAllergenRead, ProductAllergenCreate, ProductAllergenUpdate,
    ClaimCodeRead, ProductClaimRead, ProductClaimCreate, ProductClaimUpdate,
    ProductListRead, ProductListResponse, ProductImagesUpdate,
    OfferRead, OfferCreate, OfferUpdate
)
from app.schemas.campaign import (
    CampaignRead, CampaignCreate, CampaignUpdate,
    CampaignToggleRequest, CampaignSimulateRequest, CampaignSimulateResponse,
    RewardRead, ImpressionRead
)
from app.services.product_service import ProductService
from app.services.admin_service import AdminService
from app.services.campaign_service import CampaignService
from app.services.ingredient_ai_service import analyze_ingredients_with_ai

logger = logging.getLogger(__name__)
router = APIRouter()


@router.get("/products", response_model=ProductListResponse)
async def get_all_products(
    query: Optional[str] = Query(None, description="검색어 (브랜드명/상품명/용량)"),
    species: Optional[str] = Query(None, description="반려동물 종류 (DOG/CAT/ALL)"),
    active: Optional[str] = Query(None, description="활성 상태 (ACTIVE/ARCHIVED/ALL)"),
    completion_status: Optional[str] = Query(None, description="완성도 상태"),
    has_image: Optional[str] = Query(None, description="이미지 여부 (YES/NO/ALL)"),
    has_offers: Optional[str] = Query(None, description="판매처 여부 (YES/NO/ALL)"),
    sort: str = Query("UPDATED_DESC", description="정렬 (UPDATED_DESC/BRAND_ASC/INCOMPLETE_FIRST)"),
    page: int = Query(1, ge=1, description="페이지 번호"),
    size: int = Query(30, ge=1, le=100, description="페이지 크기"),
    db: AsyncSession = Depends(get_db)
):
    """상품 목록 조회 (필터링/정렬/페이지네이션)"""
    try:
        products, total = await ProductService.get_products_with_filters(
            db=db,
            query=query,
            species=species,
            active=active,
            completion_status=completion_status,
            has_image=has_image,
            has_offers=has_offers,
            sort=sort,
            page=page,
            size=size
        )
        
        # Computed fields 계산
        items = []
        for p in products:
            try:
                # offers_count
                offers_count = len(p.offers) if p.offers else 0
                
                # ingredient_exists, nutrition_exists
                ingredient_exists = p.ingredient_profile is not None
                nutrition_exists = p.nutrition_facts is not None
                
                # has_image
                has_image_flag = bool(getattr(p, 'primary_image_url', None) or getattr(p, 'thumbnail_url', None))
                
                # completion_status (마이그레이션 후 사용 가능)
                completion_status_value = getattr(p, 'completion_status', None)
                
                # last_admin_updated_at (마이그레이션 후 사용 가능)
                last_admin_updated_at = getattr(p, 'last_admin_updated_at', None)
                
                item = ProductListRead(
                    id=p.id,
                    brand_name=p.brand_name,
                    product_name=p.product_name,
                    size_label=p.size_label,
                    is_active=p.is_active,
                    category=p.category,
                    species=p.species.value if p.species else None,
                    primary_image_url=getattr(p, 'primary_image_url', None),
                    thumbnail_url=getattr(p, 'thumbnail_url', None),
                    admin_memo=getattr(p, 'admin_memo', None),
                    completion_status=completion_status_value,
                    last_admin_updated_at=last_admin_updated_at,
                    offers_count=offers_count,
                    ingredient_exists=ingredient_exists,
                    nutrition_exists=nutrition_exists,
                    has_image=has_image_flag
                )
                items.append(item)
            except Exception as e:
                logger.error(f"Error processing product {p.id}: {str(e)}", exc_info=True)
                # 개별 상품 처리 실패 시 스킵하고 계속 진행
                continue
        
        return ProductListResponse(items=items, total=total, page=page, size=size)
    except Exception as e:
        logger.error(f"Error in get_all_products: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"상품 목록을 불러오는데 실패했습니다: {str(e)}"
        )


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


@router.post("/products/{product_id}/archive", response_model=ProductRead)
async def archive_product(
    product_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """상품 비활성화 (Archive)"""
    product = await ProductService.update_product(
        product_id,
        ProductUpdate(is_active=False),
        db
    )
    return ProductRead.model_validate(product)


@router.post("/products/{product_id}/unarchive", response_model=ProductRead)
async def unarchive_product(
    product_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """상품 복구 (Unarchive)"""
    product = await ProductService.update_product(
        product_id,
        ProductUpdate(is_active=True),
        db
    )
    return ProductRead.model_validate(product)


# ========== 이미지 관리 ==========
@router.get("/products/{product_id}/images", response_model=list[str])
async def get_product_images(
    product_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """상품 이미지 목록 조회"""
    return await AdminService.get_product_images(product_id, db)


@router.patch("/products/{product_id}/images", response_model=ProductRead)
async def update_product_images(
    product_id: UUID,
    data: ProductImagesUpdate,
    db: AsyncSession = Depends(get_db)
):
    """상품 이미지 업데이트"""
    product = await AdminService.update_product_images(product_id, data, db)
    return ProductRead.model_validate(product)


# ========== 판매처 관리 ==========
@router.get("/products/{product_id}/offers", response_model=list[OfferRead])
async def get_product_offers(
    product_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """상품 판매처 목록 조회"""
    offers = await AdminService.get_product_offers(product_id, db)
    return [OfferRead.model_validate(o) for o in offers]


@router.post("/products/{product_id}/offers", response_model=OfferRead, status_code=status.HTTP_201_CREATED)
async def create_offer(
    product_id: UUID,
    data: OfferCreate,
    db: AsyncSession = Depends(get_db)
):
    """판매처 생성"""
    offer = await AdminService.create_offer(product_id, data, db)
    return OfferRead.model_validate(offer)


@router.put("/offers/{offer_id}", response_model=OfferRead)
async def update_offer(
    offer_id: UUID,
    data: OfferUpdate,
    db: AsyncSession = Depends(get_db)
):
    """판매처 수정"""
    offer = await AdminService.update_offer(offer_id, data, db)
    return OfferRead.model_validate(offer)


@router.delete("/offers/{offer_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_offer(
    offer_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """판매처 삭제"""
    await AdminService.delete_offer(offer_id, db)
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
    try:
        allergens = await AdminService.get_product_allergens(product_id, db)
        result = []
        for allergen in allergens:
            try:
                # 알레르겐 코드 정보 조회
                from sqlalchemy import select
                from app.models.pet import AllergenCode
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
            except Exception as e:
                logger.error(f"Error processing allergen {allergen.allergen_code}: {str(e)}", exc_info=True)
                # 개별 알레르겐 처리 실패 시 스킵하고 계속 진행
                continue
        
        return result
    except Exception as e:
        logger.error(f"Error in get_product_allergens: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"알레르겐 정보를 불러오는데 실패했습니다: {str(e)}"
        )


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
    from app.models.pet import AllergenCode
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
    from app.models.pet import AllergenCode
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


# ========== AI 성분 분석 ==========
class AnalyzeIngredientsRequest(BaseModel):
    """성분 분석 요청"""
    ingredients_text: str
    additives_text: Optional[str] = ""
    species: Optional[str] = None


class AnalyzeIngredientsResponse(BaseModel):
    """성분 분석 응답"""
    parsed: dict


@router.post("/analyze-ingredients", response_model=AnalyzeIngredientsResponse)
async def analyze_ingredients(req: AnalyzeIngredientsRequest):
    """
    OpenAI를 사용하여 성분 텍스트를 분석하고 구조화된 JSON 반환
    
    주의: 이 엔드포인트는 DB에 저장하지 않고 분석 결과만 반환합니다.
    분석 결과를 저장하려면 /products/{product_id}/ingredient/parsed 엔드포인트를 사용하세요.
    """
    try:
        parsed = await analyze_ingredients_with_ai(
            ingredients_text=req.ingredients_text,
            additives_text=req.additives_text or "",
            species=req.species
        )
        return AnalyzeIngredientsResponse(parsed=parsed)
    except ValueError as e:
        logger.error(f"성분 분석 실패: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"성분 분석 중 예상치 못한 오류: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"성분 분석 중 오류가 발생했습니다: {str(e)}"
        )


class SaveParsedRequest(BaseModel):
    """parsed JSON 저장 요청"""
    parsed: dict


@router.put("/products/{product_id}/ingredient/parsed")
async def save_parsed(
    product_id: UUID,
    req: SaveParsedRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    분석된 parsed JSON을 DB에 저장
    
    주의: 이 엔드포인트는 parsed 필드만 업데이트합니다.
    ingredients_text나 additives_text를 업데이트하려면 /products/{product_id}/ingredient 엔드포인트를 사용하세요.
    """
    try:
        # 기존 성분 정보 조회
        profile = await AdminService.get_ingredient_profile(product_id, db)
        
        if not profile:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="성분 정보가 등록되지 않은 상품입니다. 먼저 성분 정보를 등록하세요."
            )
        
        # parsed 필드만 업데이트
        profile.parsed = req.parsed
        profile.version += 1
        from datetime import datetime
        profile.updated_at = datetime.now()
        
        await AdminService._commit_or_rollback(db, "Failed to save parsed data")
        await db.refresh(profile)
        
        return {"ok": True, "message": "parsed 데이터가 저장되었습니다."}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"parsed 저장 실패: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"parsed 데이터 저장 중 오류가 발생했습니다: {str(e)}"
        )


@router.post("/products/{product_id}/ingredient/analyze-and-save", response_model=IngredientProfileRead)
async def analyze_and_save_ingredients(
    product_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """
    AI를 사용하여 성분 텍스트를 분석하고 parsed 컬럼에 저장
    
    1. product_id로 성분 정보 조회
    2. ingredients_text가 없으면 에러
    3. AI 분석 수행
    4. parsed 컬럼에 저장
    5. version 증가
    
    Returns:
        업데이트된 IngredientProfileRead
    """
    try:
        # 1. 성분 정보 조회
        profile = await AdminService.get_ingredient_profile(product_id, db)
        if not profile:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="성분 정보가 등록되지 않은 상품입니다. 먼저 성분 정보를 등록하세요."
            )
        
        if not profile.ingredients_text or not profile.ingredients_text.strip():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="원재료 텍스트가 없습니다. 먼저 성분 정보를 입력하세요."
            )
        
        # 2. Product에서 species 가져오기
        from sqlalchemy import select
        from app.models.product import Product
        product_result = await db.execute(
            select(Product).where(Product.id == product_id)
        )
        product = product_result.scalar_one_or_none()
        
        if product is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="상품을 찾을 수 없습니다."
            )
        
        species = product.species.value if product.species else None
        
        # 3. AI 분석 수행
        logger.info(f"AI 성분 분석 시작: product_id={product_id}, species={species}")
        try:
            parsed = await analyze_ingredients_with_ai(
                ingredients_text=profile.ingredients_text,
                additives_text=profile.additives_text or "",
                species=species
            )
            logger.info(f"AI 성분 분석 완료: product_id={product_id}")
        except ValueError as e:
            logger.error(f"AI 분석 실패: {str(e)}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"AI 분석 실패: {str(e)}"
            )
        
        # 4. parsed 저장
        profile.parsed = parsed
        profile.version += 1
        from datetime import datetime
        profile.updated_at = datetime.now()
        
        await AdminService._commit_or_rollback(db, "Failed to save parsed data")
        await db.refresh(profile)
        
        logger.info(f"parsed 데이터 저장 완료: product_id={product_id}, version={profile.version}")
        return IngredientProfileRead.model_validate(profile)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"analyze-and-save 실패: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"성분 분석 및 저장 중 오류가 발생했습니다: {str(e)}"
        )


# ========== Campaign 관리 ==========
@router.get("/campaigns", response_model=list[CampaignRead])
async def get_campaigns(
    key: Optional[str] = Query(None, description="키 검색"),
    kind: Optional[str] = Query(None, description="종류 (EVENT/NOTICE/AD)"),
    placement: Optional[str] = Query(None, description="노출 위치"),
    template: Optional[str] = Query(None, description="템플릿"),
    enabled: Optional[bool] = Query(None, description="활성화 여부"),
    db: AsyncSession = Depends(get_db)
):
    """캠페인 목록 조회 (필터링)"""
    try:
        campaigns = await CampaignService.get_campaigns(
            db=db,
            key=key,
            kind=kind,
            placement=placement,
            template=template,
            enabled=enabled
        )
        
        now = datetime.now(timezone.utc)
        result = []
        for campaign in campaigns:
            try:
                # CampaignRead 스키마에 맞게 변환
                campaign_dict = {
                    "id": campaign.id,  # UUID 객체 그대로 (Pydantic이 자동 변환)
                    "key": campaign.key,
                    "kind": campaign.kind,
                    "placement": campaign.placement,
                    "template": campaign.template,
                    "priority": campaign.priority,
                    "is_enabled": campaign.is_enabled,
                    "start_at": campaign.start_at,  # datetime 객체 그대로
                    "end_at": campaign.end_at,  # datetime 객체 그대로
                    "content": campaign.content or {},
                    "rules": [rule.rule for rule in (campaign.rules or [])],
                    "actions": [
                        {
                            "trigger": action.trigger,
                            "action_type": action.action_type,
                            "action": action.action
                        }
                        for action in (campaign.actions or [])
                    ],
                    "status": CampaignService._calculate_status(campaign, now),
                    "created_at": campaign.created_at,  # datetime 객체 그대로
                    "updated_at": campaign.updated_at  # datetime 객체 그대로
                }
                result.append(campaign_dict)
            except Exception as e:
                logger.error(f"캠페인 변환 실패: campaign_id={campaign.id}, error={str(e)}", exc_info=True)
                continue
        
        return result
    except Exception as e:
        logger.error(f"캠페인 목록 조회 실패: error={str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"캠페인 목록 조회 중 오류가 발생했습니다: {str(e)}"
        )


@router.get("/campaigns/{campaign_id}", response_model=CampaignRead)
async def get_campaign(
    campaign_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """캠페인 상세 조회"""
    campaign = await CampaignService.get_campaign_by_id(db, campaign_id)
    if not campaign:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="캠페인을 찾을 수 없습니다"
        )
    
    now = datetime.utcnow()
    return {
        "id": campaign.id,
        "key": campaign.key,
        "kind": campaign.kind,
        "placement": campaign.placement,
        "template": campaign.template,
        "priority": campaign.priority,
        "is_enabled": campaign.is_enabled,
        "start_at": campaign.start_at,
        "end_at": campaign.end_at,
        "content": campaign.content,
        "rules": [rule.rule for rule in campaign.rules],
        "actions": [
            {
                "trigger": action.trigger,
                "action_type": action.action_type,
                "action": action.action
            }
            for action in campaign.actions
        ],
        "status": CampaignService._calculate_status(campaign, now),
        "created_at": campaign.created_at,
        "updated_at": campaign.updated_at
    }


@router.post("/campaigns", response_model=CampaignRead, status_code=status.HTTP_201_CREATED)
async def create_campaign(
    data: CampaignCreate,
    db: AsyncSession = Depends(get_db)
):
    """캠페인 생성"""
    campaign = await CampaignService.create_campaign(db, data)
    
    now = datetime.utcnow()
    return {
        "id": campaign.id,
        "key": campaign.key,
        "kind": campaign.kind,
        "placement": campaign.placement,
        "template": campaign.template,
        "priority": campaign.priority,
        "is_enabled": campaign.is_enabled,
        "start_at": campaign.start_at,
        "end_at": campaign.end_at,
        "content": campaign.content,
        "rules": [rule.rule for rule in campaign.rules],
        "actions": [
            {
                "trigger": action.trigger,
                "action_type": action.action_type,
                "action": action.action
            }
            for action in campaign.actions
        ],
        "status": CampaignService._calculate_status(campaign, now),
        "created_at": campaign.created_at,
        "updated_at": campaign.updated_at
    }


@router.put("/campaigns/{campaign_id}", response_model=CampaignRead)
async def update_campaign(
    campaign_id: UUID,
    data: CampaignUpdate,
    db: AsyncSession = Depends(get_db)
):
    """캠페인 수정 (전체 교체 전략)"""
    campaign = await CampaignService.update_campaign(db, campaign_id, data)
    
    now = datetime.utcnow()
    return {
        "id": campaign.id,
        "key": campaign.key,
        "kind": campaign.kind,
        "placement": campaign.placement,
        "template": campaign.template,
        "priority": campaign.priority,
        "is_enabled": campaign.is_enabled,
        "start_at": campaign.start_at,
        "end_at": campaign.end_at,
        "content": campaign.content,
        "rules": [rule.rule for rule in campaign.rules],
        "actions": [
            {
                "trigger": action.trigger,
                "action_type": action.action_type,
                "action": action.action
            }
            for action in campaign.actions
        ],
        "status": CampaignService._calculate_status(campaign, now),
        "created_at": campaign.created_at,
        "updated_at": campaign.updated_at
    }


@router.post("/campaigns/{campaign_id}/toggle", response_model=CampaignRead)
async def toggle_campaign(
    campaign_id: UUID,
    data: CampaignToggleRequest,
    db: AsyncSession = Depends(get_db)
):
    """캠페인 토글 (idempotent)"""
    campaign = await CampaignService.toggle_campaign(db, campaign_id, data.is_enabled)
    
    now = datetime.utcnow()
    return {
        "id": campaign.id,
        "key": campaign.key,
        "kind": campaign.kind,
        "placement": campaign.placement,
        "template": campaign.template,
        "priority": campaign.priority,
        "is_enabled": campaign.is_enabled,
        "start_at": campaign.start_at,
        "end_at": campaign.end_at,
        "content": campaign.content,
        "rules": [rule.rule for rule in campaign.rules],
        "actions": [
            {
                "trigger": action.trigger,
                "action_type": action.action_type,
                "action": action.action
            }
            for action in campaign.actions
        ],
        "status": CampaignService._calculate_status(campaign, now),
        "created_at": campaign.created_at,
        "updated_at": campaign.updated_at
    }


@router.post("/campaigns/simulate", response_model=CampaignSimulateResponse)
async def simulate_campaign(
    data: CampaignSimulateRequest,
    db: AsyncSession = Depends(get_db)
):
    """시뮬레이션 (운영 검증용)"""
    result = await CampaignService.simulate_campaign(
        db=db,
        user_id=data.user_id,
        trigger=data.trigger.value,
        context=data.context
    )
    return result


@router.get("/rewards", response_model=list[RewardRead])
async def get_rewards(
    user_id: Optional[UUID] = Query(None, description="유저 ID"),
    campaign_id: Optional[UUID] = Query(None, description="캠페인 ID"),
    db: AsyncSession = Depends(get_db)
):
    """리워드 조회"""
    rewards = await CampaignService.get_rewards(db, user_id=user_id, campaign_id=campaign_id)
    
    result = []
    for reward in rewards:
        result.append({
            "id": reward.id,
            "user_id": reward.user_id,
            "campaign_id": reward.campaign_id,
            "campaign_key": reward.campaign.key if reward.campaign else "",
            "status": reward.status,
            "granted_at": reward.granted_at,
            "idempotency_key": reward.idempotency_key,
            "created_at": reward.created_at
        })
    
    return result


@router.get("/impressions", response_model=list[ImpressionRead])
async def get_impressions(
    user_id: Optional[UUID] = Query(None, description="유저 ID"),
    campaign_id: Optional[UUID] = Query(None, description="캠페인 ID"),
    db: AsyncSession = Depends(get_db)
):
    """노출 조회"""
    impressions = await CampaignService.get_impressions(db, user_id=user_id, campaign_id=campaign_id)
    
    result = []
    for impression in impressions:
        result.append({
            "id": impression.id,
            "user_id": impression.user_id,
            "campaign_id": impression.campaign_id,
            "campaign_key": impression.campaign.key if impression.campaign else "",
            "seen_count": impression.seen_count,
            "suppress_until": impression.suppress_until,
            "last_seen_at": impression.last_seen_at,
            "first_seen_at": impression.first_seen_at
        })
    
    return result
