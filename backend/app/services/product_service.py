"""상품 관련 비즈니스 로직"""
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException, status
from sqlalchemy.exc import IntegrityError

from app.models.product import Product
from app.schemas.product import ProductRead, ProductCreate, ProductUpdate, RecommendationResponse, RecommendationItem
from app.models.offer import Merchant


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
        """추천 상품 목록 조회 (비즈니스 로직)"""
        # TODO: 실제 추천 알고리즘 구현
        # 현재는 스텁 데이터 반환
        
        # Mock 데이터 생성
        mock_items = [
            RecommendationItem(
                product=ProductRead(
                    id=UUID("00000000-0000-0000-0000-000000000001"),
                    brand_name="로얄캐닌",
                    product_name="미니 어덜트",
                    size_label="3kg",
                    is_active=True,
                ),
                offer_merchant=Merchant.COUPANG,
                current_price=35000,
                avg_price=38000,
                delta_percent=-7.89,
                is_new_low=True,
            ),
            RecommendationItem(
                product=ProductRead(
                    id=UUID("00000000-0000-0000-0000-000000000002"),
                    brand_name="힐스",
                    product_name="사이언스 다이어트",
                    size_label="5kg",
                    is_active=True,
                ),
                offer_merchant=Merchant.NAVER,
                current_price=45000,
                avg_price=45000,
                delta_percent=0.0,
                is_new_low=False,
            ),
        ]
        
        return RecommendationResponse(
            pet_id=pet_id,
            items=mock_items,
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