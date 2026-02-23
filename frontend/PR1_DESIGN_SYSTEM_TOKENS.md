# PR 1: Design System 토큰 확정 (색상 유지 + Rover 스타일 구조)

## 목표
Rover 스타일의 토큰 시스템 확정, 색상은 기존 값 그대로 유지

## 변경 사항

### 1. Spacing 토큰 보완
**파일**: `lib/design_system/tokens/spacing.dart`

- ✅ 기본 여백: 24px (base)
- ✅ 카드 패딩: 24px (card)
- ✅ 섹션 간격: 32px (section)
- ✅ 버튼 높이 추가: 48px (buttonHeight), 56px (buttonHeightLarge)

### 2. Radius 토큰 보완
**파일**: `lib/design_system/tokens/radius.dart`

- ✅ 카드: 20px (card), 24px (cardLarge)
- ✅ 입력 필드: 16px (input), 20px (inputLarge) 추가
- ✅ 버튼: pill (999)
- ✅ 바텀시트: 24px

### 3. Typography 보완 (Rover 스타일)
**파일**: `lib/design_system/typography/text_styles.dart`

- ✅ H1: 32px (모바일: 28px) - 크고 단순하게 조정
- ✅ H2: 24px - 섹션 제목
- ✅ H3: 20px
- ✅ Body: 16px, lineHeight 1.6 (편안하게)
- ✅ Button: 16px, semibold (w600)

### 4. 버튼 컴포넌트 업데이트
**파일**: `lib/design_system/components/button.dart`

- ✅ 기본 높이: 44px → 48px로 변경 (Rover 스타일)
- ✅ SecondaryButton도 동일하게 적용

### 5. 색상 팔레트 확인
**파일**: `lib/design_system/tokens/colors.dart`

- ✅ 기존 `app_colors.dart` 값 그대로 재사용
- ✅ Primary: #2563EB (Blue 600)
- ✅ Status: #16A34A (Green)
- ✅ Drop: #DC2626 (Red)
- ✅ Background: #F8FAFC
- ✅ Surface: #FFFFFF

## 검증 완료 항목

- ✅ Spacing: 기본 24px 확인
- ✅ Radius: 카드 20~24, input 16~20, pill 999 확인
- ✅ Elevation: soft 그림자 확인
- ✅ Durations/Curves: 부드러운 애니메이션 확인
- ✅ Colors: 기존 값 재사용 확인
- ✅ Typography: H1 28~32px, Body 16px, Button semibold 확인

## 영향 범위
없음 (토큰만 정의/보완)

## 다음 단계
PR 2: ThemeData 통일 (Rover 톤으로 기본 위젯 스타일)
