# 🎯 지금 해야 할 일 (단계별 가이드)

## 현재 상태
- ✅ i18n 구조 준비 완료 (ARB 파일, 설정 파일)
- ✅ 홈 화면에 TODO 주석 추가 완료
- ❌ **l10n 코드 미생성** (가장 중요!)
- ❌ **app.dart 주석 처리됨**
- ❌ **화면 코드 주석 처리됨**

## 📋 해야 할 일 (순서대로)

### 1단계: l10n 코드 생성 (필수, 가장 먼저!)

터미널에서 실행:
```bash
cd frontend
flutter gen-l10n
```

**이 명령어가 성공하면:**
- `lib/.dart_tool/flutter_gen/gen_l10n/app_localizations.dart` 파일이 생성됩니다
- 이제 `AppLocalizations`를 사용할 수 있습니다

---

### 2단계: app.dart 활성화

**파일**: `lib/app/app.dart`

**변경 전** (현재):
```dart
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';  // 주석 처리됨

localizationsDelegates: const [
  // AppLocalizations.delegate,  // 주석 처리됨
  GlobalMaterialLocalizations.delegate,
  ...
],
```

**변경 후**:
```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';  // 주석 해제

localizationsDelegates: const [
  AppLocalizations.delegate,  // 주석 해제
  GlobalMaterialLocalizations.delegate,
  ...
],
```

---

### 3단계: home_screen.dart 활성화

**파일**: `lib/features/home/presentation/screens/home_screen.dart`

#### 3-1. Import 추가 (Line ~14)
**변경 전**:
```dart
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
```

**변경 후**:
```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
```

#### 3-2. AppTopBar title (Line ~328)
**변경 전**:
```dart
title: state.userNickname != null 
    ? '안녕하세요, ${state.userNickname}님!'
    : '헤이제노',
```

**변경 후**:
```dart
title: state.userNickname != null 
    ? AppLocalizations.of(context)!.screenHomeTitle(state.userNickname!)
    : AppLocalizations.of(context)!.appName,
```

#### 3-3. EmptyState - 프로필 없음 (Line ~559)
**변경 전**:
```dart
title: isOnboardingCompleted
    ? '프로필을 불러올 수 없습니다'
    : '프로필을 만들어주세요',
message: isOnboardingCompleted
    ? '프로필 정보를 다시 불러오는 중입니다'
    : '반려동물 정보를 입력하면 맞춤 추천을 받을 수 있어요',
buttonText: isOnboardingCompleted ? '다시 불러오기' : '프로필 만들기',
```

**변경 후**:
```dart
final l10n = AppLocalizations.of(context)!;
title: isOnboardingCompleted
    ? l10n.emptyNoPetProfileTitleFailed
    : l10n.emptyNoPetProfileTitle,
message: isOnboardingCompleted
    ? l10n.emptyNoPetProfileSubtitleFailed
    : l10n.emptyNoPetProfileSubtitle,
buttonText: isOnboardingCompleted 
    ? l10n.actionReloadProfile 
    : l10n.actionCreateProfile,
```

#### 3-4. EmptyState - 에러 (Line ~499)
**변경 전**:
```dart
title: state.error ?? '오류가 발생했습니다',
buttonText: '다시 시도',
```

**변경 후**:
```dart
final l10n = AppLocalizations.of(context)!;
title: state.error ?? l10n.errorOccurred,
buttonText: l10n.actionTryAgain,
```

#### 3-5. 섹션 제목 (Line ~700)
**변경 전**:
```dart
Text('왜 이 제품일까요?')
```

**변경 후**:
```dart
Text(AppLocalizations.of(context)!.sectionWhyThisProduct)
```

#### 3-6. 가격 라벨 (Line ~656)
**변경 전**:
```dart
Text('최저가')
```

**변경 후**:
```dart
Text(AppLocalizations.of(context)!.priceLowestPrice)
```

#### 3-7. 가격 비교 메시지 (Line ~678)
**변경 전**:
```dart
Text('최근 평균 대비 $priceDiffPercent% 저렴해요')
```

**변경 후**:
```dart
Text(AppLocalizations.of(context)!.priceCheaperThanAverage(priceDiffPercent))
```

#### 3-8. 빈 추천 결과 (Line ~1646)
**변경 전**:
```dart
title: "추천 상품을 찾지 못했어요",
message: message ?? "현재 조건에 맞는 추천 상품이 없습니다.",
```

**변경 후**:
```dart
final l10n = AppLocalizations.of(context)!;
title: l10n.emptyNoRecommendationsTitle,
message: message ?? l10n.emptyNoRecommendationsSubtitle,
```

#### 3-9. 버튼 텍스트 (Line ~1629)
**변경 전**:
```dart
PrimaryButton(
  text: state.recommendationActionText,
  ...
)
```

**변경 후**:
```dart
final l10n = AppLocalizations.of(context)!;
final buttonText = state.hasRecommendations
    ? l10n.actionGetRecommendationsAgain
    : l10n.actionGetRecommendations;
PrimaryButton(
  text: buttonText,
  ...
)
```

---

## ✅ 체크리스트

진행 순서대로 체크하세요:

- [ ] **1단계**: `flutter gen-l10n` 실행 성공
- [ ] **2단계**: `app.dart`에서 import 및 delegate 주석 해제
- [ ] **3단계**: `home_screen.dart`에서 import 주석 해제
- [ ] **3-2**: AppTopBar title 교체
- [ ] **3-3**: EmptyState (프로필 없음) 교체
- [ ] **3-4**: EmptyState (에러) 교체
- [ ] **3-5**: 섹션 제목 교체
- [ ] **3-6**: 가격 라벨 교체
- [ ] **3-7**: 가격 비교 메시지 교체
- [ ] **3-8**: 빈 추천 결과 교체
- [ ] **3-9**: 버튼 텍스트 교체
- [ ] 앱 실행해서 영어로 표시되는지 확인

---

## 🚨 주의사항

1. **반드시 1단계부터 순서대로 진행**
   - `flutter gen-l10n` 실행 전에 주석을 해제하면 컴파일 에러 발생

2. **한 번에 하나씩 테스트**
   - 모든 주석을 한 번에 해제하지 말고, 하나씩 해제하면서 테스트

3. **에러 발생 시**
   - `flutter clean` 후 다시 `flutter gen-l10n` 실행
   - 또는 주석을 다시 추가하고 단계별로 진행

---

## 📝 빠른 참조

**주요 파일 위치:**
- `lib/app/app.dart` - 전역 설정
- `lib/features/home/presentation/screens/home_screen.dart` - 홈 화면
- `lib/l10n/app_en.arb` - 영어 문자열
- `lib/l10n/app_ko.arb` - 한국어 문자열

**주요 명령어:**
```bash
cd frontend
flutter gen-l10n        # l10n 코드 생성
flutter clean           # 캐시 정리
flutter pub get         # 패키지 재설치
flutter run             # 앱 실행
```
