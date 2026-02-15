"""반려동물 API 라우터 - 라우팅만 담당"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete
from uuid import UUID
from typing import Optional
from datetime import datetime

from app.db.session import get_db
from app.api.deps import get_device_uid
from app.schemas.pet import PetCreate, PetRead, PetUpdate
from app.schemas.pet_summary import PetSummaryResponse
from app.services.pet_service import PetService
from app.services.user_service import UserService
from app.models.pet import PetHealthConcern, PetFoodAllergy, PetOtherAllergy

router = APIRouter()


@router.get("/", response_model=list[PetSummaryResponse])
async def get_pets(
    device_uid: Optional[str] = Depends(get_device_uid),
    db: AsyncSession = Depends(get_db),
):
    """반려동물 목록 조회 (device_uid 기반)"""
    import logging
    logger = logging.getLogger(__name__)
    
    if not device_uid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="X-Device-UID header is required"
        )
    
    logger.info(f"[Pets API] / 요청: device_uid={device_uid}")
    
    # device_uid로 user 찾기
    try:
        user = await UserService.get_user_by_device_uid(device_uid, db)
        if not user:
            logger.info(f"[Pets API] User 없음: device_uid={device_uid}")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User 조회 중 오류가 발생했습니다: {str(e)}"
            )
    except Exception as e:
        logger.error(f"[Pets API] User 조회 중 오류: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"User 조회 중 오류가 발생했습니다: {str(e)}"
        )
    
    # user의 모든 펫 조회
    try:
        pets = await PetService.get_pets_by_user_id(user.id, db)
        logger.info(f"[Pets API] 펫 {len(pets)}개 찾음: user_id={user.id}")
    except Exception as e:
        logger.error(f"[Pets API] 펫 조회 중 오류: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"펫 조회 중 오류가 발생했습니다: {str(e)}"
        )
    
    # 각 펫에 대해 PetSummaryResponse 생성
    result = []
    try:
        for pet in pets:
            try:
                # Health concerns 조회
                health_result = await db.execute(
                    select(PetHealthConcern.concern_code).where(
                        PetHealthConcern.pet_id == pet.id
                    )
                )
                health_concerns = [row[0] for row in health_result.all()]
                
                # Food allergies 조회
                food_result = await db.execute(
                    select(PetFoodAllergy.allergen_code).where(
                        PetFoodAllergy.pet_id == pet.id
                    )
                )
                food_allergies = [row[0] for row in food_result.all()]
                
                # Other allergies 조회
                other_result = await db.execute(
                    select(PetOtherAllergy.other_text).where(
                        PetOtherAllergy.pet_id == pet.id
                    )
                )
                other_allergy_row = other_result.first()
                other_allergies = other_allergy_row[0] if other_allergy_row else None
                
                result.append(PetSummaryResponse(
                    id=pet.id,
                    name=pet.name or '',
                    species=pet.species.value if pet.species else '',
                    age_stage=pet.age_stage.value if pet.age_stage else None,
                    approx_age_months=pet.approx_age_months,
                    weight_kg=float(pet.weight_kg) if pet.weight_kg is not None else 0.0,
                    health_concerns=health_concerns,
                    photo_url=pet.photo_url,
                    breed_code=pet.breed_code,
                    is_neutered=pet.is_neutered,
                    sex=pet.sex.value if pet.sex else None,
                    food_allergies=food_allergies,
                    other_allergies=other_allergies,
                    is_primary=pet.is_primary,
                ))
            except Exception as e:
                logger.error(f"[Pets API] 펫 {pet.id} 처리 중 오류: {str(e)}", exc_info=True)
                # 개별 펫 처리 실패해도 계속 진행
                continue
        
        logger.info(f"[Pets API] 총 {len(result)}개 펫 반환")
        return result
    except Exception as e:
        logger.error(f"[Pets API] 펫 목록 처리 중 오류: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"펫 목록 조회 중 오류가 발생했습니다: {str(e)}"
        )


@router.post("/", response_model=PetRead, status_code=201)
async def create_pet(
    pet_data: PetCreate,
    device_uid: Optional[str] = Depends(get_device_uid),
    db: AsyncSession = Depends(get_db),
):
    """반려동물 등록"""
    if not device_uid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="X-Device-UID header is required"
        )
    
    # device_uid로 사용자 조회
    user = await UserService.get_user_by_device_uid(device_uid, db)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
    )
    
    pet = await PetService.create_pet(user.id, pet_data, db)
    return PetRead.model_validate(pet)


@router.get("/primary", response_model=PetSummaryResponse)
async def get_primary_pet(
    device_uid: Optional[str] = Depends(get_device_uid),
    db: AsyncSession = Depends(get_db)
):
    """Primary Pet 요약 정보 조회 (홈 화면용)"""
    import logging
    logger = logging.getLogger(__name__)
    
    if not device_uid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="X-Device-UID header is required"
        )
    
    logger.info(f"[Pets API] /primary 요청: device_uid={device_uid}")
    pet = await PetService.get_primary_pet_by_device_uid(device_uid, db)
    
    if pet is None:
        logger.info(f"[Pets API] Primary pet 없음: device_uid={device_uid}")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Primary pet not found"
        )
    
    # Health concerns 조회
    health_result = await db.execute(
        select(PetHealthConcern.concern_code).where(
            PetHealthConcern.pet_id == pet.id
        )
    )
    health_concerns = [row[0] for row in health_result.all()]
    
    # Food allergies 조회
    food_result = await db.execute(
        select(PetFoodAllergy.allergen_code).where(
            PetFoodAllergy.pet_id == pet.id
        )
    )
    food_allergies = [row[0] for row in food_result.all()]
    
    # Other allergies 조회
    other_result = await db.execute(
        select(PetOtherAllergy.other_text).where(
            PetOtherAllergy.pet_id == pet.id
        )
    )
    other_allergy_row = other_result.first()
    other_allergies = other_allergy_row[0] if other_allergy_row else None
    
    return PetSummaryResponse(
        id=pet.id,
        name=pet.name or '',
        species=pet.species.value if pet.species else '',
        age_stage=pet.age_stage.value if pet.age_stage else None,
        approx_age_months=pet.approx_age_months,
        weight_kg=float(pet.weight_kg),
        health_concerns=health_concerns,
        photo_url=pet.photo_url,
        breed_code=pet.breed_code,
        is_neutered=pet.is_neutered,
        sex=pet.sex.value if pet.sex else None,
        food_allergies=food_allergies,
        other_allergies=other_allergies,
        is_primary=pet.is_primary,
    )


@router.get("/{pet_id}", response_model=PetRead)
async def get_pet(
    pet_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """반려동물 상세 조회"""
    pet = await PetService.get_pet_by_id(pet_id, db)
    return PetRead.model_validate(pet)


@router.patch("/{pet_id}/set-primary", response_model=PetSummaryResponse)
async def set_primary_pet(
    pet_id: UUID,
    device_uid: Optional[str] = Depends(get_device_uid),
    db: AsyncSession = Depends(get_db),
):
    """특정 펫을 Primary Pet으로 설정"""
    import logging
    logger = logging.getLogger(__name__)
    
    if not device_uid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="X-Device-UID header is required"
        )
    
    logger.info(f"[Pets API] /{pet_id}/set-primary 요청: device_uid={device_uid}")
    
    try:
        # device_uid로 user 찾기
        user = await UserService.get_user_by_device_uid(device_uid, db)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # Primary pet 설정
        pet = await PetService.set_primary_pet(pet_id, user.id, db)
        logger.info(f"[Pets API] Primary pet 설정 완료: pet_id={pet.id}, name={pet.name}")
        
        # Health concerns 조회
        health_result = await db.execute(
            select(PetHealthConcern.concern_code).where(
                PetHealthConcern.pet_id == pet.id
            )
        )
        health_concerns = [row[0] for row in health_result.all()]
        
        # Food allergies 조회
        food_result = await db.execute(
            select(PetFoodAllergy.allergen_code).where(
                PetFoodAllergy.pet_id == pet.id
            )
        )
        food_allergies = [row[0] for row in food_result.all()]
        
        # Other allergies 조회
        other_result = await db.execute(
            select(PetOtherAllergy.other_text).where(
                PetOtherAllergy.pet_id == pet.id
            )
        )
        other_allergy_row = other_result.first()
        other_allergies = other_allergy_row[0] if other_allergy_row else None
        
        return PetSummaryResponse(
            id=pet.id,
            name=pet.name or '',
            species=pet.species.value if pet.species else '',
            age_stage=pet.age_stage.value if pet.age_stage else None,
            approx_age_months=pet.approx_age_months,
            weight_kg=float(pet.weight_kg) if pet.weight_kg is not None else 0.0,
            health_concerns=health_concerns,
            photo_url=pet.photo_url,
            breed_code=pet.breed_code,
            is_neutered=pet.is_neutered,
            sex=pet.sex.value if pet.sex else None,
            food_allergies=food_allergies,
            other_allergies=other_allergies,
            is_primary=pet.is_primary,
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[Pets API] Primary pet 설정 중 오류: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Primary pet 설정 중 오류가 발생했습니다: {str(e)}"
        )


@router.patch("/{pet_id}", response_model=PetSummaryResponse)
async def update_pet(
    pet_id: UUID,
    pet_update: PetUpdate,
    device_uid: Optional[str] = Depends(get_device_uid),
    db: AsyncSession = Depends(get_db),
):
    """펫 프로필 업데이트 (변할 수 있는 정보만)"""
    import logging
    logger = logging.getLogger(__name__)
    
    if not device_uid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="X-Device-UID header is required"
        )
    
    logger.info(f"[Pets API] PATCH /{pet_id} 요청: device_uid={device_uid}, update_data={pet_update.model_dump()}")
    
    try:
        # device_uid로 user 찾기
        user = await UserService.get_user_by_device_uid(device_uid, db)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # 펫 조회 및 소유자 확인
        pet = await PetService.get_pet_by_id(pet_id, db)
        if pet.user_id != user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to modify this pet"
            )
        
        # 체중 업데이트
        if pet_update.weight_kg is not None:
            pet.weight_kg = pet_update.weight_kg
            logger.info(f"[Pets API] 체중 업데이트: {pet_update.weight_kg}kg")
        
        # 중성화 여부 업데이트
        if pet_update.is_neutered is not None:
            pet.is_neutered = pet_update.is_neutered
            logger.info(f"[Pets API] 중성화 여부 업데이트: {pet_update.is_neutered}")
        
        # 건강 고민 업데이트
        if pet_update.health_concerns is not None:
            logger.info(f"[Pets API] ⚠️ 건강 고민 업데이트 시작: 요청={pet_update.health_concerns}, 타입={type(pet_update.health_concerns)}")
            # 기존 건강 고민 삭제
            await db.execute(
                delete(PetHealthConcern).where(PetHealthConcern.pet_id == pet.id)
            )
            logger.info(f"[Pets API] ✅ 기존 건강 고민 삭제 완료")
            # 새 건강 고민 추가
            if pet_update.health_concerns:
                from app.models.pet import HealthConcernCode
                # DB에 있는 모든 건강 고민 코드 조회 (디버깅용)
                all_codes_result = await db.execute(select(HealthConcernCode.code))
                all_codes = {row[0] for row in all_codes_result.all()}
                logger.info(f"[Pets API] 📋 DB에 있는 모든 건강 고민 코드: {all_codes}")
                
                # 유효한 코드만 필터링
                valid_codes_result = await db.execute(
                    select(HealthConcernCode.code).where(
                        HealthConcernCode.code.in_(pet_update.health_concerns)
                    )
                )
                valid_codes = {row[0] for row in valid_codes_result.all()}
                
                logger.info(f"[Pets API] 🔍 건강 고민 요청: {pet_update.health_concerns}, DB 유효 코드: {valid_codes}")
                
                if valid_codes:
                    health_concerns = [
                        PetHealthConcern(
                            pet_id=pet.id,
                            concern_code=code
                        )
                        for code in valid_codes
                    ]
                    db.add_all(health_concerns)
                    logger.info(f"[Pets API] ✅ 건강 고민 저장 완료: {valid_codes}")
                else:
                    invalid_codes = set(pet_update.health_concerns) - all_codes
                    logger.warning(f"[Pets API] ❌ 건강 고민 저장 실패: 요청한 코드 중 유효한 코드가 없음. 요청: {pet_update.health_concerns}, DB에 없는 코드: {invalid_codes}")
            else:
                logger.info(f"[Pets API] ⚠️ 건강 고민 빈 리스트: 기존 항목만 삭제됨")
            logger.info(f"[Pets API] ✅ 건강 고민 업데이트 완료: 요청={pet_update.health_concerns}")
        
        # 음식 알레르기 업데이트
        if pet_update.food_allergies is not None:
            # 기존 알레르기 삭제
            await db.execute(
                delete(PetFoodAllergy).where(PetFoodAllergy.pet_id == pet.id)
            )
            # 새 알레르기 추가
            if pet_update.food_allergies:
                from app.models.pet import AllergenCode
                # 유효한 코드만 필터링
                valid_codes_result = await db.execute(
                    select(AllergenCode.code).where(
                        AllergenCode.code.in_(pet_update.food_allergies)
                    )
                )
                valid_codes = {row[0] for row in valid_codes_result.all()}
                
                logger.info(f"[Pets API] 음식 알레르기 요청: {pet_update.food_allergies}, DB 유효 코드: {valid_codes}")
                
                if valid_codes:
                    food_allergies = [
                        PetFoodAllergy(
                            pet_id=pet.id,
                            allergen_code=code
                        )
                        for code in valid_codes
                    ]
                    db.add_all(food_allergies)
                    logger.info(f"[Pets API] 음식 알레르기 저장 완료: {valid_codes}")
                else:
                    logger.warning(f"[Pets API] 음식 알레르기 저장 실패: 요청한 코드 중 유효한 코드가 없음. 요청: {pet_update.food_allergies}")
            else:
                logger.info(f"[Pets API] 음식 알레르기 빈 리스트: 기존 항목만 삭제됨")
            logger.info(f"[Pets API] 음식 알레르기 업데이트 완료: 요청={pet_update.food_allergies}")
        
        # 기타 알레르기 업데이트
        if pet_update.other_allergies is not None:
            if pet_update.other_allergies.strip():
                # UPSERT
                other_result = await db.execute(
                    select(PetOtherAllergy).where(PetOtherAllergy.pet_id == pet.id)
                )
                other_allergy = other_result.scalar_one_or_none()
                
                if other_allergy:
                    other_allergy.other_text = pet_update.other_allergies
                else:
                    other_allergy = PetOtherAllergy(
                        pet_id=pet.id,
                        other_text=pet_update.other_allergies
                    )
                    db.add(other_allergy)
            else:
                # 텍스트가 없으면 삭제
                await db.execute(
                    delete(PetOtherAllergy).where(PetOtherAllergy.pet_id == pet.id)
                )
            logger.info(f"[Pets API] 기타 알레르기 업데이트: {pet_update.other_allergies}")
        
        pet.updated_at = datetime.utcnow()
        await db.commit()
        await db.refresh(pet)
        
        # Health concerns 조회
        health_result = await db.execute(
            select(PetHealthConcern.concern_code).where(
                PetHealthConcern.pet_id == pet.id
            )
        )
        health_concerns = [row[0] for row in health_result.all()]
        
        # Food allergies 조회
        food_result = await db.execute(
            select(PetFoodAllergy.allergen_code).where(
                PetFoodAllergy.pet_id == pet.id
            )
        )
        food_allergies = [row[0] for row in food_result.all()]
        
        # Other allergies 조회
        other_result = await db.execute(
            select(PetOtherAllergy.other_text).where(
                PetOtherAllergy.pet_id == pet.id
            )
        )
        other_allergy_row = other_result.first()
        other_allergies = other_allergy_row[0] if other_allergy_row else None
        
        logger.info(f"[Pets API] 펫 업데이트 완료: pet_id={pet.id}")
        
        return PetSummaryResponse(
            id=pet.id,
            name=pet.name or '',
            species=pet.species.value if pet.species else '',
            age_stage=pet.age_stage.value if pet.age_stage else None,
            approx_age_months=pet.approx_age_months,
            weight_kg=float(pet.weight_kg) if pet.weight_kg is not None else 0.0,
            health_concerns=health_concerns,
            photo_url=pet.photo_url,
            breed_code=pet.breed_code,
            is_neutered=pet.is_neutered,
            sex=pet.sex.value if pet.sex else None,
            food_allergies=food_allergies,
            other_allergies=other_allergies,
            is_primary=pet.is_primary,
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[Pets API] 펫 업데이트 중 오류: {str(e)}", exc_info=True)
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"펫 업데이트 중 오류가 발생했습니다: {str(e)}"
        )
