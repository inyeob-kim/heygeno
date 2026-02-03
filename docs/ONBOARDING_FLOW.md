# 🐾 HeyZeno 회원가입 플로우 정리

**현재 구현된 온보딩/회원가입 프로세스 전체 정리**

---

## 📋 목차

1. [전체 플로우 개요](#1-전체-플로우-개요)
2. [단계별 상세 설명](#2-단계별-상세-설명)
3. [데이터 저장 구조](#3-데이터-저장-구조)
4. [상태 관리](#4-상태-관리)
5. [완료 조건 및 검증](#5-완료-조건-및-검증)
6. [재진입 시 동작](#6-재진입-시-동작)
7. [라우팅 및 네비게이션](#7-라우팅-및-네비게이션)

---

## 1. 전체 플로우 개요

### 플로우 다이어그램

```
[앱 시작]
    ↓
[OnboardingWrapper 초기화]
    ↓
[OnboardingController 생성]
    ↓
[_loadSavedData() 실행]
    ├─ 마지막 단계 로드
    ├─ 닉네임 로드
    └─ 프로필 초안 로드
    ↓
[저장된 단계가 있으면?]
    ├─ YES → 해당 단계로 복귀
    └─ NO → Step 1부터 시작
    ↓
┌─────────────────────────┐
│  Step 1: 닉네임 입력    │
│  - 닉네임 (2~12자)      │
└───────────┬─────────────┘
            ↓
┌─────────────────────────┐
│  Step 2: 아이 이름      │
│  - 반려동물 이름 (1~20자)│
└───────────┬─────────────┘
            ↓
┌─────────────────────────┐
│  Step 3: 종 선택        │
│  - 강아지 / 고양이      │
└───────────┬─────────────┘
            ↓
┌─────────────────────────┐
│  Step 4: 나이 정보      │
│  - 생년월일 / 대략 나이 │
└───────────┬─────────────┘
            ↓
        ┌───┴───┐
        │       │
    [강아지] [고양이]
        │       │
        ↓       ↓
┌──────────┐   ┌──────────┐
│ Step 5:  │   │ Step 6:  │
│ 품종 선택│   │ 성별+중성│
└────┬────┘   └────┬────┘
     │             │
     └──────┬──────┘
            ↓
┌─────────────────────────┐
│  Step 6/7: 성별+중성화   │
│  - 성별 (남/여)         │
│  - 중성화 (예/아니오/모름)│
└───────────┬─────────────┘
            ↓
┌─────────────────────────┐
│  Step 7/8: 몸무게       │
│  - 몸무게 (0.1~99.9kg) │
└───────────┬─────────────┘
            ↓
┌─────────────────────────┐
│  Step 8/9: 비만도 (BCS) │
│  - 체형 점수 (1~9)      │
└───────────┬─────────────┘
            ↓
┌─────────────────────────┐
│  Step 9/10: 건강 고민   │
│  - 다중 선택 (최소 1개) │
└───────────┬─────────────┘
            ↓
┌─────────────────────────┐
│  Step 10/11: 음식 알레르기│
│  - 다중 선택 (최소 1개) │
└───────────┬─────────────┘
            ↓
┌─────────────────────────┐
│  Step 11/12: 사진 업로드│
│  - 선택 사항            │
└───────────┬─────────────┘
            ↓
    [헤이제노 시작하기 버튼]
            ↓
    [completeOnboarding() 실행]
            ├─ Device UID 생성/확인
            └─ onboarding_completed = true 저장
            ↓
    [GoRouter: /home으로 이동]
            ↓
    [메인 홈 화면]
```

---

## 2. 단계별 상세 설명

### Step 1: 닉네임 입력 (Welcome + Nickname)

**화면**: `Step01WelcomeNicknameScreen`

**입력 데이터**:
- `nickname`: String (2~12자)

**Validation**:
- 최소 2자, 최대 12자
- 공백 제거 후 검증

**저장 시점**:
- "다음" 버튼 클릭 시 `saveNickname()` 호출
- Secure Storage에 `draft_nickname` 저장

**다음 단계**: Step 2 (Pet Name)

---

### Step 2: 아이 이름 (Pet Name)

**화면**: `Step02PetNameScreen`

**입력 데이터**:
- `name`: String (1~20자)

**Validation**:
- 비어있지 않아야 함
- 최대 20자

**저장 시점**:
- "다음" 버튼 클릭 시 `saveProfile()` 호출
- `PetProfileDraft`에 저장

**다음 단계**: Step 3 (Species)

---

### Step 3: 종 선택 (Species Selection)

**화면**: `Step03SpeciesSelectionScreen`

**입력 데이터**:
- `species`: String ('dog' | 'cat')

**선택지**:
- 강아지 🐶
- 고양이 🐱

**저장 시점**:
- 종 선택 즉시 `saveProfile()` 호출
- "다음" 버튼으로 다음 단계 이동

**다음 단계**: Step 4 (Birth Mode)

---

### Step 4: 나이 정보 (Birth Mode)

**화면**: `Step04BirthModeScreen`

**입력 데이터**:
- `birthMode`: String ('exactBirthdate' | 'approxAge')
- `birthdate`: DateTime? (birthMode == 'exactBirthdate'일 때)
- `ageYears`: int? (birthMode == 'approxAge'일 때, 0~20)
- `ageMonths`: int? (birthMode == 'approxAge'일 때, 0~11)

**선택 모드**:
1. **생년월일 알아요** 📅
   - CupertinoDatePicker로 생년월일 선택
   - 최대 20년 전까지

2. **대략적인 나이만 알아요** 🎈
   - 연령/개월 스테퍼로 입력
   - 연령: 0~20살
   - 개월: 0~11개월

**저장 시점**:
- 모드 선택 즉시 저장
- 날짜/나이 입력 시 즉시 저장

**다음 단계**: 
- 강아지: Step 5 (Breed)
- 고양이: Step 6 (Sex & Neutered)

---

### Step 5: 품종 선택 (Breed Selection) - 강아지만

**화면**: `Step05BreedSelectionScreen`

**입력 데이터**:
- `breed`: String?

**기능**:
- 검색 바로 품종 검색
- 인기 품종 상단 고정
- 전체 품종 목록
- "믹스/잘 모르겠어요" 옵션

**저장 시점**:
- 품종 선택 즉시 `saveProfile()` 호출

**다음 단계**: Step 6 (Sex & Neutered)

**참고**: 고양이일 경우 이 단계는 자동으로 건너뜀

---

### Step 6: 성별 + 중성화 (Sex & Neutered)

**화면**: `Step06SexNeuteredScreen`

**입력 데이터**:
- `sex`: String ('male' | 'female')
- `neutered`: String ('yes' | 'no' | 'unknown')

**선택지**:
- **성별**: 남아 ♂️ / 여아 ♀️
- **중성화**: 했어요 / 안 했어요 / 잘 모르겠어요

**저장 시점**:
- 각 선택 즉시 `saveProfile()` 호출

**다음 단계**: Step 7 (Weight)

---

### Step 7: 몸무게 (Weight)

**화면**: `Step07WeightScreen`

**입력 데이터**:
- `weightKg`: double (0.1~99.9)

**입력 방식**:
- 큰 숫자 표시 (예: "3.5kg")
- 빠른 조절 버튼 (-0.1kg / +0.1kg)
- 커스텀 숫자 패드

**저장 시점**:
- 숫자 입력 시 즉시 저장

**다음 단계**: Step 8 (Body Condition)

---

### Step 8: 비만도 (Body Condition Score)

**화면**: `Step08BodyConditionScreen`

**입력 데이터**:
- `bodyConditionScore`: int (1~9)

**입력 방식**:
- 슬라이더 (1~9, 8단계)
- 캐릭터 실루엣 애니메이션 (BCS에 따라 크기 변화)
- 첫 선택 시 하트 팝업 애니메이션
- 구간별 피드백 텍스트:
  - 1~3: "조금 마른 편이에요"
  - 4~6: "딱 좋아요! 💚"
  - 7~9: "조금 관리해볼까요?"

**저장 시점**:
- 슬라이더 변경 시 즉시 저장

**다음 단계**: Step 9 (Health Concerns)

---

### Step 9: 건강 고민 (Health Concerns)

**화면**: `Step09HealthConcernsScreen`

**입력 데이터**:
- `healthConcerns`: Set<String> (최소 1개)

**선택지**:
- 없어요 (독점 옵션)
- 알레르기
- 장/소화
- 치아/구강
- 비만
- 호흡기
- 피부/털
- 관절
- 눈/눈물
- 신장/요로
- 심장
- 노령

**로직**:
- "없어요" 선택 시 나머지 자동 해제
- 다른 항목 선택 시 "없어요" 자동 해제
- 다중 선택 가능

**저장 시점**:
- 선택 변경 시 즉시 저장

**다음 단계**: Step 10 (Food Allergies)

---

### Step 10: 음식 알레르기 (Food Allergies)

**화면**: `Step10FoodAllergiesScreen`

**입력 데이터**:
- `foodAllergies`: Set<String> (최소 1개)

**선택지**:
- 없어요 (독점 옵션)
- 소고기
- 닭고기
- 돼지고기
- 오리고기
- 양고기
- 생선
- 계란
- 유제품
- 밀/글루텐
- 옥수수
- 콩
- 기타 (텍스트 입력 필드)

**로직**:
- "없어요" 선택 시 나머지 자동 해제
- "기타" 선택 시 텍스트 입력 필드 표시
- 기타 텍스트 입력 시 자동으로 "기타" 항목 추가

**저장 시점**:
- 선택 변경 시 즉시 저장
- 기타 텍스트 입력 시 즉시 저장

**다음 단계**: Step 11 (Photo Upload)

---

### Step 11: 사진 업로드 (Photo Upload)

**화면**: `Step11PhotoUploadScreen`

**입력 데이터**:
- `photoUrl`: String? (선택 사항)

**기능**:
- 갤러리에서 사진 선택
- 카메라로 사진 촬영
- 사진 미리보기 (원형, 200x200)
- 사진 삭제
- 건너뛰기 버튼

**저장 시점**:
- 사진 선택 시 즉시 저장 (파일 경로)

**완료 처리**:
- "헤이제노 시작하기" 버튼 클릭 시:
  1. `completeOnboarding()` 호출
  2. Device UID 생성/확인
  3. `onboarding_completed = true` 저장
  4. GoRouter로 `/home` 이동

---

## 3. 데이터 저장 구조

### Secure Storage 키

```dart
'device_uid'              // String (UUID v4)
'onboarding_completed'    // String ('true' | 'false')
'onboarding_step'         // String (1~11, 마지막 완료 단계 번호)
'draft_nickname'          // String? (닉네임 초안)
'draft_pet_profile'       // String? (JSON, PetProfileDraft)
```

### PetProfileDraft 모델

```dart
class PetProfileDraft {
  final String? name;                    // 반려동물 이름
  final String? species;                  // 'dog' | 'cat'
  final String? birthMode;               // 'exactBirthdate' | 'approxAge'
  final DateTime? birthdate;             // 생년월일
  final int? ageYears;                   // 연령
  final int? ageMonths;                  // 개월
  final String? breed;                   // 품종
  final String? sex;                      // 'male' | 'female'
  final String? neutered;                 // 'yes' | 'no' | 'unknown'
  final double? weightKg;                // 몸무게 (kg)
  final int? bodyConditionScore;         // BCS (1~9)
  final Set<String> healthConcerns;     // 건강 고민 목록
  final Set<String> foodAllergies;       // 알레르기 목록
  final String? photoUrl;                // 사진 URL/경로
}
```

### 저장 시점

1. **즉시 저장**: 사용자가 입력/선택하는 즉시 Secure Storage에 저장
   - 닉네임 입력 완료 시
   - 종 선택 시
   - 각 프로필 필드 변경 시

2. **단계 저장**: 각 단계 완료 시 마지막 단계 번호 저장
   - "다음" 버튼 클릭 시 `saveLastStep()` 호출

3. **완료 저장**: Step 11 완료 시
   - `onboarding_completed = true` 저장
   - Device UID 생성/확인

---

## 4. 상태 관리

### OnboardingController (StateNotifier)

**상태 클래스**: `OnboardingState`

```dart
class OnboardingState {
  final OnboardingStep currentStep;      // 현재 단계
  final String? nickname;                // 닉네임
  final PetProfileDraft profile;         // 프로필 초안
  final bool isLoading;                  // 로딩 상태
  final String? error;                   // 에러 메시지
}
```

**주요 메서드**:
- `saveNickname(String)`: 닉네임 저장
- `saveProfile(PetProfileDraft)`: 프로필 저장
- `nextStep()`: 다음 단계로 이동
- `previousStep()`: 이전 단계로 이동
- `goToStep(OnboardingStep)`: 특정 단계로 이동
- `completeOnboarding()`: 온보딩 완료 처리
- `validateProfile()`: 프로필 검증

**초기화**:
- Controller 생성 시 `_loadSavedData()` 자동 호출
- 저장된 데이터가 있으면 해당 단계로 복귀

---

## 5. 완료 조건 및 검증

### 프로필 검증 규칙

**필수 필드**:
1. `nickname`: 2~12자
2. `name`: 비어있지 않음 (1~20자)
3. `species`: 'dog' 또는 'cat'
4. `birthMode`: 'exactBirthdate' 또는 'approxAge'
5. `sex`: 'male' 또는 'female'
6. `neutered`: 'yes', 'no', 또는 'unknown'
7. `weightKg`: 0.1~99.9
8. `bodyConditionScore`: 1~9
9. `healthConcerns`: 최소 1개
10. `foodAllergies`: 최소 1개

**조건부 필수 필드**:
- `birthMode == 'exactBirthdate'` → `birthdate` 필수
- `birthMode == 'approxAge'` → `ageYears` 필수
- `species == 'dog'` → `breed` 필수

**선택 필드**:
- `photoUrl`: 선택 사항

### 완료 처리

**Step 11에서 "헤이제노 시작하기" 버튼 클릭 시**:

```dart
1. completeOnboarding() 호출
2. DeviceUidService.getOrCreateDeviceUid() 실행
   - 기존 UID가 있으면 반환
   - 없으면 UUID v4 생성 후 저장
3. onboarding_completed = 'true' 저장
4. GoRouter로 /home 이동
```

---

## 6. 재진입 시 동작

### 앱 재시작 시

1. **OnboardingWrapper 초기화**
   - `OnboardingController` 생성
   - `_loadSavedData()` 자동 실행

2. **저장된 데이터 로드**
   - `onboarding_step`: 마지막 단계 번호
   - `draft_nickname`: 저장된 닉네임
   - `draft_pet_profile`: 저장된 프로필 초안

3. **단계 복귀**
   - 저장된 단계가 있으면 해당 단계로 복귀
   - 없으면 Step 1부터 시작

4. **온보딩 완료 체크**
   - 현재는 라우터에서 `initialLocation: RoutePaths.onboarding`로 설정
   - 향후 `onboarding_completed` 체크 로직 추가 필요

### 중단 후 재진입

- 각 단계의 입력 데이터는 즉시 저장되므로
- 앱을 종료해도 입력한 내용이 유지됨
- 재진입 시 마지막 단계부터 이어서 진행 가능

---

## 7. 라우팅 및 네비게이션

### 라우터 설정

**초기 경로**: `/onboarding`

**라우트 구조**:
```
/onboarding          → OnboardingWrapper
/home                → HomeScreen (메인 홈)
/watch               → WatchScreen (관심)
/benefits            → BenefitsScreen (혜택)
/me                  → MeScreen (마이)
/product/:id         → ProductDetailScreen
```

### 네비게이션

**온보딩 내부**:
- `OnboardingWrapper`가 `currentStep`에 따라 화면 전환
- `OnboardingController.nextStep()` / `previousStep()` 사용

**온보딩 완료 후**:
- `Step11PhotoUploadScreen`에서 `context.go('/home')` 호출
- GoRouter가 `/home`으로 이동

### 향후 개선 사항

**라우터 가드 추가 필요**:
```dart
// 앱 시작 시 onboarding_completed 체크
if (onboardingCompleted) {
  initialLocation: RoutePaths.home;
} else {
  initialLocation: RoutePaths.onboarding;
}
```

---

## 📝 요약

### 전체 플로우 특징

1. **11단계 온보딩 프로세스**
   - Step 1: 닉네임
   - Step 2: 아이 이름
   - Step 3: 종 선택
   - Step 4: 나이 정보
   - Step 5: 품종 (강아지만)
   - Step 6: 성별 + 중성화
   - Step 7: 몸무게
   - Step 8: 비만도
   - Step 9: 건강 고민
   - Step 10: 음식 알레르기
   - Step 11: 사진 업로드

2. **자동 저장**
   - 각 입력/선택 시 즉시 Secure Storage에 저장
   - 앱 종료 후 재진입 시 마지막 단계부터 이어서 진행

3. **유연한 플로우**
   - 강아지/고양이에 따라 다른 단계 경로
   - 사진 업로드는 선택 사항

4. **사용자 친화적**
   - 뒤로가기 지원
   - 진행률 표시
   - Haptic Feedback
   - 부드러운 애니메이션

5. **데이터 보안**
   - Secure Storage 사용
   - Device UID 기반 인증 (이메일/비밀번호 없음)

---

**Made with ❤️ for HeyZeno**
