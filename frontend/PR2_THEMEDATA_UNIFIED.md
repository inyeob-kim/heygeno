# PR 2: ThemeData 통일 (Rover 톤으로 기본 위젯 스타일)

## 목표
기본 위젯(Card, AppBar, Input, Button)을 Rover 톤으로 통일

## 변경 사항

### 1. AppBarTheme 업데이트
- ✅ elevation: 0 (그림자 제거)
- ✅ titleTextStyle: fontWeight w700 → w600 (간결하게)
- ✅ toolbarHeight: 64px (여백 크게)

### 2. CardTheme 업데이트
- ✅ borderRadius: 12px → 20px (Rover 스타일, 더 둥글게)
- ✅ shadowColor: transparent (그림자는 컴포넌트에서 boxShadow로 처리)
- ✅ border 제거 (Rover 스타일: 깔끔한 카드)

### 3. InputDecorationTheme 추가
- ✅ borderRadius: 16px (Rover 스타일)
- ✅ border: 1px (과한 보더 금지)
- ✅ focusedBorder: 2px primary (명확한 포커스 표시)
- ✅ contentPadding: 16px (편안한 여백)

### 4. Button Themes 업데이트
- ✅ ElevatedButton: pill (999) + 높이 48px
- ✅ FilledButton: pill (999) + 높이 48px
- ✅ TextButton: pill (999) + 높이 48px
- ✅ padding: horizontal 24px, vertical 12px
- ✅ elevation: 0 (그림자는 컴포넌트에서 처리)

### 5. Dark Theme도 동일하게 적용
- ✅ 모든 변경사항을 darkTheme에도 동일하게 적용

## 사용된 디자인 토큰
- `DesignTokens.BorderRadiusTokens.card`: 20px
- `DesignTokens.BorderRadiusTokens.input`: 16px
- `DesignTokens.BorderRadiusTokens.button`: 999 (pill)
- `DesignTokens.Spacing.base`: 24px
- `DesignTokens.Spacing.md`: 12px
- `DesignTokens.Spacing.buttonHeight`: 48px

## 영향 범위
전체 앱 (기본 위젯 스타일 변경)

## 주의사항
- 색상 값은 기존 `app_colors.dart` 그대로 사용 (변경 없음)
- 화면들에서 커스텀 컴포넌트가 테마를 오버라이드하고 있으면 해당 컴포넌트도 업데이트 필요

## 다음 단계
PR 3: 컴포넌트 단일화 (기존 → 신규 컴포넌트로 통일)
