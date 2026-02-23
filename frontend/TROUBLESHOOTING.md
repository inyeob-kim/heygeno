# Xcode 빌드 타임아웃 해결 방법

## 현재 상황
- l10n 코드는 주석 처리되어 있어 빌드에는 문제 없음
- Xcode 빌드 타임아웃 발생

## 해결 방법

### 1. Xcode 정리 및 재빌드
```bash
cd frontend/ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
flutter run
```

### 2. Xcode 직접 실행
```bash
cd frontend
open ios/Runner.xcworkspace
```
Xcode에서 직접 "Product > Run" 실행

### 3. 디바이스 재연결
- iPhone을 USB에서 분리 후 다시 연결
- 디바이스 신뢰 확인

### 4. Derived Data 정리
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
```

### 5. 간단한 해결 (권장)
```bash
cd frontend
flutter clean
flutter pub get
# l10n 코드 생성 (선택사항)
flutter gen-l10n
# 다시 실행
flutter run -d 00008120-0004483C1198201E
```

## l10n 활성화 (나중에)

l10n 코드가 생성되면:
1. `flutter gen-l10n` 실행
2. `lib/app/app.dart`에서 주석 해제:
   - `import 'package:flutter_gen/gen_l10n/app_localizations.dart';`
   - `AppLocalizations.delegate,`
