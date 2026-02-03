"""반려동물 관련 비즈니스 로직"""
from uuid import UUID
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException, status

from app.models.pet import Pet, AgeStage, AgeInputMode, PetHealthConcern
from app.schemas.pet import PetCreate, PetRead
from app.services.user_service import UserService


class PetService:
    """반려동물 서비스 - 반려동물 관련 비즈니스 로직만 담당"""
    
    @staticmethod
    async def get_pets_by_user_id(user_id: UUID, db: AsyncSession) -> list[Pet]:
        """사용자 ID로 반려동물 목록 조회"""
        result = await db.execute(
            select(Pet).where(Pet.user_id == user_id)
        )
        return list(result.scalars().all())
    
    @staticmethod
    async def get_pet_by_id(pet_id: UUID, db: AsyncSession) -> Pet:
        """반려동물 ID로 조회"""
        result = await db.execute(select(Pet).where(Pet.id == pet_id))
        pet = result.scalar_one_or_none()
        
        if pet is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Pet not found"
            )
        
        return pet
    
    @staticmethod
    async def create_pet(
        user_id: UUID,
        pet_data: PetCreate,
        db: AsyncSession
    ) -> Pet:
        """반려동물 생성"""
        # 중복 체크 (같은 이름의 펫이 있는지)
        existing = await db.execute(
            select(Pet).where(
                Pet.user_id == user_id,
                Pet.name == pet_data.name
            )
        )
        if existing.scalar_one_or_none() is not None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Pet with this name already exists"
            )
        
        # age_stage 계산 로직 (비즈니스 로직)
        age_stage = PetService._calculate_age_stage(
            pet_data.age_mode,
            pet_data.birthdate,
            pet_data.approx_age_months
        )
        
        pet = Pet(
            user_id=user_id,
            name=pet_data.name,
            species=pet_data.species,
            age_mode=pet_data.age_mode,
            birthdate=pet_data.birthdate,
            approx_age_months=pet_data.approx_age_months,
            breed_code=pet_data.breed_code,
            sex=pet_data.sex,
            is_neutered=pet_data.is_neutered,
            weight_kg=pet_data.weight_kg,
            body_condition_score=pet_data.body_condition_score,
            age_stage=age_stage,
            photo_url=pet_data.photo_url,
            is_primary=pet_data.is_primary if pet_data.is_primary is not None else False,
        )
        
        db.add(pet)
        await db.commit()
        await db.refresh(pet)
        
        return pet
    
    @staticmethod
    def _calculate_age_stage(
        age_mode: AgeInputMode,
        birthdate: datetime | None,
        approx_age_months: int | None
    ) -> AgeStage:
        """나이 단계 계산 (비즈니스 로직)"""
        from datetime import date
        
        age_months: int | None = None
        
        if age_mode == AgeInputMode.BIRTHDATE and birthdate:
            today = date.today()
            age_months = (today.year - birthdate.year) * 12 + (today.month - birthdate.month)
        elif age_mode == AgeInputMode.APPROX and approx_age_months is not None:
            age_months = approx_age_months
        
        if age_months is None:
            return AgeStage.ADULT  # 기본값
        
        if age_months < 12:
            return AgeStage.PUPPY
        elif age_months >= 84:  # 7세 이상
            return AgeStage.SENIOR
        else:
            return AgeStage.ADULT
    
    @staticmethod
    async def update_pet(
        pet_id: UUID,
        pet_data: PetCreate,
        db: AsyncSession
    ) -> Pet:
        """반려동물 정보 업데이트"""
        pet = await PetService.get_pet_by_id(pet_id, db)
        
        # age_stage 재계산
        age_stage = PetService._calculate_age_stage(
            pet_data.age_mode,
            pet_data.birthdate,
            pet_data.approx_age_months
        )
        
        # 필드 업데이트
        pet.name = pet_data.name
        pet.species = pet_data.species
        pet.age_mode = pet_data.age_mode
        pet.birthdate = pet_data.birthdate
        pet.approx_age_months = pet_data.approx_age_months
        pet.breed_code = pet_data.breed_code
        pet.sex = pet_data.sex
        pet.is_neutered = pet_data.is_neutered
        pet.weight_kg = pet_data.weight_kg
        pet.body_condition_score = pet_data.body_condition_score
        pet.age_stage = age_stage
        pet.photo_url = pet_data.photo_url
        if pet_data.is_primary is not None:
            pet.is_primary = pet_data.is_primary
        
        await db.commit()
        await db.refresh(pet)
        
        return pet
    
    @staticmethod
    async def get_primary_pet_by_device_uid(
        device_uid: str,
        db: AsyncSession
    ) -> Pet | None:
        """Device UID로 Primary Pet 조회"""
        # 1. User 조회
        user = await UserService.get_user_by_device_uid(device_uid, db)
        if user is None:
            return None
        
        # 2. Primary Pet 조회
        result = await db.execute(
            select(Pet).where(
                Pet.user_id == user.id,
                Pet.is_primary == True
            )
        )
        return result.scalar_one_or_none()