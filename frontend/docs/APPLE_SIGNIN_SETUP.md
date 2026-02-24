# Apple 로그인 설정 가이드

앱에서 **Sign in with Apple**이 동작하려면 아래를 직접 설정해야 합니다.

---

## 1. Apple Developer (developer.apple.com)

1. **Apple Developer Program** 가입 (유료, 연 $99)
2. **Certificates, Identifiers & Profiles** → **Identifiers** 이동
3. 앱의 **App ID** 선택 (또는 새로 생성)
   - Bundle ID 예: `com.yourcompany.petFoodApp`
4. 해당 App ID에 **Sign in with Apple** capability **체크** 후 저장
5. **(선택)** 웹/Android용 Apple 로그인을 쓸 계획이면 **Services ID**도 생성 후 설정

---

## 2. Xcode (iOS 앱)

1. `frontend/ios/Runner.xcworkspace` 를 Xcode로 열기
2. 왼쪽에서 **Runner** 프로젝트 선택 → **Signing & Capabilities** 탭
3. **+ Capability** 클릭 → **Sign in with Apple** 추가
4. 저장하면 `Runner/Runner.entitlements` 파일이 생성/수정됨  
   - 내용에 `com.apple.developer.applesignin` (Default) 가 들어가면 됨

**직접 entitlements 파일 쓰는 경우** (이미 있는 경우):

- `ios/Runner/Runner.entitlements` 에 아래가 있어야 함:

```xml
<key>com.apple.developer.applesignin</key>
<array>
  <string>Default</string>
</array>
```

---

## 3. 백엔드 (선택, 프로덕션 권장)

- 현재는 id_token을 **서명 검증 없이** decode만 해서 `sub`(Apple 사용자 ID)를 쓰고 있음
- **프로덕션**에서는 Apple 공개키(JWKS)로 서명 검증을 추가하는 것이 안전함  
  - 예: `https://appleid.apple.com/auth/keys` 에서 JWKS 받아와서 id_token 검증

`.env` 에 별도로 넣어야 할 값은 **없습니다**. (Google처럼 client id 설정 불필요)

---

## 4. 테스트

1. **실기기**에서 실행 (시뮬레이터는 Sign in with Apple이 제한적일 수 있음)
2. Start 화면에서 **Continue with Apple** 탭
3. Apple ID로 로그인 → 앱에서 로그인/회원가입 완료되는지 확인

---

## 요약 체크리스트

| 단계 | 할 일 | 완료 |
|------|--------|------|
| 1 | Apple Developer에서 App ID에 **Sign in with Apple** 켜기 | ☐ |
| 2 | Xcode에서 Runner에 **Sign in with Apple** Capability 추가 | ☐ |
| 3 | 실기기로 **Continue with Apple** 동작 확인 | ☐ |

코드 쪽 구현은 이미 되어 있으므로, **1번·2번만 하면** Apple 로그인을 사용할 수 있습니다.
