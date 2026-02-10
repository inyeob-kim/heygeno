from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete
import logging
from app.models.user import User, AuthProvider
from app.models.pet import (
    Pet, PetSpecies, AgeInputMode, AgeStage, PetSex,
    PetHealthConcern, PetFoodAllergy, PetOtherAllergy, AllergenCode
)
from app.models.tracking import Tracking
from app.schemas.onboarding import OnboardingCompleteRequest, OnboardingCompleteResponse
from datetime import date, datetime
from typing import Optional
from uuid import UUID

logger = logging.getLogger(__name__)


def calculate_age_stage(age_months: Optional[int], birthdate: Optional[date]) -> AgeStage:
    """나이 단계 계산 (PUPPY/ADULT/SENIOR)"""
    if age_months is not None:
        months = age_months
    elif birthdate:
        today = date.today()
        months = (today.year - birthdate.year) * 12 + (today.month - birthdate.month)
    else:
        return AgeStage.ADULT  # 기본값
    
    if months < 12:
        return AgeStage.PUPPY
    elif months < 84:  # 7년
        return AgeStage.ADULT
    else:
        return AgeStage.SENIOR


async def complete_onboarding(
    db: AsyncSession,
    request: OnboardingCompleteRequest
) -> OnboardingCompleteResponse:
    """
    온보딩 완료 트랜잭션
    """
    try:
        logger.info(f"[OnboardingService] 시작: device_uid={request.device_uid}")
        
        # 1. Users UPSERT
        logger.info("[OnboardingService] 1. Users UPSERT 시작")
        result = await db.execute(
            select(User).where(
                User.provider == AuthProvider.DEVICE,
                User.provider_user_id == request.device_uid
            )
        )
        user = result.scalar_one_or_none()
        logger.info(f"[OnboardingService] User 조회 결과: {user is not None}")
        
        if user:
            # 기존 사용자가 있으면 닉네임이 제공된 경우에만 업데이트 (펫 추가 모드 대응)
            if request.nickname and request.nickname.strip():
                user.nickname = request.nickname
            user.updated_at = datetime.utcnow()
        else:
            user = User(
                provider=AuthProvider.DEVICE,
                provider_user_id=request.device_uid,
                nickname=request.nickname,
                timezone='Asia/Seoul'
            )
            db.add(user)
        
        await db.flush()  # user.id를 얻기 위해
        logger.info(f"[OnboardingService] User ID: {user.id}")
        
        # 2. Pets CREATE/UPDATE
        # 펫 추가 모드면 항상 새 펫 생성 (is_primary=False)
        # 일반 온보딩 모드면 primary pet 업데이트/생성
        logger.info(f"[OnboardingService] 2. Pets 처리 시작 (펫 추가 모드: {request.is_add_pet_mode})")
        
        age_stage = calculate_age_stage(
            request.approx_age_months,
            request.birthdate
        )
        logger.info(f"[OnboardingService] Age stage 계산: {age_stage}")
        
        if request.is_add_pet_mode:
            # 펫 추가 모드: 항상 새 펫 생성 (is_primary=False)
            logger.info("[OnboardingService] 펫 추가 모드: 새 펫 생성")
            pet = Pet(
                user_id=user.id,
                name=request.pet_name,
                species=PetSpecies[request.species],
                age_mode=AgeInputMode[request.age_mode],
                birthdate=request.birthdate,
                approx_age_months=request.approx_age_months,
                breed_code=request.breed_code,
                sex=PetSex[request.sex],
                is_neutered=request.is_neutered,
                weight_kg=request.weight_kg,
                body_condition_score=request.body_condition_score,
                age_stage=age_stage,
                photo_url=request.photo_url,
                is_primary=False  # 추가 펫은 primary가 아님
            )
            db.add(pet)
        else:
            # 일반 온보딩 모드: primary pet 업데이트/생성
            result = await db.execute(
                select(Pet).where(
                    Pet.user_id == user.id,
                    Pet.is_primary == True
                )
            )
            pet = result.scalar_one_or_none()
            logger.info(f"[OnboardingService] Primary Pet 조회 결과: {pet is not None}")
            
            if pet:
                # 업데이트
                logger.info("[OnboardingService] 기존 Primary Pet 업데이트")
                pet.name = request.pet_name
                pet.species = PetSpecies[request.species]
                pet.age_mode = AgeInputMode[request.age_mode]
                pet.birthdate = request.birthdate
                pet.approx_age_months = request.approx_age_months
                pet.breed_code = request.breed_code
                pet.sex = PetSex[request.sex]
                pet.is_neutered = request.is_neutered
                pet.weight_kg = request.weight_kg
                pet.body_condition_score = request.body_condition_score
                pet.age_stage = age_stage
                pet.photo_url = request.photo_url
                pet.updated_at = datetime.utcnow()
            else:
                # 생성
                logger.info("[OnboardingService] 새 Primary Pet 생성")
                logger.info(f"[OnboardingService] Pet 데이터: species={request.species}, age_mode={request.age_mode}, breed_code={request.breed_code}")
                pet = Pet(
                    user_id=user.id,
                    name=request.pet_name,
                    species=PetSpecies[request.species],
                    age_mode=AgeInputMode[request.age_mode],
                    birthdate=request.birthdate,
                    approx_age_months=request.approx_age_months,
                    breed_code=request.breed_code,
                    sex=PetSex[request.sex],
                    is_neutered=request.is_neutered,
                    weight_kg=request.weight_kg,
                    body_condition_score=request.body_condition_score,
                    age_stage=age_stage,
                    photo_url=request.photo_url,
                    is_primary=True
                )
                db.add(pet)
        
        await db.flush()  # pet.id를 얻기 위해
        logger.info(f"[OnboardingService] Pet ID: {pet.id}")
        
        # 3. pet_health_concerns: DELETE 기존 → BULK INSERT (유효한 코드만)
        logger.info("[OnboardingService] 3. Health concerns 처리 시작")
        await db.execute(
            delete(PetHealthConcern).where(PetHealthConcern.pet_id == pet.id)
        )
        
        if request.health_concerns:  # 빈 배열이 아니면
            # 유효한 건강 고민 코드만 필터링
            from app.models.pet import HealthConcernCode
            valid_codes_result = await db.execute(
                select(HealthConcernCode.code).where(
                    HealthConcernCode.code.in_(request.health_concerns)
                )
            )
            valid_codes = {row[0] for row in valid_codes_result.all()}
            
            # 유효하지 않은 코드가 있으면 로그 기록
            invalid_codes = set(request.health_concerns) - valid_codes
            if invalid_codes:
                logger.warning(
                    f"[OnboardingService] 유효하지 않은 건강 고민 코드 발견: {invalid_codes}. "
                    f"이 코드들은 건너뜁니다."
                )
            
            # 유효한 코드만 삽입
            if valid_codes:
                health_concerns = [
                    PetHealthConcern(
                        pet_id=pet.id,
                        concern_code=code
                    )
                    for code in valid_codes
                ]
                db.add_all(health_concerns)
        
        # 4. pet_food_allergies: DELETE 기존 → BULK INSERT (유효한 코드만)
        await db.execute(
            delete(PetFoodAllergy).where(PetFoodAllergy.pet_id == pet.id)
        )
        
        if request.food_allergies:  # 빈 배열이 아니면
            # 유효한 알레르기 코드만 필터링
            valid_codes_result = await db.execute(
                select(AllergenCode.code).where(
                    AllergenCode.code.in_(request.food_allergies)
                )
            )
            valid_codes = {row[0] for row in valid_codes_result.all()}
            
            # 유효하지 않은 코드가 있으면 로그 기록
            invalid_codes = set(request.food_allergies) - valid_codes
            if invalid_codes:
                logger.warning(
                    f"[OnboardingService] 유효하지 않은 알레르기 코드 발견: {invalid_codes}. "
                    f"이 코드들은 건너뜁니다."
                )
            
            # 유효한 코드만 삽입
            if valid_codes:
                food_allergies = [
                    PetFoodAllergy(
                        pet_id=pet.id,
                        allergen_code=code
                    )
                    for code in valid_codes
                ]
                db.add_all(food_allergies)
        
        # 5. pet_other_allergies: UPSERT
        if request.other_allergy_text:
            result = await db.execute(
                select(PetOtherAllergy).where(PetOtherAllergy.pet_id == pet.id)
            )
            other_allergy = result.scalar_one_or_none()
            
            if other_allergy:
                other_allergy.other_text = request.other_allergy_text
                other_allergy.updated_at = datetime.utcnow()
            else:
                other_allergy = PetOtherAllergy(
                    pet_id=pet.id,
                    other_text=request.other_allergy_text
                )
                db.add(other_allergy)
        else:
            # 텍스트가 없으면 삭제
            await db.execute(
                delete(PetOtherAllergy).where(PetOtherAllergy.pet_id == pet.id)
            )
        
        # 6. (선택) trackings 생성
        if request.auto_track and request.auto_track.enable:
            if request.auto_track.product_ids:
                for product_id in request.auto_track.product_ids:
                    # 중복 체크
                    result = await db.execute(
                        select(Tracking).where(
                            Tracking.user_id == user.id,
                            Tracking.product_id == product_id
                        )
                    )
                    existing = result.scalar_one_or_none()
                    
                    if not existing:
                        tracking = Tracking(
                            user_id=user.id,
                            pet_id=pet.id,
                            product_id=product_id
                        )
                        db.add(tracking)
        
        # 7. COMMIT (get_db에서 자동으로 처리되지만 명시적으로)
        logger.info("[OnboardingService] 7. COMMIT 시작")
        await db.commit()
        logger.info("[OnboardingService] 온보딩 완료 성공")
        
        return OnboardingCompleteResponse(
            success=True,
            user_id=user.id,
            pet_id=pet.id
        )
        
    except Exception as e:
        logger.error(f"[OnboardingService] 오류 발생: {str(e)}", exc_info=True)
        await db.rollback()
        raise e
