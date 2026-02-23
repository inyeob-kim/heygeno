# 회원가입/로그인 및 구독 모듈 (재사용 가이드)

이 문서는 pet-food-app 백엔드에 추가된 **인증·구독 모듈** 구조와 API, DB를 정리한 것입니다. 다른 프로젝트에서도 동일한 패턴으로 재사용할 수 있습니다.

## 1. 개요

- **인증**: 소셜 로그인(Google, Apple, Naver) + (선택) Firebase 이메일/비밀번호. `users` + `user_tokens` + `withdrawal_log`.
- **구독**: 인앱 구매(IOS/Android) 영수증 검증, `subscription_payments` + `users.plan_type`/`plan_expire_at`.

## 2. DB 테이블

### 2.1 users (확장)

| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | UUID | PK |
| provider | VARCHAR(50) | DEVICE, GOOGLE, APPLE, NAVER, EMAIL |
| provider_user_id | VARCHAR(255) | OAuth sub / device_uid |
| firebase_uid | VARCHAR(128) | UNIQUE, nullable |
| email | VARCHAR(255) | nullable |
| nickname | VARCHAR(50) | server_default='User' |
| timezone | VARCHAR(50) | |
| status | VARCHAR(20) | active, withdrawn, pending |
| withdrawn_at | TIMESTAMPTZ | nullable |
| plan_type | VARCHAR(20) | FREE, PRO |
| plan_expire_at | TIMESTAMPTZ | nullable |

- UNIQUE: (provider, provider_user_id), firebase_uid

### 2.2 user_tokens

- (user_id, provider) PK, refresh_token, access_token, token_updated_at
- FK user_id → users.id CASCADE

### 2.3 withdrawal_log

- id, user_id, deleted_at, archive_date, restored_at, reason, provider, provider_user_id, firebase_uid
- 30일 이내 복구 시 사용

### 2.4 subscription_payments

- id, user_id, transaction_id, platform(ios/android), product_id, amount, currency, payment_status(PAID/REFUNDED/FAILED), payment_date, expires_at, processed_at, last_verified_at, purchase_token, original_transaction_id, environment, raw_receipt
- UNIQUE: (platform, transaction_id)

## 3. 인증 API

### POST /api/v1/auth/social-login

- Body: `provider`, `id_token` (또는 Naver `access_token`), `refresh_token`, `restore`, `firebase_uid`, `email`, `nickname`
- 200: 로그인 성공 (restored 여부 포함)
- 404: 회원 없음 → 프론트에서 POST /auth/register
- 403: 탈퇴 계정 → `restore=true`로 재요청

### POST /api/v1/auth/register

- Body: `provider`, `id_token` 또는 `oauth_id`, `refresh_token`, `firebase_uid`, `email`, `nickname`
- 소셜 로그인 404 후 회원가입용

### POST /api/v1/auth/refresh

- Body: `refresh_token`, `provider`
- user_tokens에서 사용자 조회 후 로그인 상태 반환

## 4. 구독 API

### POST /api/v1/billing/verify?user_id={user_id}

- Body: `platform`, `product_id`, `receipt_or_token`, `transaction_id`, `original_transaction_id`, `amount`, `currency`
- 영수증 검증(현재 스텁) 후 subscription_payments UPSERT, users.plan_type/plan_expire_at 갱신
- Idempotent

### GET /api/v1/billing/me/entitlements?user_id={user_id}

- 응답: `pro`, `plan_type`, `plan_expire_at`

### GET /api/v1/billing/products

- 응답: `ios_product_id`, `android_product_id` (설정 또는 기본값)

## 5. 설정

- `.env`: `IOS_PRODUCT_ID`, `ANDROID_PRODUCT_ID` (선택)

## 6. 마이그레이션

- `alembic/versions/add_auth_and_subscription_module.py` 적용 후 사용

## 7. 프로덕션 시 주의

- **id_token 검증**: 현재 개발용으로 unverified decode. 프로덕션에서는 Google/Apple JWKS 또는 Firebase Admin SDK로 반드시 검증.
- **영수증 검증**: `_verify_receipt_stub`를 App Store Server API / Google Play Developer API 연동으로 교체.
