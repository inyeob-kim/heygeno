"""
인증 API (재사용 가능한 인증 모듈)

- POST /auth/social-login: 소셜 로그인
- POST /auth/register: 소셜 404 후 회원가입
- POST /auth/email/signup, POST /auth/email/signin: 이메일 회원가입/로그인
- POST /auth/refresh: refresh_token 갱신
- 모든 성공 응답에 access_token (JWT) 포함
"""
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.core.security import create_access_token
from app.services.auth_service import (
    social_login,
    register_after_social,
    get_oauth_id_from_id_token,
    create_user_email,
    email_signin,
    get_or_create_user_by_device_uid,
)

router = APIRouter()


class SocialLoginRequest(BaseModel):
    provider: str  # google | apple | naver
    id_token: str | None = None
    access_token: str | None = None
    refresh_token: str = ""
    restore: bool = False
    firebase_uid: str | None = None
    email: str | None = None
    nickname: str | None = None


class SocialLoginResponse(BaseModel):
    access_token: str
    user_id: str
    provider: str
    oauth_id: str
    nickname: str
    status: str
    restored: bool = False

    class Config:
        from_attributes = True


class RegisterRequest(BaseModel):
    provider: str
    id_token: str | None = None
    access_token: str | None = None
    oauth_id: str | None = None  # id_token 없이 직접 전달 시
    refresh_token: str = ""
    firebase_uid: str | None = None
    email: str | None = None
    nickname: str | None = None


class RegisterResponse(BaseModel):
    access_token: str
    user_id: str
    provider: str
    oauth_id: str
    nickname: str
    status: str = "active"

    class Config:
        from_attributes = True


class EmailSignUpRequest(BaseModel):
    email: str
    password: str
    nickname: str | None = None


class EmailSignInRequest(BaseModel):
    email: str
    password: str


class GuestLoginRequest(BaseModel):
    device_uid: str
    nickname: str = "Guest"


@router.post("/social-login", response_model=SocialLoginResponse)
async def post_social_login(
    body: SocialLoginRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    소셜 로그인.
    - 200: 로그인 성공 (기존 사용자 또는 복구)
    - 404: 회원 없음 → 프론트에서 POST /auth/register 호출
    - 403: 탈퇴 계정 → restore=true로 재요청
    """
    user, restored = await social_login(
        db,
        provider=body.provider,
        id_token=body.id_token,
        access_token=body.access_token,
        refresh_token=body.refresh_token,
        restore=body.restore,
        firebase_uid=body.firebase_uid,
        email=body.email,
        nickname=body.nickname,
    )
    await db.commit()
    access_token = create_access_token(data={"sub": str(user.id)})
    return SocialLoginResponse(
        access_token=access_token,
        user_id=str(user.id),
        provider=user.provider,
        oauth_id=user.provider_user_id,
        nickname=user.nickname,
        status=user.status,
        restored=restored,
    )


@router.post("/register", response_model=RegisterResponse)
async def post_register(
    body: RegisterRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    소셜 로그인 404 후 회원가입.
    id_token 또는 (provider + oauth_id) 필요.
    """
    from fastapi import HTTPException, status
    from app.core.config import settings
    provider_upper = body.provider.upper()
    oauth_id = body.oauth_id
    if not oauth_id and body.id_token:
        oauth_id = get_oauth_id_from_id_token(
            provider_upper, body.id_token, getattr(settings, "GOOGLE_CLIENT_ID", None)
        )
    if not oauth_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Provide id_token or oauth_id",
        )
    user = await register_after_social(
        db,
        provider=provider_upper,
        oauth_id=oauth_id,
        firebase_uid=body.firebase_uid,
        email=body.email,
        nickname=body.nickname,
        refresh_token=body.refresh_token,
    )
    await db.commit()
    access_token = create_access_token(data={"sub": str(user.id)})
    return RegisterResponse(
        access_token=access_token,
        user_id=str(user.id),
        provider=user.provider,
        oauth_id=user.provider_user_id,
        nickname=user.nickname,
        status=user.status,
    )


class RefreshRequest(BaseModel):
    refresh_token: str
    provider: str


@router.post("/refresh", response_model=SocialLoginResponse)
async def post_refresh(
    body: RefreshRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    refresh_token으로 사용자 조회 후 로그인 상태 반환.
    """
    from sqlalchemy import select
    from app.models.user_token import UserToken
    from app.models.user import User
    from fastapi import HTTPException, status

    result = await db.execute(
        select(UserToken, User).join(User, UserToken.user_id == User.id).where(
            UserToken.provider == body.provider,
            UserToken.refresh_token == body.refresh_token,
        )
    )
    row = result.one_or_none()
    if not row:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")
    token_row, user = row
    if user.status == "withdrawn":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account withdrawn")
    access_token = create_access_token(data={"sub": str(user.id)})
    return SocialLoginResponse(
        access_token=access_token,
        user_id=str(user.id),
        provider=user.provider,
        oauth_id=user.provider_user_id,
        nickname=user.nickname,
        status=user.status,
        restored=False,
    )


@router.post("/email/signup", response_model=RegisterResponse)
async def post_email_signup(
    body: EmailSignUpRequest,
    db: AsyncSession = Depends(get_db),
):
    """이메일 회원가입"""
    user = await create_user_email(
        db,
        email=body.email.strip().lower(),
        password=body.password,
        nickname=body.nickname,
    )
    await db.commit()
    await db.refresh(user)
    access_token = create_access_token(data={"sub": str(user.id)})
    return RegisterResponse(
        access_token=access_token,
        user_id=str(user.id),
        provider=user.provider,
        oauth_id=user.provider_user_id,
        nickname=user.nickname,
        status=user.status,
    )


@router.post("/guest-login", response_model=SocialLoginResponse)
async def post_guest_login(
    body: GuestLoginRequest,
    db: AsyncSession = Depends(get_db),
):
    """게스트 로그인: device_uid로 사용자 조회 또는 생성 후 JWT 반환"""
    user = await get_or_create_user_by_device_uid(
        db,
        device_uid=body.device_uid,
        nickname=body.nickname,
    )
    await db.commit()
    await db.refresh(user)
    access_token = create_access_token(data={"sub": str(user.id)})
    return SocialLoginResponse(
        access_token=access_token,
        user_id=str(user.id),
        provider=user.provider,
        oauth_id=user.provider_user_id,
        nickname=user.nickname,
        status=user.status,
        restored=False,
    )


@router.post("/email/signin", response_model=SocialLoginResponse)
async def post_email_signin(
    body: EmailSignInRequest,
    db: AsyncSession = Depends(get_db),
):
    """이메일 로그인"""
    user = await email_signin(db, body.email.strip().lower(), body.password)
    access_token = create_access_token(data={"sub": str(user.id)})
    return SocialLoginResponse(
        access_token=access_token,
        user_id=str(user.id),
        provider=user.provider,
        oauth_id=user.provider_user_id,
        nickname=user.nickname,
        status=user.status,
        restored=False,
    )
