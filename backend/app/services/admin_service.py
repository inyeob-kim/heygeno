"""관리자용 서비스 - 성분/영양/알레르겐/클레임 관리"""
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException, status
from sqlalchemy.exc import IntegrityError
from datetime import datetime

from app.models.product import (
    ProductIngredientProfile, ProductNutritionFacts,
    ProductAllergen, ProductClaim, ClaimCode
)
from app.models.pet import AllergenCode
from app.schemas.admin import (
    IngredientProfileCreate, IngredientProfileUpdate,
    NutritionFactsCreate, NutritionFactsUpdate,
    ProductAllergenCreate, ProductAllergenUpdate,
    ProductClaimCreate, ProductClaimUpdate
)


class AdminService:
    """관리자 서비스 - 성분/영양/알레르겐/클레임 관리"""
    
    # ========== 성분 정보 ==========
    @staticmethod
    async def get_ingredient_profile(product_id: UUID, db: AsyncSession) -> ProductIngredientProfile | None:
        """성분 정보 조회"""
        result = await db.execute(
            select(ProductIngredientProfile).where(ProductIngredientProfile.product_id == product_id)
        )
        return result.scalar_one_or_none()
    
    @staticmethod
    async def create_or_update_ingredient_profile(
        product_id: UUID,
        data: IngredientProfileCreate | IngredientProfileUpdate,
        db: AsyncSession
    ) -> ProductIngredientProfile:
        """성분 정보 생성 또는 수정"""
        existing = await AdminService.get_ingredient_profile(product_id, db)
        
        if existing:
            # 수정
            if data.ingredients_text is not None:
                existing.ingredients_text = data.ingredients_text
            if data.additives_text is not None:
                existing.additives_text = data.additives_text
            if data.parsed is not None:
                existing.parsed = data.parsed
            if data.source is not None:
                existing.source = data.source
            existing.version += 1
            existing.updated_at = datetime.now().isoformat()
            profile = existing
        else:
            # 생성
            profile = ProductIngredientProfile(
                product_id=product_id,
                ingredients_text=data.ingredients_text,
                additives_text=data.additives_text,
                parsed=data.parsed,
                source=data.source,
                version=1,
                updated_at=datetime.now().isoformat()
            )
            db.add(profile)
        
        try:
            await db.commit()
            await db.refresh(profile)
        except IntegrityError as e:
            await db.rollback()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Failed to save ingredient profile: {str(e)}"
            )
        
        return profile
    
    # ========== 영양 정보 ==========
    @staticmethod
    async def get_nutrition_facts(product_id: UUID, db: AsyncSession) -> ProductNutritionFacts | None:
        """영양 정보 조회"""
        result = await db.execute(
            select(ProductNutritionFacts).where(ProductNutritionFacts.product_id == product_id)
        )
        return result.scalar_one_or_none()
    
    @staticmethod
    async def create_or_update_nutrition_facts(
        product_id: UUID,
        data: NutritionFactsCreate | NutritionFactsUpdate,
        db: AsyncSession
    ) -> ProductNutritionFacts:
        """영양 정보 생성 또는 수정"""
        existing = await AdminService.get_nutrition_facts(product_id, db)
        
        if existing:
            # 수정
            if data.protein_pct is not None:
                existing.protein_pct = data.protein_pct
            if data.fat_pct is not None:
                existing.fat_pct = data.fat_pct
            if data.fiber_pct is not None:
                existing.fiber_pct = data.fiber_pct
            if data.moisture_pct is not None:
                existing.moisture_pct = data.moisture_pct
            if data.ash_pct is not None:
                existing.ash_pct = data.ash_pct
            if data.kcal_per_100g is not None:
                existing.kcal_per_100g = data.kcal_per_100g
            if data.calcium_pct is not None:
                existing.calcium_pct = data.calcium_pct
            if data.phosphorus_pct is not None:
                existing.phosphorus_pct = data.phosphorus_pct
            if data.aafco_statement is not None:
                existing.aafco_statement = data.aafco_statement
            existing.version += 1
            existing.updated_at = datetime.now().isoformat()
            facts = existing
        else:
            # 생성
            facts = ProductNutritionFacts(
                product_id=product_id,
                protein_pct=data.protein_pct,
                fat_pct=data.fat_pct,
                fiber_pct=data.fiber_pct,
                moisture_pct=data.moisture_pct,
                ash_pct=data.ash_pct,
                kcal_per_100g=data.kcal_per_100g,
                calcium_pct=data.calcium_pct,
                phosphorus_pct=data.phosphorus_pct,
                aafco_statement=data.aafco_statement,
                version=1,
                updated_at=datetime.now().isoformat()
            )
            db.add(facts)
        
        try:
            await db.commit()
            await db.refresh(facts)
        except IntegrityError as e:
            await db.rollback()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Failed to save nutrition facts: {str(e)}"
            )
        
        return facts
    
    # ========== 알레르겐 ==========
    @staticmethod
    async def get_allergen_codes(db: AsyncSession) -> list[AllergenCode]:
        """알레르겐 코드 목록 조회"""
        result = await db.execute(select(AllergenCode))
        return list(result.scalars().all())
    
    @staticmethod
    async def get_product_allergens(product_id: UUID, db: AsyncSession) -> list[ProductAllergen]:
        """상품 알레르겐 목록 조회"""
        result = await db.execute(
            select(ProductAllergen).where(ProductAllergen.product_id == product_id)
        )
        return list(result.scalars().all())
    
    @staticmethod
    async def add_product_allergen(
        product_id: UUID,
        data: ProductAllergenCreate,
        db: AsyncSession
    ) -> ProductAllergen:
        """상품 알레르겐 추가"""
        # 중복 체크
        existing = await db.execute(
            select(ProductAllergen).where(
                ProductAllergen.product_id == product_id,
                ProductAllergen.allergen_code == data.allergen_code
            )
        )
        if existing.scalar_one_or_none() is not None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Allergen already exists for this product"
            )
        
        allergen = ProductAllergen(
            product_id=product_id,
            allergen_code=data.allergen_code,
            confidence=data.confidence,
            source=data.source
        )
        
        db.add(allergen)
        try:
            await db.commit()
            await db.refresh(allergen)
        except IntegrityError as e:
            await db.rollback()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Failed to add allergen: {str(e)}"
            )
        
        return allergen
    
    @staticmethod
    async def update_product_allergen(
        product_id: UUID,
        allergen_code: str,
        data: ProductAllergenUpdate,
        db: AsyncSession
    ) -> ProductAllergen:
        """상품 알레르겐 수정"""
        result = await db.execute(
            select(ProductAllergen).where(
                ProductAllergen.product_id == product_id,
                ProductAllergen.allergen_code == allergen_code
            )
        )
        allergen = result.scalar_one_or_none()
        
        if allergen is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Product allergen not found"
            )
        
        if data.confidence is not None:
            allergen.confidence = data.confidence
        if data.source is not None:
            allergen.source = data.source
        
        try:
            await db.commit()
            await db.refresh(allergen)
        except IntegrityError as e:
            await db.rollback()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Failed to update allergen: {str(e)}"
            )
        
        return allergen
    
    @staticmethod
    async def delete_product_allergen(
        product_id: UUID,
        allergen_code: str,
        db: AsyncSession
    ) -> None:
        """상품 알레르겐 삭제"""
        result = await db.execute(
            select(ProductAllergen).where(
                ProductAllergen.product_id == product_id,
                ProductAllergen.allergen_code == allergen_code
            )
        )
        allergen = result.scalar_one_or_none()
        
        if allergen is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Product allergen not found"
            )
        
        db.delete(allergen)
        await db.commit()
    
    # ========== 클레임 ==========
    @staticmethod
    async def get_claim_codes(db: AsyncSession) -> list[ClaimCode]:
        """클레임 코드 목록 조회"""
        result = await db.execute(select(ClaimCode))
        return list(result.scalars().all())
    
    @staticmethod
    async def get_product_claims(product_id: UUID, db: AsyncSession) -> list[ProductClaim]:
        """상품 클레임 목록 조회"""
        result = await db.execute(
            select(ProductClaim).where(ProductClaim.product_id == product_id)
        )
        return list(result.scalars().all())
    
    @staticmethod
    async def add_product_claim(
        product_id: UUID,
        data: ProductClaimCreate,
        db: AsyncSession
    ) -> ProductClaim:
        """상품 클레임 추가"""
        # 중복 체크
        existing = await db.execute(
            select(ProductClaim).where(
                ProductClaim.product_id == product_id,
                ProductClaim.claim_code == data.claim_code
            )
        )
        if existing.scalar_one_or_none() is not None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Claim already exists for this product"
            )
        
        claim = ProductClaim(
            product_id=product_id,
            claim_code=data.claim_code,
            evidence_level=data.evidence_level,
            note=data.note
        )
        
        db.add(claim)
        try:
            await db.commit()
            await db.refresh(claim)
        except IntegrityError as e:
            await db.rollback()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Failed to add claim: {str(e)}"
            )
        
        return claim
    
    @staticmethod
    async def update_product_claim(
        product_id: UUID,
        claim_code: str,
        data: ProductClaimUpdate,
        db: AsyncSession
    ) -> ProductClaim:
        """상품 클레임 수정"""
        result = await db.execute(
            select(ProductClaim).where(
                ProductClaim.product_id == product_id,
                ProductClaim.claim_code == claim_code
            )
        )
        claim = result.scalar_one_or_none()
        
        if claim is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Product claim not found"
            )
        
        if data.evidence_level is not None:
            claim.evidence_level = data.evidence_level
        if data.note is not None:
            claim.note = data.note
        
        try:
            await db.commit()
            await db.refresh(claim)
        except IntegrityError as e:
            await db.rollback()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Failed to update claim: {str(e)}"
            )
        
        return claim
    
    @staticmethod
    async def delete_product_claim(
        product_id: UUID,
        claim_code: str,
        db: AsyncSession
    ) -> None:
        """상품 클레임 삭제"""
        result = await db.execute(
            select(ProductClaim).where(
                ProductClaim.product_id == product_id,
                ProductClaim.claim_code == claim_code
            )
        )
        claim = result.scalar_one_or_none()
        
        if claim is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Product claim not found"
            )
        
        db.delete(claim)
        await db.commit()
