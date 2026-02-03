# 홈 화면 Empty State 개편 요약

## 1) 문제 원인 요약

**현재 문제**: 온보딩 완료 후에도 홈 화면이 "프로필 없음(Empty State)"처럼 보여 혼란을 줌

**원인 분석**:
- `HomeController`가 `currentPetIdProvider`에 의존하는데, 이 값이 `null`로 초기화됨
- 온보딩 완료 시 서버에 pet이 저장되지만, 로컬 상태에 반영되지 않음
- 홈 진입 시 서버에서 primary pet을 조회하는 로직이 없음
- 상태 분기가 명확하지 않아 (A/B/C) 혼란 발생

## 2) 상태 다이어그램

```
앱 시작/홈 진입
    ↓
[로딩 중] (HomeStateType.loading)
    ↓
onboarding_completed 체크
    ↓
┌─────────────────┬─────────────────┐
│   false (A)     │    true (B/C)   │
│                 │                 │
│ /onboarding로   │ primary pet 조회│
│ 리다이렉트      │                 │
└─────────────────┘                 │
                                    ↓
                        ┌───────────┴───────────┐
                        │                       │
                    [pet 있음] (B)        [pet 없음] (C)
                        │                       │
                        │                       │
            ┌───────────┴───────────┐           │
            │                       │           │
    추천 로드 중          추천 완료      Empty State
    (스켈레톤)           (정상 홈)      (프로필 만들기)
```

**상태 정의**:
- **A**: `onboarding_completed = false` → `/onboarding` 리다이렉트
- **B**: `onboarding_completed = true` AND `primary pet 존재` → 정상 홈 (내 아이 카드 + 추천)
- **C**: `onboarding_completed = true` BUT `pet 없음` → Empty State (프로필 만들기)

## 3) Flutter 위젯 구조

```
HomeScreen (ConsumerStatefulWidget)
├── AppScaffold
│   ├── AppBar (동적 타이틀: "오늘, {펫이름}에게 딱 맞는 사료 🐾")
│   └── Body
│       ├── [로딩] LoadingWidget
│       ├── [B 상태] _buildHomeWithPet()
│       │   ├── PetCard (내 아이 카드)
│       │   ├── RecommendationCard (추천 Top1)
│       │   └── AppPrimaryButton ("맞춤 사료 보러가기")
│       ├── [C 상태] TodayEmptyState
│       │   └── AppPrimaryButton ("프로필 만들기")
│       └── [에러] EmptyStateWidget
│
HomeController (StateNotifier)
├── initialize() → PetService.getPrimaryPetSummary()
│   ├── 성공 → B 상태 + 추천 로드
│   └── 실패/없음 → C 상태
└── refreshRecommendations()
```

## 4) 핵심 코드 스니펫

### 4-1) GoRouter Redirect 가드

```dart
// frontend/lib/app/router/app_router.dart
GoRouter _createRouter(Ref ref) {
  return GoRouter(
    redirect: (context, state) async {
      final onboardingRepo = OnboardingRepositoryImpl();
      final isCompleted = await onboardingRepo.isOnboardingCompleted();
      final location = state.uri.path;

      // A) 온보딩 미완료 → 온보딩으로 리다이렉트
      if (!isCompleted) {
        if (location != RoutePaths.onboarding) {
          return RoutePaths.onboarding;
        }
        return null;
      }

      // B) 온보딩 완료 → 온보딩 화면 접근 시 홈으로 리다이렉트
      if (isCompleted && location == RoutePaths.onboarding) {
        return RoutePaths.home;
      }

      return null;
    },
    // ...
  );
}
```

### 4-2) HomeScreen build() 분기

```dart
// frontend/lib/features/home/presentation/screens/home_screen.dart
Widget _buildBody(BuildContext context, HomeState state) {
  // A) 로딩 중
  if (state.isLoading) {
    return const LoadingWidget();
  }

  // B) Primary Pet 존재 → 정상 홈
  if (state.hasPet) {
    return _buildHomeWithPet(context, state);
  }

  // C) Pet 없음 → Empty State
  if (state.isNoPet) {
    return _buildEmptyState(context);
  }

  // 에러 상태
  if (state.isError) {
    return EmptyStateWidget(/* ... */);
  }

  return const SizedBox.shrink();
}
```

### 4-3) PetSummary 모델/서비스 인터페이스

```dart
// frontend/lib/data/models/pet_summary_dto.dart
class PetSummaryDto {
  final String petId;
  final String name;
  final String species;
  final String? ageStage;
  final int? ageMonths;
  final double weightKg;
  final List<String> healthConcerns;
  final String? photoUrl;

  String get ageSummary => /* 나이 요약 텍스트 */;
  String get healthSummary => /* 건강 포인트 요약 */;
}

// frontend/lib/domain/services/pet_service.dart
class PetService {
  /// Primary Pet 요약 정보 조회 (서버 우선, 실패 시 로컬 캐시)
  Future<PetSummaryDto?> getPrimaryPetSummary() async {
    try {
      // 1. 서버에서 primary pet 조회
      final response = await _apiClient.get('${Endpoints.pets}/primary');
      if (response.data != null) {
        final pet = PetSummaryDto.fromJson(response.data);
        // 로컬 캐시에 저장
        await _saveToCache(pet);
        return pet;
      }
    } catch (e) {
      // 네트워크 오류: 로컬 캐시 fallback
      return await _getCachedPetSummary();
    }
    return null;
  }
}
```

### 4-4) HomeController initialize()

```dart
// frontend/lib/features/home/presentation/controllers/home_controller.dart
Future<void> initialize() async {
  state = state.copyWith(stateType: HomeStateType.loading);

  try {
    // 1. Primary Pet 조회
    final petSummary = await _petService.getPrimaryPetSummary();

    if (petSummary == null) {
      // C 상태: pet 없음
      state = state.copyWith(stateType: HomeStateType.noPet);
      return;
    }

    // 2. Pet ID를 provider에 저장
    _ref.read(currentPetIdProvider.notifier).state = petSummary.petId;

    // 3. B 상태: pet 존재 → 추천 로드
    state = state.copyWith(
      stateType: HomeStateType.hasPet,
      petSummary: petSummary,
      isLoadingRecommendations: true,
    );

    // 4. 추천 로드
    await _loadRecommendations(petSummary.petId);
  } catch (e) {
    state = state.copyWith(
      stateType: HomeStateType.error,
      error: failure.message,
    );
  }
}
```

## 5) 체크리스트 (테스트 시나리오)

### ✅ 필수 테스트 시나리오

1. **가입 직후 홈 진입**
   - [ ] 온보딩 완료 → 홈 화면으로 자동 이동
   - [ ] "오늘, {펫이름}에게 딱 맞는 사료 🐾" 타이틀 표시
   - [ ] 내 아이 카드 표시 (이름, 나이, 몸무게, 건강 포인트)
   - [ ] 추천 카드 로딩 → 추천 데이터 표시

2. **앱 재시작 후 홈 진입**
   - [ ] 로컬 캐시에서 primary pet 조회 성공
   - [ ] 서버 조회 실패해도 캐시로 홈 표시
   - [ ] 추천 데이터 새로고침 동작

3. **Pet 존재/없음 분기**
   - [ ] Pet 있음 → B 상태 (정상 홈)
   - [ ] Pet 없음 → C 상태 (Empty State: "프로필이 아직 없어요. 30초면 끝나요 🐶🐱")
   - [ ] "프로필 만들기" 버튼 클릭 → `/pet-profile` 이동

4. **네트워크 실패 시 fallback**
   - [ ] 서버 조회 실패 → 로컬 캐시 사용
   - [ ] 캐시도 없으면 → C 상태 (Empty State)
   - [ ] 에러 메시지 표시 및 "다시 시도" 버튼 동작

5. **온보딩 미완료 시 가드**
   - [ ] `/home` 접근 시 `/onboarding`으로 리다이렉트
   - [ ] 다른 탭 접근 시도도 `/onboarding`으로 리다이렉트

6. **온보딩 완료 후 온보딩 화면 접근**
   - [ ] `/onboarding` 접근 시 `/home`으로 리다이렉트

7. **추천 데이터 로딩 상태**
   - [ ] 로딩 중: "분석 중..." 스켈레톤 표시
   - [ ] 로딩 완료: 추천 Top1 카드 표시
   - [ ] 추천 없음: "추천 준비 중" 메시지

8. **CTA 버튼 동작**
   - [ ] "맞춤 사료 보러가기" → 추천 Top1 상품 상세 화면 이동
   - [ ] "프로필 수정" → `/pet-profile` 이동
   - [ ] Pull-to-refresh → 추천 데이터 새로고침

## 변경된 파일 목록

1. **새로 생성**:
   - `frontend/lib/data/models/pet_summary_dto.dart`
   - `frontend/lib/domain/services/pet_service.dart`
   - `frontend/lib/features/home/presentation/widgets/pet_card.dart`
   - `frontend/lib/features/home/presentation/widgets/recommendation_card.dart`

2. **수정**:
   - `frontend/lib/core/storage/storage_keys.dart` (primary_pet_id, primary_pet_summary 추가)
   - `frontend/lib/core/network/endpoints.dart` (primaryPet 엔드포인트 추가)
   - `frontend/lib/features/home/presentation/controllers/home_controller.dart` (상태 분기 리팩터링)
   - `frontend/lib/features/home/presentation/screens/home_screen.dart` (UI 개편)
   - `frontend/lib/features/home/presentation/widgets/today_empty_state.dart` (문구 변경)
   - `frontend/lib/app/router/app_router.dart` (redirect 가드 추가)

## 다음 단계 (선택)

- [ ] 추천 이유(reasons) 필드 추가 (서버 API 확장 필요)
- [ ] "대표 사료 둘러보기" 기능 구현
- [ ] 추천 목록 화면 구현
- [ ] 프로필 수정 후 홈 자동 새로고침
