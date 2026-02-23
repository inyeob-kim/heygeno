# UI 리디자인 작업 계획: Rover/Chewy 스타일 + 미국 현지화

## 목표
- 기존 색상 팔레트 유지 (절대 변경 금지)
- Rover/Chewy 스타일의 "여백 + 카드 중심 + 신뢰 톤 + 단순한 계층" 적용
- 미국 시장 올인: 영어(en_US) 기본, USD/lb/oz, AM/PM, 미국 날짜 포맷
- 기능/데이터 흐름/라우팅 로직은 변경하지 않고 UI/UX만 변경

---

## 0) 현재 상태 진단

### 디자인 관련 요소 위치

#### 테마 파일 (중복 존재)
1. **`lib/app/theme/`** (메인, 현재 사용 중)
   - `app_theme.dart` - ThemeData 정의
   - `app_colors.dart` - 색상 팔레트 (기존 값 유지)
   - `app_radius.dart` - Border radius
   - `app_spacing.dart` - Spacing
   - `app_typography.dart` - Typography
   - `app_shadows.dart` - Shadows

2. **`lib/ui/theme/`** (중복, 제거 예정)
   - `app_theme.dart` - 다른 ThemeData 정의
   - `app_colors.dart` - 다른 색상 정의
   - 기타 중복 파일들

3. **`lib/design_system/theme/`** (신규 디자인 시스템)
   - `app_theme.dart` - 통합 예정

#### 디자인 토큰
- **`lib/design_system/tokens/`** (신규, Rover 스타일)
  - `spacing.dart` - Spacing (기본 24px)
  - `radius.dart` - Radius (카드 20~24, input 16~20, pill 999)
  - `elevation.dart` - Elevation (soft)
  - `durations.dart` - Durations/Curves (부드럽게)
  - `colors.dart` - Colors (기존 값 재사용)

#### 컴포넌트 (이중화 심각)

**기존 컴포넌트 (제거/마이그레이션 예정):**
- `lib/ui/widgets/app_buttons.dart` - AppPrimaryButton (9개 파일에서 사용), AppSecondaryButton
- `lib/ui/widgets/card_container.dart` - CardContainer (10개 파일에서 사용)
- `lib/core/widgets/empty_state.dart` - EmptyStateWidget (7개 파일에서 사용)
- `lib/ui/widgets/figma_section_header.dart` - FigmaSectionHeader (2개 파일에서 사용)
- `lib/ui/widgets/figma_empty_state.dart` - FigmaEmptyState (1개 파일에서 사용)
- `lib/ui/widgets/primary_button.dart` - PrimaryButton (중복)
- `lib/ui/widgets/section_header.dart` - SectionHeader (중복)
- `lib/core/widgets/primary_button.dart` - PrimaryButton (중복)

**신규 컴포넌트 (통일 목표):**
- `lib/design_system/components/button.dart` - PrimaryButton, SecondaryButton ✅
- `lib/design_system/components/app_card.dart` - AppCard ✅
- `lib/design_system/components/empty_state.dart` - EmptyState ✅
- `lib/design_system/components/section_header.dart` - SectionHeader ✅
- `lib/design_system/components/app_scaffold.dart` - AppScaffold ✅
- `lib/design_system/components/badge.dart` - BadgePill ✅

#### 하단 탭
- **현재 구조**: 5탭 (Home, Watch, Market, Benefits, More)
- **목표 구조**: 4탭 (Home, Find, Deals, Alerts)
- **파일**: `lib/ui/widgets/app_bottom_tab_bar.dart`
- **라우터**: `lib/app/router/app_router.dart` (StatefulShellRoute)

---

## 작업 단계별 계획

### PR 1: Design System 토큰 확정 (색상 유지 + Rover 스타일 구조)

**목표**: Rover 스타일의 토큰 시스템 확정, 색상은 기존 값 그대로 유지

**작업 내용**:
1. `lib/design_system/tokens/` 검증 및 보완
   - Spacing: 기본 24px 확인 ✅
   - Radius: 카드 20~24, input 16~20, pill 999 확인 ✅
   - Elevation: soft 그림자 확인 ✅
   - Durations/Curves: 부드러운 애니메이션 확인 ✅
   - Colors: 기존 `app_colors.dart` 값 재사용 확인 ✅

2. `lib/design_system/typography/` 생성/확정
   - H1: 28~32px (크고 단순)
   - Body: 16px (lineHeight 편안하게)
   - Button: 16px, semibold

**변경 파일**:
- `lib/design_system/tokens/` (검증)
- `lib/design_system/typography/` (생성/확정)

**영향 범위**: 없음 (토큰만 정의)

---

### PR 2: ThemeData 통일 (Rover 톤으로 기본 위젯 스타일)

**목표**: 기본 위젯(Card, AppBar, Input, Button)을 Rover 톤으로 통일

**작업 내용**:
1. `lib/app/theme/app_theme.dart` 업데이트
   - CardTheme: 둥근 라운드(20~24) + 소프트 쉐도우
   - AppBarTheme: 그림자 제거, 타이틀 간결, 여백 크게
   - InputDecorationTheme: radius 16~20, 과한 보더 금지
   - ElevatedButton/FilledButton/TextButton: pill + 높이 48 기준
   - 색상 값은 기존 `app_colors.dart` 그대로 사용

2. `lib/app/app.dart`에서 테마 적용 확인

**변경 파일**:
- `lib/app/theme/app_theme.dart`
- `lib/app/app.dart` (확인)

**영향 범위**: 전체 앱 (기본 위젯 스타일 변경)

---

### PR 3: 컴포넌트 단일화 (가장 중요)

**목표**: 기존 컴포넌트를 신규 컴포넌트로 통일

**작업 내용**:

#### 3-1. 기존 컴포넌트 사용처 조사
```bash
# 사용처 찾기
grep -r "AppPrimaryButton\|CardContainer\|EmptyStateWidget\|FigmaSectionHeader" lib/
```

#### 3-2. 마이그레이션 전략
- **방법 A**: 기존 컴포넌트를 신규 컴포넌트 래퍼로 변경 (호환 유지)
- **방법 B**: 사용처를 신규 컴포넌트로 일괄 치환

**선택**: 방법 B (일괄 치환) - 더 깔끔하고 단일화

#### 3-3. 화면별 마이그레이션 순서
1. **홈 화면** (시각적 변화가 가장 큼)
2. **추천/Find 화면**
3. **딜/Deals 화면**
4. **알림/Alerts 화면**
5. **기타 화면** (온보딩, 상세, 설정 등)

**변경 파일**:
- 각 화면 파일들 (기존 컴포넌트 → 신규 컴포넌트)
- 기존 컴포넌트 파일들 (deprecated 표시 후 제거 예정)

**영향 범위**: 전체 앱 (모든 화면)

---

### PR 4: Bottom Tab 재정의 (4탭: Home/Find/Deals/Alerts)

**목표**: 하단 탭을 4개로 재구성, 미국 런치 최적화

**작업 내용**:
1. **탭 구조 변경**:
   - 기존: Home, Watch, Market, Benefits, More (5탭)
   - 신규: Home, Find, Deals, Alerts (4탭)

2. **라우팅 매핑**:
   - Home → Home (유지)
   - Find → Recommendation (기존 추천 화면)
   - Deals → Market (기존 마켓 화면, "멀티플랫폼 최저가 비교"로 재정의)
   - Alerts → Watch (기존 관심 화면, 알림 중심으로 재정의)

3. **Benefits 처리**:
   - Home에 "Rewards preview 카드"로 요약 노출
   - 또는 More/Account 영역으로 이동 (하단 탭에서 제거)

4. **More 처리**:
   - 하단 탭에서 제거
   - Home 우상단 profile/settings 아이콘(또는 top-right menu)로 이동

5. **아이콘 변경**:
   - Home: `home_rounded` (유지)
   - Find: `search_rounded` (새로)
   - Deals: `local_offer_rounded` 또는 `attach_money_rounded` (새로)
   - Alerts: `notifications_rounded` (새로)

6. **라벨 변경** (i18n):
   - `tab_home` → "Home"
   - `tab_find` → "Find" (신규)
   - `tab_deals` → "Deals" (신규)
   - `tab_alerts` → "Alerts" (신규)

**변경 파일**:
- `lib/ui/widgets/app_bottom_tab_bar.dart`
- `lib/app/router/app_router.dart` (StatefulShellRoute branches)
- `lib/l10n/app_en.arb` (라벨 추가)

**영향 범위**: 네비게이션 구조 (기능은 유지)

---

### PR 5: Home 화면 리디자인 (Rover/Chewy식 구조)

**목표**: Home 화면을 Rover/Chewy 스타일로 재배치

**작업 내용**:
1. **상단 Hero 섹션**:
   - 큰 헤더: "Hey {petName}! 🐾"
   - 서브: "Ready to find food that fits {him/her}?"
   - 우상단: profile/settings + pet switch

2. **Pet Summary Card** (AppCard):
   - 큰 원형 이미지/placeholder
   - 한 줄 요약: "Senior • 30.2 lb • Neutered"
   - 건강고민: 2개까지만 표시 + '+2 more'로 축약
   - Allergies: "Avoid" 배지로 정리

3. **Current Food CTA Card**:
   - 문구: "What's {petName} eating right now?"
   - 보조 설명: "We'll compare ingredients and track the best price."
   - PrimaryButton: "Add current food"
   - 토글/아이콘 라인: Price drop / Low stock / Health match (요약형)

4. **Recommendation CTA Card**:
   - 제목: "Find {petName}'s best match"
   - 보조: "Personalized for allergies, age, and health needs."
   - PrimaryButton: "Get recommendations"

5. **Alerts preview** (최대 2개) + "See all alerts" 링크

**규칙**:
- 한 화면에 모든 내용을 다 보여주지 말고, "요약 + 더보기"로 밀도 줄이기
- 숫자 나열 UI 금지: 요약 문장 → 상세에서 수치 공개

**변경 파일**:
- `lib/features/home/presentation/screens/home_screen.dart`
- `lib/features/home/presentation/widgets/` (관련 위젯들)

**영향 범위**: Home 화면만

---

### PR 6: Find/Deals/Alerts 화면 리디자인

**목표**: 핵심 화면들을 Rover 스타일로 리디자인

#### 6-1. Find 탭 (추천)
- 추천 시작(필터/질문) 흐름을 카드형 섹션으로 정리
- 결과 리스트는 "신뢰 카드 리스트": 큰 이미지 + 한 줄 요약 + 배지
- 점수는 기본 숨김, "Why this?" 눌러서 bottom sheet에서 근거 공개

#### 6-2. Deals 탭 (최저가)
- "Shop"이 아니라 "Compare & best price"에 초점
- 상단 검색 + 필터칩
- 리스트 카드에는 "Best price today" 같은 문구 + 플랫폼 뱃지

#### 6-3. Alerts 탭 (알림)
- 가격 하락/재고/추천 업데이트를 탭 내 섹션으로 구분
- 알림 아이템은 카드 리스트로 통일, 액션은 1개(보기/끄기)
- 빈상태/에러: 친근한 영어 + 행동 1개만 제공

**변경 파일**:
- `lib/features/recommendation/` (Find)
- `lib/features/market/` (Deals)
- `lib/features/watch/` 또는 `lib/features/alert/` (Alerts)

**영향 범위**: 각 화면만

---

### PR 7: 미국 현지화 (en_US 기본 + 포맷터)

**목표**: 영어 기본, USD/lb/oz, AM/PM, 미국 날짜 포맷 적용

**작업 내용**:
1. **i18n 기본 설정**:
   - 기본 Locale: en_US ✅ (이미 설정됨)
   - ko_KR은 유지 가능하되 런치 기본은 en_US

2. **하드코딩 문자열 치환**:
   - 모든 하드코딩 문자열을 l10n 키로 치환
   - `lib/l10n/app_en.arb`에 영어 문구 추가

3. **포맷터 생성** (`lib/utils/formatters.dart`):
   - `currency`: USD 포맷, thousand separator
   - `date`: MMM d, yyyy (예: "Jan 15, 2024")
   - `time`: 12h AM/PM
   - `weight`: kg→lb 변환(표시만), 내부 계산은 기존 단위 유지

4. **Home에서 단위 표기 적용**:
   - "13.7kg" → "30.2 lb"로 표시
   - 모든 무게 표기를 lb로 변환

5. **텍스트 오버플로우 대응**:
   - 긴 영어 문장 대응(줄바꿈/auto-size/최소화)

**변경 파일**:
- `lib/utils/formatters.dart` (신규)
- `lib/l10n/app_en.arb` (문구 추가)
- 각 화면 파일들 (하드코딩 문자열 → l10n 키)

**영향 범위**: 전체 앱 (표시 형식만 변경)

---

### PR 8: QA 체크리스트 & 완료 기준

**완료 기준**:
1. ✅ 버튼/카드/empty/section header가 단일 컴포넌트로 통일됨
2. ✅ Home/Find/Deals/Alerts 4탭이 동작하고 용어가 미국식으로 명확함
3. ✅ Home에서 "여백/요약/CTA 중심"으로 Rover 체감이 남
4. ✅ 영어 기본, USD/lb/US date/time 포맷 적용됨
5. ✅ 기능 로직 변화 없음(회귀 최소)

**QA 체크리스트 문서**: `UI_REDESIGN_QA_CHECKLIST.md` 생성

---

## 마이그레이션 전략

### 기존 컴포넌트 → 신규 컴포넌트 매핑

| 기존 컴포넌트 | 신규 컴포넌트 | 위치 |
|-------------|-------------|------|
| `AppPrimaryButton` | `PrimaryButton` | `lib/design_system/components/button.dart` |
| `AppSecondaryButton` | `SecondaryButton` | `lib/design_system/components/button.dart` |
| `CardContainer` | `AppCard` | `lib/design_system/components/app_card.dart` |
| `EmptyStateWidget` | `EmptyState` | `lib/design_system/components/empty_state.dart` |
| `FigmaSectionHeader` | `SectionHeader` | `lib/design_system/components/section_header.dart` |
| `FigmaEmptyState` | `EmptyState` | `lib/design_system/components/empty_state.dart` |

### 탭 구조 변경 매핑

| 기존 탭 | 신규 탭 | 라우팅 |
|--------|--------|--------|
| Home | Home | `/home` (유지) |
| Watch | Alerts | `/watch` → `/alerts` |
| Market | Deals | `/market` → `/deals` |
| Benefits | (제거) | Home에 "Rewards preview" 카드로 노출 |
| More | (제거) | Home 우상단 profile/settings로 이동 |

---

## 주의사항

1. **색상 팔레트 절대 변경 금지**: 기존 `app_colors.dart` 값 그대로 사용
2. **기능 로직 변경 금지**: UI/UX만 변경, 데이터 흐름/라우팅 유지
3. **점진적 마이그레이션**: 화면별로 PR 단위로 진행, 한 번에 모든 화면 변경 금지
4. **회귀 테스트**: 각 PR마다 기능 동작 확인

---

## 예상 작업 시간

- PR 1: 1일 (토큰 확정)
- PR 2: 1일 (ThemeData 통일)
- PR 3: 3-5일 (컴포넌트 단일화, 화면별 마이그레이션)
- PR 4: 1일 (Bottom Tab 재정의)
- PR 5: 2-3일 (Home 화면 리디자인)
- PR 6: 3-4일 (Find/Deals/Alerts 리디자인)
- PR 7: 2-3일 (미국 현지화)
- PR 8: 1일 (QA 체크리스트)

**총 예상 시간**: 14-19일
