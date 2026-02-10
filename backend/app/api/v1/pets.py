"""반려동물 API 라우터 - 라우팅만 담당"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from uuid import UUID
from typing import Optional

from app.db.session import get_db
from app.api.deps import get_device_uid
from app.schemas.pet import PetCreate, PetRead
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
    
    try:
        # device_uid로 user 찾기 (없으면 생성하지 않고 None 반환)
        user = await UserService.get_user_by_device_uid(device_uid, db)
        if not user:
            logger.warning(f"[Pets API] User를 찾을 수 없음: device_uid={device_uid}")
            return []
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
    db: AsyncSession = Depends(get_db),
    # TODO: 실제 인증 구현 후 user: User = Depends(get_current_user)
):
    """반려동물 등록"""
    # TODO: 실제 user_id 설정 구현 (현재는 Mock user 사용)
    device_uid = "mock_device_uid"  # TODO: 실제 device_uid 추출
    mock_user = await UserService.get_or_create_user_by_device_uid(
        device_uid, "Mock User", db
    )
    
    pet = await PetService.create_pet(mock_user.id, pet_data, db)
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
    
    logger.info(f"[Pets API] Primary pet 찾음: pet_id={pet.id}, name={pet.name}")
    
    # Health concerns 조회
    result = await db.execute(
        select(PetHealthConcern.concern_code).where(
            PetHealthConcern.pet_id == pet.id
        )
    )
    health_concerns = [row[0] for row in result.all()]
    logger.info(f"[Pets API] Health concerns: {health_concerns}")
    
    # Food allergies 조회
    result = await db.execute(
        select(PetFoodAllergy.allergen_code).where(
            PetFoodAllergy.pet_id == pet.id
        )
    )
    food_allergies = [row[0] for row in result.all()]
    logger.info(f"[Pets API] Food allergies: {food_allergies}")
    
    # Other allergies 조회
    result = await db.execute(
        select(PetOtherAllergy.other_text).where(
            PetOtherAllergy.pet_id == pet.id
        )
    )
    other_allergy_row = result.first()
    other_allergies = other_allergy_row[0] if other_allergy_row else None
    logger.info(f"[Pets API] Other allergies: {other_allergies}")
    
    return PetSummaryResponse(
        id=pet.id,
        name=pet.name,
        species=pet.species.value,
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
