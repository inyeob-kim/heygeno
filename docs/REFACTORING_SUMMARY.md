# 리팩토링 변경 사항 상세 정리

## 📅 리팩토링 일시
2024년 (레이어드 아키텍처 기반 리팩토링)

## 🎯 목표
- 레이어드 아키텍처 원칙 준수 (UI → Domain → Data → External)
- Controllers에서 Repository 직접 호출 제거
- 비즈니스 로직을 Service 레이어로 이동
- 상태 관리 최적화 (autoDispose 적용)

---

## 📁 새로 생성된 파일

### 1. `frontend/lib/domain/services/recommendation_service.dart` ✨
**목적**: 추천 관련 비즈니스 로직을 담당하는 Domain Service

**주요 기능**:
- `getRecommendations()`: 추천 상품 조회 (forceRefresh 옵션 지원)
- `getRecommendationHistory()`: 추천 히스토리 조회

**변경 전**: Controllers에서 `ProductRepository` 직접 호출
**변경 후**: `RecommendationService`를 통해 추천 로직 처리

---

### 2. `frontend/lib/domain/services/campaign_service.dart` ✨
**목적**: 캠페인/미션 관련 비즈니스 로직을 담당하는 Domain Service

**주요 기능**:
- `getMissions()`: 미션 목록 조회 (MissionDto → MissionData 변환 포함)
- `getPointBalance()`: 포인트 잔액 조회
- `claimReward()`: 미션 보상 받기

**도메인 모델 추가**:
- `MissionData`: MissionDto를 도메인 모델로 변환 (BenefitsController에서 사용)

**변경 전**: `BenefitsController`에서 `MissionRepository` 직접 호출 및 DTO 변환
**변경 후**: `CampaignService`에서 DTO 변환 및 비즈니스 로직 처리

---

### 3. `frontend/lib/domain/services/user_service.dart` ✨
**목적**: 사용자 정보 조회를 담당하는 Domain Service

**주요 기능**:
- `getCurrentUser()`: 현재 사용자 정보 조회

**변경 전**: `HomeController`에서 `UserRepository` 직접 호출
**변경 후**: `UserService`를 통해 사용자 정보 조회

---

## 🔧 수정된 파일

### 4. `frontend/lib/domain/services/pet_service.dart` 🔄
**변경 사항**: 비즈니스 로직 메서드 추가

**추가된 메서드**:
```dart
bool hasProfileChanged(PetSummaryDto oldPet, PetSummaryDto newPet)
```
- 프로필 변경 감지 로직 (체중, 중성화, 나이 단계, 품종, 건강 고민, 알레르기 비교)
- `_listEquals()` 헬퍼 메서드 추가

**변경 전**: `HomeController._hasProfileChanged()` (Controller에 비즈니스 로직)
**변경 후**: `PetService.hasProfileChanged()` (Service로 이동)

---

### 5. `frontend/lib/features/home/presentation/controllers/home_controller.dart` 🔄
**변경 사항**: Repository 직접 호출 제거, Service 사용으로 변경

#### Import 변경
**변경 전**:
```dart
import '../../../../data/repositories/product_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import 'package:collection/collection.dart'; // ListEquality 사용
```

**변경 후**:
```dart
import '../../../../domain/services/recommendation_service.dart';
import '../../../../domain/services/user_service.dart';
// collection 패키지 제거
```

#### 생성자 변경
**변경 전**:
```dart
final ProductRepository _productRepository;
final UserRepository _userRepository;

HomeController(
  this._productRepository,
  this._petService,
  this._userRepository,
  this._ref,
)
```

**변경 후**:
```dart
final RecommendationService _recommendationService;
final UserService _userService;

HomeController(
  this._recommendationService,
  this._petService,
  this._userService,
  this._ref,
)
```

#### 메서드 변경

**1. `initialize()` 메서드**
- `_userRepository.getCurrentUser()` → `_userService.getCurrentUser()`

**2. `_loadRecommendations()` 메서드**
- `_productRepository.getRecommendations(petId, forceRefresh: force)` 
- → `_recommendationService.getRecommendations(petId: petId, forceRefresh: force)`

**3. `refreshPetSummary()` 메서드**
- `_hasProfileChanged(oldPetSummary, newPetSummary)` 
- → `_petService.hasProfileChanged(oldPetSummary, newPetSummary)`

**4. `_hasProfileChanged()` 메서드 삭제**
- 비즈니스 로직을 `PetService.hasProfileChanged()`로 이동

#### Provider 변경
**변경 전**:
```dart
final productRepository = ref.watch(productRepositoryProvider);
final userRepository = ref.watch(userRepositoryProvider);
return HomeController(productRepository, petService, userRepository, ref);
```

**변경 후**:
```dart
final recommendationService = ref.watch(recommendationServiceProvider);
final userService = ref.watch(userServiceProvider);
return HomeController(recommendationService, petService, userService, ref);
```

---

### 6. `frontend/lib/features/benefits/presentation/controllers/benefits_controller.dart` 🔄
**변경 사항**: Repository 직접 호출 제거, Service 사용으로 변경

#### Import 변경
**변경 전**:
```dart
import '../../../../data/repositories/mission_repository.dart';
```

**변경 후**:
```dart
import '../../../../domain/services/campaign_service.dart';
```

#### MissionData 모델 제거
- `MissionData` 클래스를 Controller에서 제거
- `CampaignService`로 이동 (도메인 모델로 정의)

#### 생성자 변경
**변경 전**:
```dart
final MissionRepository _missionRepository;
BenefitsController(this._missionRepository)
```

**변경 후**:
```dart
final CampaignService _campaignService;
BenefitsController(this._campaignService)
```

#### 메서드 변경

**1. `_initialize()` 메서드**
**변경 전**:
```dart
final results = await Future.wait([
  _missionRepository.getMissions(),
  _missionRepository.getPointBalance(),
]);
final missionDtos = results[0] as List<MissionDto>;
final missions = missionDtos.map((dto) => MissionData(...)).toList();
```

**변경 후**:
```dart
final results = await Future.wait([
  _campaignService.getMissions(),  // 이미 MissionData로 변환됨
  _campaignService.getPointBalance(),
]);
final missions = results[0] as List<MissionData>;
```

**2. `claimReward()` 메서드**
- `_missionRepository.claimReward()` → `_campaignService.claimReward()`

#### Provider 변경
**변경 전**:
```dart
final missionRepository = ref.watch(missionRepositoryProvider);
return BenefitsController(missionRepository);
```

**변경 후**:
```dart
final campaignService = ref.watch(campaignServiceProvider);
return BenefitsController(campaignService);
```

---

### 7. `frontend/lib/features/me/presentation/controllers/my_controller.dart` 🔄
**변경 사항**: Repository 직접 호출 제거, Service 사용으로 변경

#### Import 변경
**변경 전**:
```dart
import '../../../../data/repositories/product_repository.dart';
```

**변경 후**:
```dart
import '../../../../domain/services/recommendation_service.dart';
```

#### 생성자 변경
**변경 전**:
```dart
final ProductRepository _productRepository;
MyController(this._petService, this._productRepository)
```

**변경 후**:
```dart
final RecommendationService _recommendationService;
MyController(this._petService, this._recommendationService)
```

#### 메서드 변경

**`_loadRecommendations()` 메서드**
**변경 전**:
```dart
final recommendations = await _productRepository.getRecommendationHistory(
  petId,
  limit: 3,
);
```

**변경 후**:
```dart
final recommendations = await _recommendationService.getRecommendationHistory(
  petId: petId,
  limit: 3,
);
```

#### Provider 변경
**변경 전**:
```dart
final productRepository = ref.watch(productRepositoryProvider);
return MyController(petService, productRepository);
```

**변경 후**:
```dart
final recommendationService = ref.watch(recommendationServiceProvider);
return MyController(petService, recommendationService);
```

---

### 8. `frontend/lib/features/market/presentation/controllers/section_controller.dart` 🔄
**변경 사항**: 상태 관리 최적화 (autoDispose 적용)

#### Provider 변경
**변경 전**:
```dart
final sectionControllerProvider = StateNotifierProvider.family<
    SectionController, SectionState, SectionType>(...)
```

**변경 후**:
```dart
final sectionControllerProvider = StateNotifierProvider.autoDispose.family<
    SectionController, SectionState, SectionType>(...)
```

**효과**: 화면 이탈 시 자동으로 Provider가 해제되어 메모리 최적화

---

### 9. `frontend/lib/features/product_detail/presentation/controllers/product_detail_controller.dart` 🔄
**변경 사항**: 상태 관리 최적화 (autoDispose 적용)

#### Provider 변경
**변경 전**:
```dart
final productDetailControllerProvider =
    StateNotifierProvider.family<ProductDetailController, ProductDetailState, String>(...)
```

**변경 후**:
```dart
final productDetailControllerProvider =
    StateNotifierProvider.autoDispose.family<ProductDetailController, ProductDetailState, String>(...)
```

**효과**: 제품 상세 화면 이탈 시 자동으로 Provider가 해제되어 메모리 최적화

---

### 10. `frontend/lib/features/pet_update/presentation/controllers/pet_update_controller.dart` 🔄
**변경 사항**: 상태 관리 최적화 (autoDispose 적용)

#### Provider 변경
**변경 전**:
```dart
final petUpdateControllerProvider = 
    StateNotifierProvider.family<PetUpdateController, PetUpdateState, String>(...)
```

**변경 후**:
```dart
final petUpdateControllerProvider = 
    StateNotifierProvider.autoDispose.family<PetUpdateController, PetUpdateState, String>(...)
```

**효과**: 펫 업데이트 화면 이탈 시 자동으로 Provider가 해제되어 메모리 최적화

---

### 11. `frontend/lib/features/home/presentation/controllers/recommendation_animation_controller.dart` 🔄
**변경 사항**: 상태 관리 최적화 (autoDispose 적용)

#### Provider 변경
**변경 전**:
```dart
final recommendationAnimationControllerProvider = 
    StateNotifierProvider.family<...>(...)
```

**변경 후**:
```dart
final recommendationAnimationControllerProvider = 
    StateNotifierProvider.autoDispose.family<...>(...)
```

**효과**: 추천 애니메이션 화면 이탈 시 자동으로 Provider가 해제되어 메모리 최적화

---

## 📊 변경 통계

### 새로 생성된 파일
- **3개**: `recommendation_service.dart`, `campaign_service.dart`, `user_service.dart`

### 수정된 파일
- **8개**: Controllers 및 Services

### 코드 라인 수
- **추가**: 약 200줄 (새로운 Services)
- **삭제**: 약 150줄 (Controllers에서 중복 로직 제거)
- **순 증가**: 약 50줄

---

## ✅ 달성한 목표

### 1. 레이어드 아키텍처 준수 ✅
- **Before**: UI → Repository (직접 호출)
- **After**: UI → Service → Repository

### 2. 단일 책임 원칙 ✅
- Controllers: 상태 관리만 담당
- Services: 비즈니스 로직 담당
- Repositories: 데이터 접근만 담당

### 3. 코드 중복 제거 ✅
- DTO 변환 로직을 Service로 통합
- 에러 처리 로직을 Service로 통합
- 비즈니스 규칙을 Service로 통합

### 4. 메모리 최적화 ✅
- `autoDispose` 적용으로 화면 이탈 시 자동 해제
- 불필요한 Provider 유지 방지

### 5. 유지보수성 향상 ✅
- 비즈니스 로직이 Service에 집중되어 수정 용이
- 테스트 가능성 향상 (Service 단위 테스트 가능)

---

## 🔄 의존성 흐름 변경

### Before (리팩토링 전)
```
HomeController → ProductRepository (직접 호출)
HomeController → UserRepository (직접 호출)
BenefitsController → MissionRepository (직접 호출)
MyController → ProductRepository (직접 호출)
```

### After (리팩토링 후)
```
HomeController → RecommendationService → ProductRepository
HomeController → UserService → UserRepository
BenefitsController → CampaignService → MissionRepository
MyController → RecommendationService → ProductRepository
```

---

## 📝 주요 개선 사항

1. **비즈니스 로직 분리**: Controller에서 Service로 이동
2. **DTO 변환 중앙화**: Service에서 일괄 처리
3. **에러 처리 통일**: Service에서 일관된 에러 처리
4. **메모리 관리**: autoDispose로 자동 해제
5. **테스트 용이성**: Service 단위로 테스트 가능

---

## 🎯 다음 단계 (선택 사항)

1. **ProductService 생성**: 상품 조회/검색/필터 로직 통합
2. **SettingsService 생성**: 설정 관련 로직 통합
3. **에러 핸들링 개선**: 더 구체적인 에러 타입 정의
4. **캐싱 전략 개선**: Service 레벨에서 캐싱 정책 통일
