# 로그인 상태 복원 기능 설계

## 목표
앱 실행(콜드 스타트) 또는 Hot Restart 시, **저장된 access_token이 있으면** 로그인 화면(Start)을 건너뛰고 이전에 사용하던 화면(홈 또는 온보딩)으로 복원한다.

---

## 현재 상태 요약

| 구분 | 구현 여부 | 비고 |
|------|-----------|------|
| 토큰 저장 | ✅ | 로그인 시 `SecureStorage`에 `access_token` 저장 |
| API 요청 시 토큰 첨부 | ✅ | `AuthTokenInterceptor`가 매 요청마다 SecureStorage에서 읽어 Bearer 헤더 설정 |
| 앱 시작 시 토큰 복원(화면 분기) | ❌ | `InitialSplashScreen`이 항상 3초 후 **Start**로만 이동 |

→ 토큰은 유지되지만, **화면 흐름이 “이미 로그인됨”을 반영하지 않음.**

---

## 설계 개요

- **진입점**: `InitialSplashScreen`의 `_checkAndNavigate()` (스플래시 3초 대기 후 실행되는 로직).
- **판단 순서**:
  1. **토큰 없음** → 기존처럼 `Start`로 이동.
  2. **토큰 있음** → “로그인된 사용자 복원” 플로우 진입:
     - 서버에 펫 목록 등으로 “온보딩 완료 여부” 동기화 후,
     - 온보딩 완료 → **Home**, 미완료 → **Onboarding**으로 이동.

---

## 상세 설계

### 1. 진입점: `InitialSplashScreen._checkAndNavigate()`

**위치**: `lib/features/onboarding/presentation/screens/initial_splash_screen.dart`

**로직 (의사코드)**:

```
await 최소 3초 대기
if (!mounted) return

authRepo = ref.read(authRepositoryProvider)
hasToken = await authRepo.hasAccessToken()

if (!hasToken) {
  context.go(RoutePaths.start)
  return
}

// 토큰 있음 → 복원
onboardingService = ref.read(onboardingServiceProvider)
goHome = await onboardingService.shouldGoToHomeAfterLogin()
if (!mounted) return
context.go(goHome ? RoutePaths.home : RoutePaths.onboarding)
```

**설명**:
- `hasAccessToken()`: SecureStorage에 access_token 존재 여부만 확인 (동기화된 저장소 읽기).
- `shouldGoToHomeAfterLogin()`: 이미 로그인 직후에 사용 중인 메서드.  
  - 서버에 펫 목록 조회(`getAllPetSummaries`) → 펫 있으면 온보딩 완료로 간주하고 `setOnboardingCompleted(true)` 호출 후 `true` 반환, 없으면 `false` 반환.  
  - 복원 시에도 “서버 기준으로 온보딩 완료 여부를 맞추고, 홈/온보딩 중 어디로 갈지” 결정하는 데 그대로 사용 가능.

**의존성**:
- `authRepositoryProvider` (이미 존재)
- `onboardingServiceProvider` (이미 존재)  
→ `InitialSplashScreen`이 `ConsumerStatefulWidget`이므로 `ref.read`로 접근 가능.

---

### 2. 토큰은 있지만 만료된 경우 (401)

- `shouldGoToHomeAfterLogin()` 내부에서 `_petService.getAllPetSummaries()` 호출 시, 토큰 만료면 서버가 401을 반환할 수 있음.
- **1차 구현**: 401이 나면 예외로 전파되고, `_checkAndNavigate()`에서 `catch` 후 **Start로 이동**하도록 처리.  
  (사용자는 다시 로그인 화면에서 재로그인하게 됨.)
- **선택(추후)**: 401 수신 시 전역에서 `AuthRepository.signOut()`으로 토큰 삭제 후 Start 리다이렉트(예: 인터셉터에서 401 처리)를 두면, “만료된 토큰으로 인한 복원 실패”를 일관되게 처리할 수 있음.  
  → 이번 설계에서는 “복원 실패 시 Start로 보내기”만 명시하고, 전역 401 처리 여부는 별도 이슈로 둠.

---

### 3. 라우터 가드 (기존 유지)

- `onboardingGuard`: **온보딩 완료 여부**만 보고 리다이렉트 (인증 여부는 보지 않음).
- 로그인 상태 복원은 **InitialSplash에서 한 번만** “토큰 있으면 Start 건너뛰기”를 수행하고,  
  이후에는 기존처럼 온보딩 완료 여부에 따라 가드가 동작하면 됨.
- **추가 옵션(나중에)**: “인증 필수 라우트”(예: /me, /settings)에 대해 “토큰 없으면 Start로” 같은 **auth guard**를 두고 싶다면, `redirect`에서 `hasAccessToken()`을 비동기로 확인하는 방식으로 확장 가능.  
  → 현재 설계 범위 밖.

---

### 4. 데이터 흐름 요약

```
[앱 시작]
  → InitialSplash (3초)
  → _checkAndNavigate()
       ├─ hasAccessToken() == false  → context.go(Start)
       └─ hasAccessToken() == true
            → shouldGoToHomeAfterLogin()  // API 호출, 온보딩 상태 동기화
                 ├─ true  → context.go(Home)
                 └─ false → context.go(Onboarding)
```

---

### 5. 예외·에러 처리

| 상황 | 처리 |
|------|------|
| `hasAccessToken()` 예외 | catch 후 `context.go(Start)` (안전하게 로그인 화면으로) |
| `shouldGoToHomeAfterLogin()` 예외 (네트워크, 401 등) | catch 후 `context.go(Start)` |
| `mounted` false | 모든 await 직후 확인 후 early return, 네비게이션 생략 |

---

### 6. 테스트 시나리오 (검증용)

1. **토큰 없이 실행** → 스플래시 후 Start.
2. **토큰 있고, 서버에 펫 있음** → 스플래시 후 Home.
3. **토큰 있고, 서버에 펫 없음** → 스플래시 후 Onboarding.
4. **토큰 있지만 만료(401)** → 스플래시 후 Start (재로그인 유도).
5. **Hot Restart (토큰 있는 상태)** → 스플래시 후 Home 또는 Onboarding (2·3과 동일).

---

### 7. 수정 대상 파일

| 파일 | 변경 내용 |
|------|------------|
| `initial_splash_screen.dart` | `_checkAndNavigate()` 내부에 `hasAccessToken()` 분기 추가, 토큰 있으면 `shouldGoToHomeAfterLogin()` 호출 후 Home/Onboarding으로 이동, 예외 시 Start |

---

### 8. (선택) 추후 개선

- **전역 401 처리**: API 인터셉터에서 401 시 토큰 삭제 + Start 리다이렉트 또는 이벤트 발행.
- **Auth guard**: 특정 경로는 “토큰 없으면 Start”로 보내는 redirect 추가.
- **토큰 갱신**: refresh_token 도입 시 복원 전에 갱신 시도 후 실패 시에만 Start.

이 설계대로 구현하면 “앱 실행 시 로그인 상태 유지(복원)” 기능이 동작하며, Hot Restart 시에도 Start 대신 Home/Onboarding으로 바로 진입하게 된다.
