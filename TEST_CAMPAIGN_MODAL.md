# HOME_MODAL 캠페인 모달 테스트 가이드

## 1단계: DTO 파일 생성

```bash
cd frontend
dart run build_runner build --delete-conflicting-outputs
```

## 2단계: 백엔드 서버 실행 확인

백엔드 서버가 실행 중인지 확인:
```bash
# 백엔드 디렉토리에서
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

또는 Docker Compose 사용:
```bash
docker-compose up backend
```

## 3단계: HOME_MODAL 캠페인 생성

### 방법 1: 관리자 페이지 사용 (권장) ⭐

1. 관리자 페이지 접속: `http://localhost:3000` (또는 설정된 포트)
2. "이벤트 관리" 탭 클릭
3. 우측 상단 "새 캠페인 생성" 버튼 클릭
4. 다음 정보 입력:
   - **Campaign Key**: `test_home_modal_001` (고유한 키)
   - **Kind**: `NOTICE` 또는 `EVENT`
   - **Placement**: `HOME_MODAL` ⭐ (중요!)
   - **Template**: `image_top` 또는 `no_image`
   - **Priority**: `1` (낮을수록 먼저 표시)
   - **생성 즉시 활성화**: 체크
   - **시작일/종료일**: 현재 시간 이후로 설정
   - **제목**: "환영합니다! 🎉"
   - **설명**: "헤이제노에 오신 것을 환영합니다."
   - **이미지 URL**: (선택사항) 이미지 URL 입력
   - **CTA 버튼 텍스트**: "시작하기"
   - **딥링크 경로**: "/benefits"
5. "생성" 버튼 클릭

### 방법 2: API 직접 호출

관리자 API를 사용하여 테스트용 캠페인을 생성합니다.

### API 엔드포인트
```
POST http://localhost:8000/api/v1/admin/campaigns
```

### 요청 예시 (cURL)

```bash
curl -X POST "http://localhost:8000/api/v1/admin/campaigns" \
  -H "Content-Type: application/json" \
  -d '{
    "key": "test_home_modal_001",
    "kind": "NOTICE",
    "placement": "HOME_MODAL",
    "template": "image_top",
    "priority": 1,
    "is_enabled": true,
    "start_at": "2024-01-01T00:00:00Z",
    "end_at": "2025-12-31T23:59:59Z",
    "content": {
      "title": "환영합니다! 🎉",
      "description": "헤이제노에 오신 것을 환영합니다. 지금 바로 시작해보세요!",
      "image_url": "https://via.placeholder.com/400x200?text=Welcome",
      "cta": {
        "text": "시작하기",
        "deeplink": "/benefits"
      }
    },
    "rules": [],
    "actions": []
  }'
```

### 요청 예시 (Postman/Thunder Client)

**URL:** `POST http://localhost:8000/api/v1/admin/campaigns`

**Headers:**
```
Content-Type: application/json
```

**Body (JSON):**
```json
{
  "key": "test_home_modal_001",
  "kind": "NOTICE",
  "placement": "HOME_MODAL",
  "template": "image_top",
  "priority": 1,
  "is_enabled": true,
  "start_at": "2024-01-01T00:00:00Z",
  "end_at": "2025-12-31T23:59:59Z",
  "content": {
    "title": "환영합니다! 🎉",
    "description": "헤이제노에 오신 것을 환영합니다. 지금 바로 시작해보세요!",
    "image_url": "https://via.placeholder.com/400x200?text=Welcome",
    "cta": {
      "text": "시작하기",
      "deeplink": "/benefits"
    }
  },
  "rules": [],
  "actions": []
}
```

### 다른 예시 (이미지 없이)

```json
{
  "key": "test_home_modal_002",
  "kind": "EVENT",
  "placement": "HOME_MODAL",
  "template": "no_image",
  "priority": 2,
  "is_enabled": true,
  "start_at": "2024-01-01T00:00:00Z",
  "end_at": "2025-12-31T23:59:59Z",
  "content": {
    "title": "특별 이벤트",
    "description": "첫 추천 받고 포인트 받으세요!",
    "cta": {
      "text": "이벤트 참여하기",
      "deeplink": "/home"
    }
  },
  "rules": [],
  "actions": []
}
```

## 4단계: 프론트엔드 앱 실행

```bash
cd frontend
flutter run -d chrome
# 또는
flutter run -d ios
# 또는
flutter run -d android
```

## 5단계: 테스트 시나리오

### 시나리오 1: 기본 모달 표시
1. 앱 실행 후 홈 화면으로 이동
2. 펫 정보가 등록되어 있는 상태여야 함
3. 홈 화면 진입 시 자동으로 모달이 표시되어야 함
4. 모달 내용 확인:
   - 제목 표시
   - 설명 표시
   - 이미지 표시 (있는 경우)
   - CTA 버튼 표시

### 시나리오 2: 모달 닫기
1. 모달이 표시된 상태에서 "닫기" 버튼 클릭
2. 모달이 사라져야 함
3. 홈 화면이 정상적으로 보여야 함

### 시나리오 3: CTA 버튼 클릭
1. 모달의 CTA 버튼 클릭 (예: "시작하기")
2. 딥링크로 지정된 화면으로 이동해야 함 (예: `/benefits`)
3. 모달이 자동으로 닫혀야 함

### 시나리오 4: 여러 캠페인 우선순위
1. 여러 개의 `HOME_MODAL` 캠페인 생성 (다른 `priority` 값)
2. `priority`가 낮은 캠페인이 먼저 표시되어야 함
3. 모달을 닫으면 다음 캠페인이 표시되어야 함 (현재는 첫 번째만 표시)

## 6단계: 확인 사항

### 백엔드 API 확인
```bash
# 활성 캠페인 조회
curl "http://localhost:8000/api/v1/campaigns?placement=HOME_MODAL"
```

### 프론트엔드 로그 확인
앱 실행 시 콘솔에서 다음 로그를 확인:
```
[HomeController] 홈 모달 캠페인 로드 완료: X개
```

### 문제 해결

#### 모달이 표시되지 않는 경우
1. 백엔드 서버가 실행 중인지 확인
2. 캠페인이 활성화되어 있는지 확인 (`is_enabled: true`)
3. 현재 시간이 `start_at`과 `end_at` 사이인지 확인
4. `placement`가 정확히 `HOME_MODAL`인지 확인
5. 프론트엔드 콘솔에서 에러 로그 확인

#### 빌드 에러가 발생하는 경우
```bash
cd frontend
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## 참고사항

- 캠페인은 `priority` 값이 낮을수록 우선순위가 높습니다
- 현재는 첫 번째 캠페인만 표시되며, 여러 캠페인을 순차적으로 표시하려면 추가 구현이 필요합니다
- 모달은 홈 화면 진입 시 자동으로 표시됩니다
- 모달을 닫으면 현재 세션에서는 다시 표시되지 않습니다 (새로고침 필요)
