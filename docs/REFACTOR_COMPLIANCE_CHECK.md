# refactor.mdc 준수 점검 결과

> 앱 전체를 `.cursor/rules/refactor.mdc` 규칙에 따라 점검한 결과 (2025-02 기준)

---

## 1. 레이어드 아키텍처 준수 현황

### 1.1 목표 구조

```
UI/Screen → Controller → Service → Repository → External (ApiClient)
```

### 1.2 준수 중인 부분 ✅

| 구분 | 위치 | 비고 |
|------|------|------|
| Controller → Service | HomeController | PetService, RecommendationService, UserService, CampaignService |
| Controller → Service | ProductDetailController | ProductService, TrackingService |
| Controller → Service | PetProfileController | PetService |
| Controller → Service | MyController | PetService, RecommendationService |
| Controller → Service | BenefitsController | MissionService |
| Controller → Service | SectionController | SectionService |
| Service → Repository | ProductService, RecommendationService, PetService | Repository를 통한 데이터 접근 |
| Router Guard | router_guards.dart | OnboardingService로 결과만 조회 |

### 1.3 위반 사항 ❌

#### Controller → Repository 직접 참조 (Service를 거치지 않음)

| 위치 | 위반 내용 | 규칙 |
|------|----------|------|
| **PetUpdateController** | PetRepository, ProductRepository 직접 사용 | → PetService, ProductService 또는 별도 UseCase로 위임해야 함 |
| **WatchController** | TrackingRepository, ProductRepository 직접 사용 | → TrackingService, ProductService로 위임해야 함 |
| **RecommendationAnimationController** | ProductRepository 직접 사용 | → RecommendationService로 위임해야 함 |

#### UI/Screen → Repository 직접 참조

| 위치 | 위반 내용 | 규칙 |
|------|----------|------|
| **match_score_provider.dart** | productRepositoryProvider 직접 호출 | → ProductService 사용 (ProductService에 getProductMatchScore 있음) |

#### UI/Screen에서 Service 직접 호출 (FutureBuilder 등)

| 위치 | 패턴 | 규칙 준수 |
|------|------|----------|
| find_screen.dart | FutureBuilder + recommendationService.getRecommendationHistory | ⚠️ 화면이 Service 직접 호출 – Controller/Provider로 위임 권장 |
| recommendation_history_screen.dart | FutureBuilder + recommendationService.getRecommendationHistory | ⚠️ 동일 |
| home_screen.dart | FutureBuilder + onboardingService.isOnboardingCompleted | ✓ 라우팅/조건 판단용 서비스 조회는 허용 범위 |
| benefits_screen.dart | petService.getPrimaryPetSummary() 직접 호출 | ⚠️ 화면이 Service 직접 호출 – BenefitsController 확장 권장 |

---

## 2. OnboardingRepository 직접 사용

| 위치 | 위반 내용 | 규칙 |
|------|----------|------|
| **onboarding_flow.dart:110** | `OnboardingRepositoryImpl()` 직접 인스턴스화, `setOnboardingCompleted(true)` 호출 | → OnboardingService.setCompleted() 추가 후 Service 사용 |
| **onboarding_controller.dart:15** | `OnboardingRepositoryImpl()` 직접 인스턴스화 | → OnboardingService Provider 주입 사용 |
| **onboarding_service.dart:24** | Provider 내 `OnboardingRepositoryImpl()` 인스턴스화 | ⚠️ Provider에서 구현체 생성은 허용 범위 (Repository Provider 없음) |

---

## 3. 화면 책임 제한 (3가지)

### 3.1 준수하는 화면 ✅

- 대부분 화면: Controller/Provider watch 후 UI 렌더링, CTA 시 notifier 호출

### 3.2 비즈니스 로직이 UI에 있는 경우 ❌

| 위치 | 위반 내용 | 규칙 |
|------|----------|------|
| **recommendation_detail_screen.dart** | `_extractSafetyReasons()`, `_extractQualityReasons()` – matchReasons 파싱 로직 | 도메인 규칙은 Service/UseCase로 이동 권장 |

---

## 4. 컨트롤러(Notifier) 설계

### 4.1 준수 원칙

- 컨트롤러는 도메인 규칙을 갖지 않음
- 서비스 호출 + 결과를 상태에 바인딩하는 역할만 수행

### 4.2 위반 가능성 ⚠️

| 위치 | 내용 |
|------|------|
| **HomeController** | refreshPetSummary 내부에 프로필 변경 감지/오케스트레이션 로직 다수 – PetService로 일부 이전 완료, 남은 오케스트레이션은 컨트롤러 책임 범위 내로 보임 |

---

## 5. Provider 설계 (family, autoDispose)

### 5.1 잘 적용된 Provider ✅

| Provider | family | autoDispose |
|----------|--------|-------------|
| productDetailControllerProvider | ✓ (productId) | ✓ |
| petUpdateControllerProvider | ✓ (petId) | ✓ |
| sectionControllerProvider | ✓ (SectionType) | ✓ |
| recommendationAnimationControllerProvider | ✓ (PetSummaryDto) | ✓ |
| matchScoreProvider | ✓ (MatchScoreQueryKey) | ✓ |

### 5.2 family/autoDispose 미적용 Provider

| Provider | family | autoDispose | 비고 |
|----------|--------|-------------|------|
| homeControllerProvider | ✗ | ✗ | 전역 홈 상태로 역할상 적절 |
| watchControllerProvider | ✗ | ✗ | 전역 watch 상태 |
| benefitsControllerProvider | ✗ | ✗ | 전역 benefits 상태 |
| marketControllerV2Provider | ✗ | ✗ | 전역 market 상태 |
| myControllerProvider | ✗ | ✗ | 전역 my 상태 |

---

## 6. 에러 처리 일관화

### 6.1 현황

- `handleException()`: `core/utils/error_handler.dart`에 중앙 정의 ✅
- 일부 Controller/Service에서 사용
- 일부는 `catch`만 하고 SnackBar/print로 처리

### 6.2 권장

- 모든 `catch`에서 `handleException()` 사용
- 사용자 메시지/리커버리 액션은 SnackBarHelper 등으로 일원화

---

## 7. 라우터(GoRouter) 책임

### 7.1 준수 ✅

- `router_guards.dart`: OnboardingService 호출로 결과만 사용
- 경로 정의, Guard/Redirect만 담당
- 조건 판단은 서비스에서 수행

---

## 8. 서비스 레이어 구성

### 8.1 존재하는 서비스

| 서비스 | Repository 사용 | 비고 |
|--------|-----------------|------|
| ProductService | ProductRepository | ✓ |
| RecommendationService | ProductRepository | ✓ |
| PetService | PetRepository, ApiClient | ✓ (혼합 사용) |
| TrackingService | TrackingRepository, PetService | ✓ |
| OnboardingService | OnboardingRepository | ✓ |
| UserService | UserRepository | ✓ |
| CampaignService | CampaignRepository | ✓ |
| MissionService | MissionRepository | ✓ |
| SectionService | SectionRepository | ✓ |

### 8.2 ProductService 확장 필요

- `getProduct(productId)`: 상품 기본 정보 조회 – WatchController용
- 현재 ProductService는 `getProductDetailForDisplay`, `getProductMatchScore`만 제공

---

## 9. 우선순위별 수정 제안

### 우선순위 1: Controller → Repository 직접 참조 제거

1. **PetUpdateController**  
   - PetRepository.updatePet → PetService에 `updatePet()` 추가 후 위임  
   - ProductRepository.clearRecommendationCache → RecommendationService에 `clearCache(petId)` 추가 후 위임  

2. **WatchController**  
   - ProductRepository.getProduct → ProductService에 `getProduct(productId)` 추가 후 위임  
   - TrackingRepository는 TrackingService가 이미 래핑 → TrackingService 사용으로 전환  

3. **RecommendationAnimationController**  
   - ProductRepository → RecommendationService 사용으로 전환  

4. **match_score_provider**  
   - productRepository → productService 사용  

### 우선순위 2: Onboarding 직접 사용 정리

5. **onboarding_flow.dart**  
   - OnboardingService에 `setOnboardingCompleted(bool)` 추가  
   - `OnboardingRepositoryImpl()` 제거, OnboardingService 사용  

6. **onboarding_controller.dart**  
   - OnboardingRepositoryImpl 대신 OnboardingService Provider 주입  

### 우선순위 3: 화면에서 Service 직접 호출 정리

7. **find_screen.dart, recommendation_history_screen.dart**  
   - FutureBuilder + Service 호출을 Controller/Provider 기반으로 변경 검토  

8. **benefits_screen.dart**  
   - petService 직접 호출을 BenefitsController로 이전 검토  

### 우선순위 4: 도메인 로직 이전

9. **recommendation_detail_screen.dart**  
   - `_extractSafetyReasons`, `_extractQualityReasons` → RecommendationService 또는 별도 UseCase로 이동 검토  

### 우선순위 5: 에러 처리 통일

10. 모든 `catch`에서 `handleException()` 사용 및 SnackBarHelper로 사용자 피드백 일원화  

---

## 10. 요약

| 항목 | 상태 | 건수 |
|------|------|------|
| Controller → Repository 직접 참조 | ❌ | 4곳 |
| UI → Repository 직접 참조 | ❌ | 1곳 |
| OnboardingRepository 직접 사용 | ❌ | 2곳 |
| UI에서 Service 직접 호출 (FutureBuilder 등) | ⚠️ | 3곳 |
| UI 내 도메인 로직 | ❌ | 1곳 |
| Provider 설계 (family/autoDispose) | ✅ | 대부분 준수 |
| 라우터 가드 | ✅ | 준수 |
| 에러 처리 일관화 | ⚠️ | 부분적 |
