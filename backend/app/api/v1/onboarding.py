from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
import traceback
import logging
from app.db.session import get_db
from app.schemas.onboarding import OnboardingCompleteRequest, OnboardingCompleteResponse
from app.services.onboarding_service import complete_onboarding

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post("/complete", response_model=OnboardingCompleteResponse)
async def complete_onboarding_endpoint(
    request: OnboardingCompleteRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    온보딩 완료 API
    - 트랜잭션으로 한번에 저장
    - 실패 시 롤백
    """
    try:
        logger.info(f"[Onboarding] 요청 수신: device_uid={request.device_uid}, nickname={request.nickname}")
        logger.info(f"[Onboarding] Pet 정보: name={request.pet_name}, species={request.species}, age_mode={request.age_mode}")
        return await complete_onboarding(db, request)
    except ValueError as e:
        logger.error(f"[Onboarding] Validation error: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        error_trace = traceback.format_exc()
        logger.error(f"[Onboarding] 서버 오류: {str(e)}\n{error_trace}")
        raise HTTPException(
            status_code=500, 
            detail=f"온보딩 완료 중 오류가 발생했습니다: {str(e)}"
        )
