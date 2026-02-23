# i18n 영어 적용 현황

## ❌ 현재 상태: 영어 미적용

### 문제점
1. **l10n 코드 미생성**: `flutter gen-l10n` 실행 필요
2. **app.dart 주석 처리**: `AppLocalizations.delegate` 주석 처리됨
3. **화면 코드 미마이그레이션**: 하드코딩된 한글 문자열 사용 중

### 현재 화면 상태
```dart
// home_screen.dart 예시
Text('안녕하세요, ${state.userNickname}님!')  // ❌ 하드코딩된 한글
Text('지금 추천받기')  // ❌ 하드코딩된 한글
```

## ✅ 영어 적용을 위한 단계

### 1단계: l10n 코드 생성 (필수)
```bash
cd frontend
flutter gen-l10n
```

### 2단계: app.dart 활성화
`lib/app/app.dart`에서 주석 해제:
```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';  // 주석 해제

localizationsDelegates: const [
  AppLocalizations.delegate,  // 주석 해제
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
],
```

### 3단계: 화면 코드 마이그레이션 (가장 중요!)

**예시: 홈 화면**
```dart
// Before (현재)
Text('안녕하세요, ${state.userNickname}님!')

// After (변경 필요)
Text(AppLocalizations.of(context)!.screenHomeTitle(state.userNickname ?? 'Pet'))
```

**예시: 버튼**
```dart
// Before (현재)
Text('지금 추천받기')

// After (변경 필요)
Text(AppLocalizations.of(context)!.actionGetRecommendations)
```

## 📊 진행률

- **i18n 구조 준비**: 100% ✅
- **ARB 파일 준비**: 100% ✅
- **l10n 코드 생성**: 0% ❌
- **app.dart 활성화**: 0% ❌
- **화면 마이그레이션**: 0% ❌

## 🎯 즉시 영어를 보려면

**임시 방법** (권장하지 않음):
- ARB 파일의 영어 문자열을 직접 하드코딩으로 교체
- 예: `'안녕하세요'` → `'Welcome back'`

**올바른 방법**:
1. `flutter gen-l10n` 실행
2. `app.dart` 활성화
3. 화면별로 문자열 마이그레이션 진행

## 📝 다음 작업

가장 빠르게 영어를 적용하려면:
1. 홈 화면부터 시작 (가장 중요)
2. 주요 버튼/텍스트부터 교체
3. 점진적으로 확장
