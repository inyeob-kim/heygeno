"""반려동물 API 라우터 - 라우팅만 담당"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID
from typing import Optional

from app.db.session import get_db
from app.api.deps import get_device_uid
from app.schemas.pet import PetCreate, PetRead
from app.schemas.pet_summary import PetSummaryResponse
from app.services.pet_service import PetService
from app.services.user_service import UserService
from app.models.pet import PetHealthConcern

router = APIRouter()


@router.get("/", response_model=list[PetRead])
async def get_pets(
    db: AsyncSession = Depends(get_db),
    # TODO: 실제 인증 구현 후 user: User = Depends(get_current_user)
):
    """반려동물 목록 조회"""
    # TODO: 실제 user_id 기반 필터링 구현
    # 현재는 Mock user 사용
    mock_user_id = UUID("00000000-0000-0000-0000-000000000000")
    pets = await PetService.get_pets_by_user_id(mock_user_id, db)
    return [PetRead.model_validate(pet) for pet in pets]


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
    from sqlalchemy import select
    result = await db.execute(
        select(PetHealthConcern.concern_code).where(
            PetHealthConcern.pet_id == pet.id
        )
    )
    health_concerns = [row[0] for row in result.all()]
    logger.info(f"[Pets API] Health concerns: {health_concerns}")
    
    return PetSummaryResponse(
        id=pet.id,
        name=pet.name,
        species=pet.species.value,
        age_stage=pet.age_stage.value if pet.age_stage else None,
        approx_age_months=pet.approx_age_months,
        weight_kg=float(pet.weight_kg),
        health_concerns=health_concerns,
        photo_url=pet.photo_url,
    )


@router.get("/{pet_id}", response_model=PetRead)
async def get_pet(
    pet_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """반려동물 상세 조회"""
    pet = await PetService.get_pet_by_id(pet_id, db)
    return PetRead.model_validate(pet)
