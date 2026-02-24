"""
인증 서비스 (재사용 가능한 인증 모듈)

- 소셜 로그인: (provider, oauth_id) 조회/생성, user_tokens UPSERT
- 이메일 로그인: password_hash 검증, email_verified 체크
- 이메일 인증: 회원가입 시 인증 메일 발송, 토큰으로 검증 완료
- 탈퇴/복구: withdrawal_log, 30일 이내 복구
"""
import secrets
from datetime import datetime, timezone, timedelta
from uuid import UUID
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException, status

from app.models.user import User, UserStatus
from app.models.user_token import UserToken
from app.models.withdrawal_log import WithdrawalLog
from app.models.email_verification_token import EmailVerificationToken
from app.core.security import verify_password as pwd_verify, get_password_hash as pwd_hash
from app.services.email_service import send_verification_email


# ----- id_token 검증 및 oauth_id 추출 -----

def _decode_jwt_sub_unverified(id_token: str) -> str | None:
    """JWT에서 sub 클레임 추출 (서명 미검증)"""
    try:
        from jose import jwt
        payload = jwt.get_unverified_claims(id_token)
        return payload.get("sub")
    except Exception:
        return None


def verify_google_id_token(id_token: str, client_id: str | None = None) -> dict | None:
    """Google id_token 검증 후 payload 반환 (sub, email 등). 실패 시 None."""
    try:
        from google.oauth2 import id_token
        from google.auth.transport import requests
        req = requests.Request()
        # client_id가 없으면 검증만 하고 audience 체크 생략 (개발용)
        if client_id:
            payload = id_token.verify_oauth2_token(id_token, req, client_id)
        else:
            payload = id_token.verify_oauth2_token(id_token, req)
        return payload if isinstance(payload, dict) else None
    except Exception:
        return None


def verify_apple_id_token(id_token: str) -> dict | None:
    """Apple id_token 검증. Apple JWKS로 서명 검증 (선택). 여기서는 decode만."""
    try:
        from jose import jwt
        # 서명 검증 없이 클레임만 추출 (프로덕션에서는 Apple JWKS로 검증 권장)
        payload = jwt.get_unverified_claims(id_token)
        if payload.get("iss") != "https://appleid.apple.com":
            return None
        return payload
    except Exception:
        return None


def get_oauth_id_from_id_token(provider: str, id_token: str, google_client_id: str | None = None) -> str | None:
    """provider별 id_token에서 oauth_id(sub) 추출. Google은 검증 시도."""
    p = provider.upper()
    if p == "GOOGLE":
        payload = verify_google_id_token(id_token, google_client_id)
        if payload:
            return payload.get("sub")
        return _decode_jwt_sub_unverified(id_token)
    if p == "APPLE":
        payload = verify_apple_id_token(id_token)
        if payload:
            return payload.get("sub")
        return _decode_jwt_sub_unverified(id_token)
    if p in ("EMAIL", "NAVER"):
        return _decode_jwt_sub_unverified(id_token)
    return None


# ----- 사용자 조회/생성 -----

async def get_user_by_provider_oauth(
    db: AsyncSession,
    provider: str,
    oauth_id: str,
) -> User | None:
    """(provider, provider_user_id)로 사용자 조회"""
    result = await db.execute(
        select(User).where(
            User.provider == provider,
            User.provider_user_id == oauth_id,
        )
    )
    return result.scalar_one_or_none()


async def get_user_by_firebase_uid(db: AsyncSession, firebase_uid: str) -> User | None:
    """firebase_uid로 사용자 조회"""
    result = await db.execute(select(User).where(User.firebase_uid == firebase_uid))
    return result.scalar_one_or_none()


async def get_or_create_user_by_firebase_uid(
    db: AsyncSession,
    firebase_uid: str,
    *,
    email: str | None = None,
    nickname: str | None = None,
) -> User:
    """Firebase uid로 사용자 조회 또는 생성 (Google 등 Firebase 로그인용)"""
    existing = await get_user_by_firebase_uid(db, firebase_uid)
    if existing:
        if existing.status == UserStatus.WITHDRAWN.value:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Account withdrawn",
            )
        return existing
    user = await create_user_social(
        db,
        provider="GOOGLE",
        oauth_id=firebase_uid,
        firebase_uid=firebase_uid,
        email=email,
        nickname=nickname or "User",
    )
    await db.flush()
    await db.refresh(user)
    return user


async def get_or_create_user_by_device_uid(
    db: AsyncSession,
    device_uid: str,
    nickname: str = "Guest",
) -> User:
    """게스트 로그인: device_uid로 사용자 조회 또는 생성"""
    existing = await get_user_by_provider_oauth(db, "DEVICE", device_uid)
    if existing:
        if existing.status == UserStatus.WITHDRAWN.value:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Account withdrawn",
            )
        return existing
    user = User(
        provider="DEVICE",
        provider_user_id=device_uid,
        nickname=nickname,
        status=UserStatus.ACTIVE.value,
        plan_type="FREE",
    )
    db.add(user)
    await db.flush()
    await db.refresh(user)
    return user


async def get_user_by_email(db: AsyncSession, email: str) -> User | None:
    """이메일로 사용자 조회 (EMAIL provider)"""
    result = await db.execute(
        select(User).where(User.provider == "EMAIL", User.email == email)
    )
    return result.scalar_one_or_none()


async def create_user_social(
    db: AsyncSession,
    provider: str,
    oauth_id: str,
    *,
    firebase_uid: str | None = None,
    email: str | None = None,
    nickname: str | None = None,
) -> User:
    """소셜 로그인으로 새 사용자 생성 (Apple/Google 등은 이메일 이미 검증된 것으로 간주)"""
    provider_upper = provider.upper()
    email_verified = provider_upper in ("APPLE", "GOOGLE")  # 소셜은 인증된 이메일로 간주
    user = User(
        provider=provider_upper,
        provider_user_id=oauth_id,
        firebase_uid=firebase_uid,
        email=email,
        nickname=nickname or "User",
        status=UserStatus.ACTIVE.value,
        plan_type="FREE",
        email_verified=email_verified,
    )
    db.add(user)
    await db.flush()
    await db.refresh(user)
    return user


def _generate_verification_token() -> str:
    return secrets.token_urlsafe(32)


async def create_user_email(
    db: AsyncSession,
    email: str,
    password: str,
    nickname: str | None = None,
) -> User:
    """이메일 회원가입: provider=EMAIL, email_verified=False, 인증 메일 발송"""
    existing = await get_user_by_email(db, email)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered",
        )
    user = User(
        provider="EMAIL",
        provider_user_id=email,
        email=email,
        password_hash=pwd_hash(password),
        nickname=nickname or email.split("@")[0][:50] or "User",
        status=UserStatus.ACTIVE.value,
        plan_type="FREE",
        email_verified=False,
    )
    db.add(user)
    await db.flush()
    await db.refresh(user)

    token_str = _generate_verification_token()
    expires_at = datetime.now(timezone.utc) + timedelta(hours=24)
    evt = EmailVerificationToken(
        user_id=user.id,
        token=token_str,
        expires_at=expires_at,
    )
    db.add(evt)
    await db.flush()
    send_verification_email(email, token_str)

    return user


async def email_signin(db: AsyncSession, email: str, password: str) -> User:
    """이메일 로그인: 비밀번호 검증 후 사용자 반환. 미인증 시 403."""
    user = await get_user_by_email(db, email)
    if not user or not user.password_hash:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )
    if not pwd_verify(password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )
    if user.email_verified is False:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={
                "code": "EMAIL_NOT_VERIFIED",
                "message": "Email not verified. Please check your inbox and click the verification link.",
            },
        )
    if user.status == UserStatus.WITHDRAWN.value:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account withdrawn",
        )
    return user


# ----- 이메일 인증 (verify / resend) -----

async def verify_email_by_token(db: AsyncSession, token: str) -> User | None:
    """토큰으로 이메일 인증 처리. 성공 시 user 반환, 실패/만료 시 None."""
    now = datetime.now(timezone.utc)
    result = await db.execute(
        select(EmailVerificationToken)
        .where(
            EmailVerificationToken.token == token,
            EmailVerificationToken.expires_at > now,
        )
    )
    evt = result.scalar_one_or_none()
    if not evt:
        return None
    user = await db.get(User, evt.user_id)
    if not user:
        return None
    user.email_verified = True
    await db.delete(evt)
    await db.flush()
    await db.refresh(user)
    return user


async def resend_verification_email(db: AsyncSession, email: str) -> None:
    """해당 이메일 사용자에게 인증 메일 재발송. 없거나 이미 인증된 경우 HTTPException."""
    user = await get_user_by_email(db, email)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No account found with this email",
        )
    if user.email_verified:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already verified",
        )
    # 기존 토큰 삭제 후 새 토큰 생성
    result = await db.execute(select(EmailVerificationToken).where(EmailVerificationToken.user_id == user.id))
    for ev in result.scalars().all():
        await db.delete(ev)
    token_str = _generate_verification_token()
    expires_at = datetime.now(timezone.utc) + timedelta(hours=24)
    evt = EmailVerificationToken(user_id=user.id, token=token_str, expires_at=expires_at)
    db.add(evt)
    await db.flush()
    send_verification_email(email, token_str)


# ----- 탈퇴 로그 / 복구 -----

async def find_withdrawn_for_restore(
    db: AsyncSession,
    provider: str,
    oauth_id: str,
) -> WithdrawalLog | None:
    """탈퇴 로그에서 30일 이내 미복구 건 조회"""
    from sqlalchemy import and_
    cutoff = datetime.now(timezone.utc) - timedelta(days=30)
    result = await db.execute(
        select(WithdrawalLog).where(
            and_(
                WithdrawalLog.provider == provider,
                WithdrawalLog.provider_user_id == oauth_id,
                WithdrawalLog.restored_at.is_(None),
                WithdrawalLog.deleted_at >= cutoff,
            )
        ).order_by(WithdrawalLog.deleted_at.desc()).limit(1)
    )
    return result.scalar_one_or_none()


async def restore_user(db: AsyncSession, user: User, log: WithdrawalLog | None = None) -> None:
    """탈퇴 사용자 복구: status=active, withdrawn_at=NULL, withdrawal_log.restored_at 갱신"""
    user.status = UserStatus.ACTIVE.value
    user.withdrawn_at = None
    if log:
        log.restored_at = datetime.now(timezone.utc)
    else:
        log_result = await db.execute(
            select(WithdrawalLog).where(
                WithdrawalLog.user_id == user.id,
                WithdrawalLog.restored_at.is_(None),
            ).order_by(WithdrawalLog.deleted_at.desc()).limit(1)
        )
        latest = log_result.scalar_one_or_none()
        if latest:
            latest.restored_at = datetime.now(timezone.utc)


# ----- user_tokens UPSERT -----

async def upsert_user_token(
    db: AsyncSession,
    user_id: UUID,
    provider: str,
    refresh_token: str,
    access_token: str | None = None,
) -> None:
    """user_tokens에 refresh_token 저장 (있으면 갱신)"""
    result = await db.execute(
        select(UserToken).where(
            UserToken.user_id == user_id,
            UserToken.provider == provider,
        )
    )
    token_row = result.scalar_one_or_none()
    now = datetime.now(timezone.utc)
    if token_row:
        token_row.refresh_token = refresh_token
        token_row.access_token = access_token
        token_row.token_updated_at = now
    else:
        db.add(UserToken(
            user_id=user_id,
            provider=provider,
            refresh_token=refresh_token,
            access_token=access_token,
            token_updated_at=now,
        ))


# ----- social-login 플로우 -----

async def social_login(
    db: AsyncSession,
    provider: str,
    id_token: str | None = None,
    access_token: str | None = None,
    refresh_token: str = "",
    restore: bool = False,
    firebase_uid: str | None = None,
    email: str | None = None,
    nickname: str | None = None,
) -> tuple[User, bool]:
    """
    소셜 로그인 처리.
    Returns: (user, restored)
    - 기존 사용자(active): user_tokens UPSERT 후 반환
    - 탈퇴 사용자: restore=True면 복구 후 반환, 아니면 403
    - 없음: 404 (회원가입 필요)
    """
    from app.core.config import settings
    provider_upper = provider.upper()
    oauth_id = None
    if id_token:
        oauth_id = get_oauth_id_from_id_token(
            provider_upper, id_token, getattr(settings, "GOOGLE_CLIENT_ID", None)
        )
    if not oauth_id and access_token and provider_upper == "NAVER":
        # Naver: access_token으로 API 호출해 oauth_id 획득 (스텁)
        oauth_id = None  # TODO: Naver API

    if not oauth_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not get oauth_id from id_token or access_token",
        )

    user = await get_user_by_provider_oauth(db, provider_upper, oauth_id)
    if user:
        if user.status == UserStatus.WITHDRAWN.value:
            if not restore:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Account withdrawn; use restore=true to restore",
                )
            await restore_user(db, user)
            await db.commit()
            await db.refresh(user)
            if refresh_token:
                await upsert_user_token(db, user.id, provider_upper, refresh_token, None)
                await db.commit()
            return user, True
        # active
        if refresh_token:
            await upsert_user_token(db, user.id, provider_upper, refresh_token, None)
        await db.commit()
        await db.refresh(user)
        return user, False

    # 탈퇴 30일 이내 복구 가능
    if restore:
        log = await find_withdrawn_for_restore(db, provider_upper, oauth_id)
        if log:
            user = await db.get(User, log.user_id)
            if user:
                await restore_user(db, user, log=log)
                await db.commit()
                await db.refresh(user)
                if refresh_token:
                    await upsert_user_token(db, user.id, provider_upper, refresh_token, None)
                    await db.commit()
                    await db.refresh(user)
                return user, True

    # 회원 없음 → 404 (프론트에서 회원가입 플로우)
    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail="User not found; sign up required",
    )


async def register_after_social(
    db: AsyncSession,
    provider: str,
    oauth_id: str,
    *,
    firebase_uid: str | None = None,
    email: str | None = None,
    nickname: str | None = None,
    refresh_token: str = "",
) -> User:
    """소셜 로그인 404 후 회원가입: 사용자 생성 + user_tokens 저장"""
    existing = await get_user_by_provider_oauth(db, provider, oauth_id)
    if existing:
        return existing
    if firebase_uid:
        existing_f = await get_user_by_firebase_uid(db, firebase_uid)
        if existing_f:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="User already exists with this firebase_uid",
            )
    user = await create_user_social(
        db, provider, oauth_id,
        firebase_uid=firebase_uid,
        email=email,
        nickname=nickname,
    )
    await db.commit()
    await db.refresh(user)
    if refresh_token:
        await upsert_user_token(db, user.id, provider, refresh_token, None)
        await db.commit()
        await db.refresh(user)
    return user
