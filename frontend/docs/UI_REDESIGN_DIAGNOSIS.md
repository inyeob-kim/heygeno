# UI 리디자인 진단 & 작업 계획

## 📋 현재 상태 진단

### 1. Theme/ColorScheme 위치

#### ✅ 최신 (사용 권장)
- `frontend/lib/app/theme/app_theme.dart` - `AppTheme.lightTheme`
- `frontend/lib/app/theme/app_colors.dart` - `AppColors` (primary: `#2563EB`)

#### ⚠️ 구버전 (점진적 제거 필요)
- `frontend/lib/ui/theme/app_theme.dart` - `AppTheme.light` (토스 스타일)
- `frontend/lib/ui/theme/app_colors.dart` - 다른 색상 값 사용

#### ✅ Design System Theme
- `frontend/lib/design_system/theme/app_theme.dart` - 확인 필요

**결론**: `frontend/lib/app/theme/`를 기준으로 통일, 색상 값은 절대 변경하지 않음.

---

### 2. Spacing/Radius 상수 위치

#### ✅ Design System Tokens (최신, Rover 스타일)
- `frontend/lib/design_system/tokens/spacing.dart` - `Spacing` (base=24, card=24, section=32)
- `frontend/lib/design_system/tokens/radius.dart` - `BorderRadiusTokens` (card=20, button=999, input=16)

#### ⚠️ 구버전 (점진적 제거 필요)
- `frontend/lib/app/theme/app_spacing.dart` - `AppSpacing` (xl=24, xxxl=48)
- `frontend/lib/app/theme/app_radius.dart` - `AppRadius` (card=16, pill=999)
- `frontend/lib/ui/theme/app_spacing.dart` - 다른 값 (pagePadding=16)
- `frontend/lib/ui/theme/app_radius.dart` - 다른 값 (cardRadius=18)

**결론**: `frontend/lib/design_system/tokens/`를 기준으로 통일.

---

### 3. 공통 컴포넌트 이중화 현황

#### 🔴 PrimaryButton (3개 버전)

1. **✅ 신규 (Design System)**
   - `frontend/lib/design_system/components/button.dart`
   - `PrimaryButton`, `SecondaryButton`
   - Pill 형태, 높이 48px, 아이콘 지원

2. **⚠️ 기존 버전들**
   - `frontend/lib/ui/widgets/primary_button.dart` - `PrimaryButton` (FilledButton 기반)
   - `frontend/lib/core/widgets/primary_button.dart` - `PrimaryButton` (ElevatedButton 기반)
   - `frontend/lib/ui/widgets/app_buttons.dart` - 확인 필요
   - `frontend/lib/ui/widgets/figma_primary_button.dart` - 확인 필요

**사용처**: 약 30개 파일에서 혼재 사용 중

---

#### 🔴 CardContainer/AppCard (2개 버전)

1. **✅ 신규 (Design System)**
   - `frontend/lib/design_system/components/app_card.dart`
   - `AppCard` (radius 20, padding 24, 소프트 그림자)

2. **⚠️ 기존 버전**
   - `frontend/lib/ui/widgets/card_container.dart` - `CardContainer` (radius 16, padding 24)

**사용처**: 약 20개 파일에서 혼재 사용 중

---

#### 🔴 EmptyState (3개 버전)

1. **✅ 신규 (Design System)**
   - `frontend/lib/design_system/components/empty_state.dart`
   - `EmptyState` (친근한 문구, 1개 버튼)

2. **⚠️ 기존 버전들**
   - `frontend/lib/core/widgets/empty_state.dart` - `EmptyStateWidget` (쿠팡 스타일)
   - `frontend/lib/ui/widgets/figma_empty_state.dart` - 확인 필요

**사용처**: 약 10개 파일에서 혼재 사용 중

---

#### 🔴 SectionHeader (3개 버전)

1. **✅ 신규 (Design System)**
   - `frontend/lib/design_system/components/section_header.dart`
   - `SectionHeader` (제목 + 서브타이틀 + optional action)

2. **⚠️ 기존 버전들**
   - `frontend/lib/ui/widgets/section_header.dart` - 확인 필요
   - `frontend/lib/ui/widgets/figma_section_header.dart` - 확인 필요
   - `frontend/lib/ui/components/section_header.dart` - 확인 필요

**사용처**: 약 15개 파일에서 혼재 사용 중

---

### 4. Bottom Tab 구조

#### 현재 구조 (5개 탭)
- **0: Home** (`RoutePaths.home`)
- **1: Watch** (`RoutePaths.watch`) → **Alerts로 변경 예정**
- **2: Market** (`RoutePaths.market`) → **Deals로 변경 예정**
- **3: Benefits** (`RoutePaths.benefits`) → **Home에 통합 또는 More로 이동**
- **4: More** (`RoutePaths.me`) → **하단 탭에서 제거, Home 우상단으로 이동**

#### 목표 구조 (4개 탭)
- **0: Home** (유지)
- **1: Find** (새로 생성, 추천 화면)
- **2: Deals** (Market 리네임, 최저가 비교)
- **3: Alerts** (Watch 리네임, 가격/재고/추천 알림)

**파일 위치**:
- `frontend/lib/ui/widgets/app_bottom_tab_bar.dart` - 탭 UI
- `frontend/lib/app/router/app_router.dart` - 라우팅 (5개 브랜치)
- `frontend/lib/ui/widgets/bottom_nav_shell.dart` - 셸 래퍼

---

### 5. i18n 현황

#### ✅ 이미 설정됨
- `frontend/lib/app/app.dart` - `flutter_localizations` 설정, 기본 locale: `en_US`
- `frontend/lib/l10n/app_en.arb` - 영어 번역 파일
- `frontend/lib/l10n/app_ko.arb` - 한국어 번역 파일

#### ⚠️ 작업 필요
- 하드코딩 문자열을 l10n 키로 치환
- USD/날짜/시간/무게 포맷터 추가

---

## 📝 단계별 작업 계획 (PR 단위)

### PR 1: Design System 토큰 확정 (기존 색상 유지)

**목표**: Rover 스타일 토큰 확정, 색상은 절대 변경하지 않음

**변경 파일**:
- `frontend/lib/design_system/tokens/spacing.dart` - 확인 및 보완
- `frontend/lib/design_system/tokens/radius.dart` - 확인 및 보완
- `frontend/lib/design_system/tokens/elevation.dart` - 확인 및 보완
- `frontend/lib/design_system/tokens/durations.dart` - 확인 및 보완
- `frontend/lib/design_system/typography/text_styles.dart` - H1 28~32, body 16, lineHeight 편안하게

**영향 범위**: 토큰만 정의, 기존 코드 영향 없음

---

### PR 2: ThemeData 통일 (Rover 톤, 색상 유지)

**목표**: ThemeData를 Rover 스타일로 업데이트, 색상 값은 그대로 사용

**변경 파일**:
- `frontend/lib/app/theme/app_theme.dart` - CardTheme, AppBarTheme, InputDecorationTheme, ButtonTheme 업데이트
- `frontend/lib/app/app.dart` - Theme 적용 확인

**영향 범위**: 기본 위젯 스타일 변경 (Material 위젯들)

---

### PR 3: 컴포넌트 단일화 - 버튼

**목표**: 모든 버튼을 `design_system/components/button.dart`의 `PrimaryButton`/`SecondaryButton`으로 통일

**변경 파일**:
- 기존 버튼 사용처 약 30개 파일 → 신규 컴포넌트로 치환
- `frontend/lib/ui/widgets/primary_button.dart` - Deprecated 표시
- `frontend/lib/core/widgets/primary_button.dart` - Deprecated 표시

**영향 범위**: 모든 화면의 버튼 스타일 통일

---

### PR 4: 컴포넌트 단일화 - 카드

**목표**: 모든 카드를 `design_system/components/app_card.dart`의 `AppCard`로 통일

**변경 파일**:
- 기존 카드 사용처 약 20개 파일 → 신규 컴포넌트로 치환
- `frontend/lib/ui/widgets/card_container.dart` - Deprecated 표시

**영향 범위**: 모든 화면의 카드 스타일 통일

---

### PR 5: 컴포넌트 단일화 - EmptyState & SectionHeader

**목표**: EmptyState와 SectionHeader를 Design System 컴포넌트로 통일

**변경 파일**:
- EmptyState 사용처 약 10개 파일 → 신규 컴포넌트로 치환
- SectionHeader 사용처 약 15개 파일 → 신규 컴포넌트로 치환
- 기존 컴포넌트들 Deprecated 표시

**영향 범위**: 빈 상태 및 섹션 헤더 스타일 통일

---

### PR 6: Bottom Tab 재정의 (4탭 구조)

**목표**: 5탭 → 4탭으로 재구성 (Home, Find, Deals, Alerts)

**변경 파일**:
- `frontend/lib/ui/widgets/app_bottom_tab_bar.dart` - 탭 아이콘/라벨 변경
- `frontend/lib/app/router/app_router.dart` - 브랜치 재구성 (5개 → 4개)
- `frontend/lib/ui/widgets/bottom_nav_shell.dart` - 브랜치 인덱스 매핑 수정
- `frontend/lib/l10n/app_en.arb` - 탭 라벨 추가 (tab_find, tab_deals, tab_alerts)
- `frontend/lib/app/router/route_paths.dart` - 경로 추가/변경

**영향 범위**: 네비게이션 구조 변경, 기존 Watch/Market/Benefits/More 경로는 리다이렉트 또는 제거

**주의사항**:
- Watch → Alerts: 기능 유지, 이름만 변경
- Market → Deals: 기능 유지, 이름만 변경
- Benefits: Home에 "Rewards preview" 카드로 통합 또는 More로 이동
- More: 하단 탭에서 제거, Home 우상단 profile/settings 아이콘으로 이동

---

### PR 7: Home 화면 리디자인 (Rover/Chewy 스타일)

**목표**: Home 화면을 "여백 + 카드 중심 + 신뢰 톤"으로 재배치

**변경 파일**:
- `frontend/lib/features/home/presentation/screens/home_screen.dart` - 전체 구조 재배치
- `frontend/lib/features/home/presentation/widgets/` - 위젯들 리팩토링
- `frontend/lib/l10n/app_en.arb` - 영어 문구 추가

**구조 변경**:
1. 상단 Hero: "Hey {petName}! 🐾" + 서브텍스트
2. Pet Summary Card: 큰 이미지 + 한 줄 요약 + 건강고민 2개까지만 + Allergies 배지
3. Current Food CTA Card: "What's {petName} eating right now?" + PrimaryButton
4. Recommendation CTA Card: "Find {petName}'s best match" + PrimaryButton
5. Alerts preview (최대 2개) + "See all alerts" 링크

**영향 범위**: Home 화면 전체 UI 변경 (기능 로직은 유지)

---

### PR 8: Find/Deals/Alerts 화면 리디자인

**목표**: 각 탭 화면을 Rover 스타일로 리디자인

**변경 파일**:
- `frontend/lib/features/recommendation/` - Find 탭 (추천 화면)
- `frontend/lib/features/market/` - Deals 탭 (최저가 비교)
- `frontend/lib/features/watch/` 또는 `frontend/lib/features/alert/` - Alerts 탭 (알림)

**주요 변경**:
- Find: 카드형 섹션, 점수는 기본 숨김, "Why this?" bottom sheet
- Deals: "Compare & best price" 초점, 플랫폼 뱃지
- Alerts: 탭 내 섹션 구분, 카드 리스트, 친근한 영어 문구

**영향 범위**: 각 탭 화면 전체 UI 변경 (기능 로직은 유지)

---

### PR 9: 미국 현지화 (i18n + 포맷터)

**목표**: 영어 기본, USD/lb/US date/time 포맷 적용

**변경 파일**:
- `frontend/lib/utils/formatters.dart` - 새로 생성
  - `CurrencyFormatter`: USD 포맷, thousand separator
  - `DateFormatter`: MMM d, yyyy
  - `TimeFormatter`: 12h AM/PM
  - `WeightFormatter`: kg → lb 변환 (표시만)
- 모든 화면의 하드코딩 문자열 → l10n 키로 치환
- `frontend/lib/l10n/app_en.arb` - 모든 영어 문구 추가
- Home 화면의 "13.7kg" → "30.2 lb" 변환 적용

**영향 범위**: 모든 화면의 텍스트 및 포맷팅

---

### PR 10: QA 체크리스트 & 완료 기준

**목표**: 리디자인 완료 기준 문서화

**생성 파일**:
- `frontend/docs/UI_REDESIGN_QA_CHECKLIST.md` - QA 체크리스트

**체크리스트 항목**:
1. ✅ 버튼/카드/empty/section header가 단일 컴포넌트로 통일됨
2. ✅ Home/Find/Deals/Alerts 4탭이 동작하고 용어가 미국식으로 명확함
3. ✅ Home에서 "여백/요약/CTA 중심"으로 Rover 체감이 남
4. ✅ 영어 기본, USD/lb/US date/time 포맷 적용됨
5. ✅ 기능 로직 변화 없음 (회귀 최소)

---

## 🎯 우선순위 및 의존성

### Phase 1: 기반 구축 (PR 1-2)
- Design System 토큰 확정
- ThemeData 통일
- **의존성**: 없음

### Phase 2: 컴포넌트 통일 (PR 3-5)
- 버튼/카드/EmptyState/SectionHeader 단일화
- **의존성**: Phase 1 완료

### Phase 3: 네비게이션 재구성 (PR 6)
- Bottom Tab 4탭 구조
- **의존성**: Phase 2 완료 (컴포넌트 통일 후 적용)

### Phase 4: 화면 리디자인 (PR 7-8)
- Home/Find/Deals/Alerts 화면 리디자인
- **의존성**: Phase 2, 3 완료

### Phase 5: 현지화 (PR 9)
- i18n + 포맷터
- **의존성**: Phase 4 완료 (화면 구조 확정 후)

### Phase 6: QA (PR 10)
- 체크리스트 및 완료 기준
- **의존성**: 모든 Phase 완료

---

## ⚠️ 주의사항

1. **색상 팔레트 절대 변경 금지**: `AppColors.primary = #2563EB` 등 기존 색상 값은 그대로 유지
2. **기능/데이터 흐름/라우팅 로직 변경 금지**: UI/UX만 변경
3. **점진적 마이그레이션**: 기존 컴포넌트를 한 번에 제거하지 말고 Deprecated 표시 후 단계적으로 치환
4. **회귀 테스트**: 각 PR마다 기능 동작 확인
5. **영어 기본**: 모든 새 문구는 영어로 작성, 한국어는 선택적

---

## 📊 예상 작업량

- **PR 1-2**: 1-2일 (토큰/테마 정의)
- **PR 3-5**: 3-5일 (컴포넌트 통일, 약 75개 파일 수정)
- **PR 6**: 1-2일 (탭 재구성)
- **PR 7**: 2-3일 (Home 화면 리디자인)
- **PR 8**: 3-4일 (Find/Deals/Alerts 화면 리디자인)
- **PR 9**: 2-3일 (현지화)
- **PR 10**: 0.5일 (QA 문서)

**총 예상 기간**: 약 2-3주 (PR 단위로 진행)
