# 홈 화면 i18n 마이그레이션 준비 완료

## ✅ 완료된 작업

1. ARB 파일에 필요한 키 추가 완료
2. 홈 화면 코드에 TODO 주석 추가 (마이그레이션 위치 표시)

## 🚀 다음 단계

### 1. l10n 코드 생성 (필수)
```bash
cd frontend
flutter gen-l10n
```

### 2. app.dart 활성화
`lib/app/app.dart`에서 주석 해제:
```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';  // 주석 해제
AppLocalizations.delegate,  // 주석 해제
```

### 3. home_screen.dart 활성화
`lib/features/home/presentation/screens/home_screen.dart`에서:
1. Import 주석 해제
2. 모든 TODO 주석 해제하고 하드코딩된 문자열 교체

## 📝 변경 위치

다음 위치에서 TODO 주석을 찾아서 주석 해제하세요:

1. **Line ~12**: Import 추가
2. **Line ~328**: AppTopBar title
3. **Line ~559**: EmptyState (프로필 없음)
4. **Line ~499**: EmptyState (에러)
5. **Line ~700**: 섹션 제목 "왜 이 제품일까요?"
6. **Line ~656**: "최저가"
7. **Line ~678**: 가격 비교 메시지
8. **Line ~1646**: 빈 추천 결과
9. **Line ~1627**: 버튼 텍스트

## ⚠️ 주의사항

- `flutter gen-l10n` 실행 전에는 주석을 해제하면 컴파일 에러 발생
- 모든 TODO 주석을 한 번에 해제하지 말고, 하나씩 테스트하면서 진행
