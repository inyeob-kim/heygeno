# refactor.mdc 준수 리팩터링 분석 보고서

> **목표**: 기존 기능/로직에 영향 없이 `.cursor/rules/refactor.mdc` 규칙 준수

---

## 1. 현재 아키텍처 요약

### 1.1 레이어 구조 현황

```
[현재 구조]
UI/Screen → Controller → Service or Repository (혼재)
                        ↘ Repository → ApiClient (External)
```

- **올바른 패턴**: HomeController → PetService, RecommendationService, UserService, CampaignService
- **위반 패턴**: ProductDetailController, PetProfileController → Repository 직접 참조
- **위반 패턴**: 일부 Screen → Repository/Service 직접 호출 (FutureBuilder 등)

### 1.2 규칙 대비 목표 구조

```
UI/Screen → Controller → Service → Repository → External (ApiClient)
```

---

## 2. 위반 사항 상세 분석

### 2.1 레이어 역참조 / 직접 참조 위반

| 위치 | 위반 내용 | 규칙 | 영향도 |
|------|----------|------|--------|
| `home_screen.dart:801` | `OnboardingRepositoryImpl()` 직접 인스턴스화 | UI → Repository 직접 참조 금지 | 높음 |
| `recommendation_detail_screen.dart:81` | `productRepositoryProvider` 직접 호출 | UI → Repository 직접 참조 금지 | 높음 |
| `product_detail_controller.dart` | `ProductRepository` 직접 의존 | Controller → Service → Repository 여야 함 | 중간 |
| `pet_profile_controller.dart` | `PetRepository` 직접 의존 | Controller → PetService → PetRepository | 중간 |

### 2.2 비즈니스 로직이 Controller/UI에 있는 경우

| 위치 | 위반 내용 | 규칙 | 권장 조치 |
|------|----------|------|-----------|
| `home_controller.dart:358-412` | `_hasProfileChanged()` 프로필 변경 감지 로직 | 도메인 규칙은 Service로 | → PetService로 이전 |
| `home_controller.dart:414-420` | `_listEqualsUnordered()` 비교 헬퍼 | 도메인 로직 | → PetService 또는 도메인 유틸로 이전 |
| `recommendation_detail_screen.dart:125-148` | `_extractSafetyReasons()` 매칭/안전 사유 추출 | UI에 비즈니스 로직 | → RecommendationService 또는 별도 UseCase로 이전 |

### 2.3 데이터 변환이 Controller에 있는 경우

| 위치 | 위반 내용 | 규칙 | 권장 조치 |
|------|----------|------|-----------|
| `product_detail_controller.dart:139-196` | `loadProduct()` 내 nutritionFacts 맵, IngredientAnalysisData, PriceHistoryItem, ClaimItem 매핑 | 데이터 변환은 Service/Repository | → ProductService 또는 ProductDetailUseCase로 이전 |

### 2.4 에러 처리 분산

| 현황 | 세부 |
|------|------|
| `handleException()` 중앙화 | `core/utils/error_handler.dart`에 존재 ✓ |
| 일관성 부족 | 일부는 handleException, 일부는 catch만, 일부는 SnackBar 직접 표시 |
| 권장 | 에러 → 사용자 메시지/리커버리 매핑을 한 곳에서 처리 (SnackBarHelper 활용 등) |

### 2.5 라우터/가드

| 항목 | 현황 | 규칙 준수 |
|------|------|----------|
| `router_guards.dart` | OnboardingService로 온보딩 완료 여부 확인 | ✓ 서비스에서 결과만 제공 |
| `route_validators.dart` | args/petSummary/recommendations 검증 | ✓ 라우트 수준 검증만 수행 |
| 조건 판단 → 라우팅 | 가드에서 서비스 호출 후 리다이렉트 | 규칙상 가벼운 조건만 허용, 현재 수준은 수용 가능 |

---

## 3. 서비스 레이어 누락/불일치

| 서비스 | 존재 | Repository 사용 | 비고 |
|--------|------|-----------------|------|
| PetService | ✓ | ApiClient 직접 사용 (PetRepository 미사용) | PetRepository와 역할 중복 |
| RecommendationService | ✓ | ProductRepository | ✓ |
| UserService | ✓ | UserRepository | ✓ |
| CampaignService | ✓ | (추정) CampaignRepository | ✓ |
| TrackingService | ✓ | TrackingRepository, PetService | ✓ |
| **ProductService** | **없음** | - | ProductDetailController가 ProductRepository 직접 사용 |
| OnboardingService | ✓ | (OnboardingRepository) | ✓ |
| SectionService | ✓ | SectionRepository | ✓ |

---

## 4. Provider 설계 현황

| Provider | family | autoDispose | 비고 |
|----------|--------|-------------|------|
| productDetailControllerProvider | ✓ (productId) | ✓ | 양호 |
| homeControllerProvider | ✗ | ✗ | 전역 홈 상태로 적절할 수 있음 |
| petProfileControllerProvider | ✗ | ✗ | petId family 고려 가능 |

---

## 5. 리팩터링 우선순위 및 수정 방향 (기능 변경 없이)

### 우선순위 1: 직접 참조 제거 (레이어 위반)

1. **HomeScreen (801행)**  
   - `OnboardingRepositoryImpl()` 제거  
   - OnboardingService에 `clearAll()` 또는 `resetOnboarding()` 추가  
   - 화면은 OnboardingService만 호출

2. **RecommendationDetailScreen (81행)**  
   - `ProductRepository.getRecommendations(generateExplanationOnly: true)` 호출 제거  
   - RecommendationService에 `generateRAGExplanations(petId, recommendations)` 추가  
   - 화면은 RecommendationService만 호출

3. **ProductDetailController**  
   - ProductRepository 직접 의존 제거  
   - ProductService 신설 → 상품 상세 조립, 매핑 로직 이관  
   - Controller는 ProductService, TrackingService만 사용

4. **PetProfileController**  
   - PetRepository 직접 의존 제거  
   - PetService에 `createPet(...)` 추가 (기존 PetRepository.createPet 래핑)  
   - Controller는 PetService만 사용

### 우선순위 2: 도메인 로직 이전

5. **HomeController `_hasProfileChanged()`, `_listEqualsUnordered()`**  
   - PetService 또는 `PetProfileComparator` 유틸로 이동  
   - 프로필 변경 여부 판단은 PetService 책임으로

6. **RecommendationDetailScreen `_extractSafetyReasons()`**  
   - RecommendationService 또는 별도 `RecommendationExplanationService`로 이동  
   - UI는 결과만 사용

### 우선순위 3: 데이터 변환 이전

7. **ProductDetailController.loadProduct() 내 변환**  
   - `detail` → IngredientAnalysisData, PriceHistoryItem, ClaimItem 변환을 ProductService로 이동  
   - Controller는 ProductService 결과를 그대로 state에 반영

### 우선순위 4: 에러 처리 일관화

8. **에러 처리 패턴 통일**  
   - 모든 catch에서 handleException 사용  
   - 사용자 메시지/리커버리(SnackBar, 재시도 등)는 ErrorHandler 또는 SnackBarHelper로 일원화

---

## 6. 리팩터링 시 기능 보존 체크리스트

리팩터링 시 아래를 반드시 검증:

- [ ] 온보딩 플로우 (초기 가입, 스킵, 재가입 시 초기화)
- [ ] 홈 초기화 (primary pet, 추천, 캠페인)
- [ ] 펫 프로필 생성
- [ ] 추천 로드/재추천/조건 조정
- [ ] 추천 상세 화면 RAG 설명 생성
- [ ] 상품 상세 (가격, 성분, 클레임, 찜)
- [ ] 가격 알림/트래킹
- [ ] 혜택/캠페인

---

## 7. 리팩터링 순서 제안 (안전한 적용)

1. **ProductService 도입**  
   - ProductRepository를 래핑하고 상세 조립/매핑 로직 추가  
   - ProductDetailController를 ProductService 사용으로 변경  
   - 기존 API/Repository 동작 유지

2. **OnboardingService 확장**  
   - `resetOnboarding()` 또는 `clearAll()` 추가  
   - HomeScreen에서 OnboardingRepositoryImpl 제거

3. **RecommendationService 확장**  
   - `generateRAGExplanations(...)` 추가  
   - RecommendationDetailScreen을 RecommendationService만 사용하도록 변경

4. **PetService 확장**  
   - `createPet()` 추가 (PetRepository 위임)  
   - `hasProfileChanged()` 등 프로필 비교 로직 이전  
   - PetProfileController, HomeController 정리

5. **에러 처리 일관화**  
   - catch 블록에서 handleException 사용로 통일  
   - SnackBar/재시도는 ErrorHandler/SnackBarHelper로 일원화

---

## 8. 요약

| 항목 | 위반 수 | 심각도 |
|------|--------|--------|
| UI → Repository 직접 참조 | 2곳 | 높음 |
| Controller → Repository 직접 참조 | 2곳 | 중간 |
| Controller/UI 내 도메인 로직 | 3곳+ | 중간 |
| 데이터 변환 위치 | 1곳 | 중간 |
| 에러 처리 불일치 | 다수 | 낮음 |

**핵심 원칙**:  
화면/프로바이더에 흩어진 API 호출·변환·예외 처리를 Repository/Service로 모아 UI를 단순화하고, 기존 동작은 그대로 유지하는 방향으로 진행.
