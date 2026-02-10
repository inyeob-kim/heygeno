# 헤이제노 디자인 시스템 가이드 v1.0 (Final)

> 일상 관리형 펫 서비스에 최적화된 iOS 스타일 디자인 시스템

---

## 📋 목차

0. [헤이제노 디자인 철학](#0-헤이제노-디자인-철학-최종)
1. [헤이제노 전용 컬러 시스템](#1-헤이제노-전용-컬러-시스템)
2. [이모지 사용 규칙](#2-이모지-사용-규칙-헤이제노만의-감성)
3. [간격 시스템](#3-간격-시스템-appspacing)
4. [AppRadius 가이드](#4-appradius-가이드)
5. [AppElevation 가이드](#5-appelevation-가이드-중요)
6. [CardContainer 최종 규칙](#6-cardcontainer-최종-규칙)
7. [홈 화면 전용 UI 원칙](#7-홈-화면-전용-ui-원칙-핵심)
8. [애니메이션 원칙](#8-애니메이션-원칙-헤이제노-스타일)
9. [컴포넌트 가이드](#9-컴포넌트-가이드)
10. [최종 체크리스트](#-최종-체크리스트)

---

## 0️⃣ 헤이제노 디자인 철학 (최종)

### 헤이제노는 이런 앱이다

❌ **"매번 추천받는 앱"**

✅ **"지금 상태를 한눈에 확인하는 앱"**

### 핵심 키워드

- **관리 (Manage)** - 현재 상태를 체계적으로 관리
- **안심 (Reassurance)** - 잘하고 있다는 신호 제공
- **일상 (Daily)** - 매일 사용하는 일상 도구
- **우리 아이 (Emotional, but 절제된)** - 감정적이지만 과하지 않게

### 디자인 원칙

👉 **차분하지만 차갑지 않게**  
👉 **귀엽지만 유치하지 않게**

---

## 1️⃣ 헤이제노 전용 컬러 시스템

### 🎨 컬러 역할 분리 (가장 중요)

**색은 감정이 아니라 "역할"로 쓴다**

### Primary 컬러 2축 구조

```dart
// Decision / Navigation (정보, 이동, 비교)
AppColors.primaryBlue   // #2563EB

// Status / Emotional (현재 상태, 안심, 성공)
AppColors.petGreen      // #16A34A
```

### 컬러 사용 규칙 (명문화)

#### 🔵 Primary Blue (#2563EB)

**언제 쓰나**
- 이동 / 전환 / 비교
- "결정"이 필요한 버튼
- CTA 중 행동 유도

**사용 예**
- 비교해보기
- 상세보기
- 추천 결과 보기
- 링크 / 강조 텍스트

```dart
OutlinedButton(
  side: BorderSide(color: AppColors.primaryBlue),
  child: Text('비교해보기'),
)
```

#### 🟢 Pet Green (#16A34A)

**언제 쓰나**
- 현재 상태
- 잘하고 있다는 신호
- 등록 완료 / 유지 중
- "안심" 메시지

**사용 예**
- 현재 급여 중
- 가격 알림 ON
- 정상 / 적합 / 완료

```dart
Container(
  color: AppColors.petGreen.withOpacity(0.1),
  child: Text('현재 급여 중'),
)
```

#### ❌ 금지 규칙

- **Primary Blue + Pet Green 동시 강조 금지**
- **감정용 컬러(초록)를 CTA 메인으로 남발 금지**

### 전체 색상 팔레트

```dart
// 배경
AppColors.background  // #F7F8FB - 전체 배경
AppColors.surface     // #FFFFFF - 카드/컨테이너 배경

// 텍스트
AppColors.textPrimary    // #0F172A - 주요 텍스트
AppColors.textSecondary  // #64748B - 보조 텍스트

// Primary (Blue)
AppColors.primaryBlue   // #2563EB - 결정/이동/비교
AppColors.primary2      // #1D4ED8 - 호버/활성 상태

// Status (Green)
AppColors.petGreen      // #16A34A - 상태/안심/성공

// 상태 색상
AppColors.positiveGreen  // #00D084 - 성공/긍정
AppColors.dangerRed      // #F04452 - 에러/위험

// 아이콘
AppColors.iconPrimary  // #0F172A - 주요 아이콘
AppColors.iconMuted    // #64748B - 보조 아이콘
```

---

## 2️⃣ 이모지 사용 규칙 (헤이제노만의 감성)

### 핵심 원칙

**이모지는 정보 보조 도구이지, 장식이 아니다**

### 허용 위치

✅ 섹션 타이틀  
✅ 카드 헤더  
✅ 상태 요약

### 금지 위치

❌ 본문 문장 중간  
❌ 버튼 텍스트  
❌ 리스트 아이템마다 반복

### 기본 이모지 세트 (고정)

| 용도 | 이모지 | 사용 예 |
|------|--------|---------|
| 펫 | 🐶 🐱 | 펫 프로필 |
| 사료 | 🥣 | 현재 급여 사료 |
| 가격 | 📉 | 가격 하락 |
| 시간 | ⏰ | 소진 예상 |
| 혜택 | 🎁 | 포인트 |
| 상태 OK | ✅ | 완료 |
| 주의 | ⚠️ | 변경 필요 |

### 이모지 사용 규칙

- **한 섹션당 최대 1개**
- **크기 조절 ❌** → 기본 폰트 크기 사용
- **색상 변경 ❌** (이모지는 항상 기본 컬러)

```dart
// ✅ 올바른 사용
Text('🐶 ${petName}')  // 섹션 헤더
Text('🥣 현재 급여 중')  // 카드 타이틀

// ❌ 잘못된 사용
Text('사료를 🥣 등록해주세요')  // 본문 중간
Text('🥣🥣🥣')  // 반복 사용
```

---

## 3️⃣ 간격 시스템 (AppSpacing)

### 핵심 원칙

**간격은 디자인 언어다**

```dart
class AppSpacing {
  static const double xs = 4;   // 미세 간격 (거의 사용 안 함)
  static const double sm = 8;   // 아이콘-텍스트, 작은 요소 간
  static const double md = 12;  // 섹션 내부 그룹
  static const double lg = 16;  // 카드 내부 주요 구분, 페이지 padding
  static const double xl = 24;  // 카드 간, 페이지 섹션 간
}
```

### 사용 원칙

- **카드 내부 기본 padding** → `lg` (16)
- **카드 간 간격** → `lg` (16)
- **섹션 간 간격** → `xl` (24)
- **아이콘–텍스트** → `sm` (8)

### ❌ 금지 규칙

```dart
// ❌ 하드코딩된 간격 사용 금지
SizedBox(height: 20)  // ❌
SizedBox(width: 10)   // ❌
EdgeInsets.all(15)    // ❌

// ✅ 올바른 사용
SizedBox(height: AppSpacing.lg)  // ✅
SizedBox(width: AppSpacing.sm)   // ✅
EdgeInsets.all(AppSpacing.lg)    // ✅
```

---

## 4️⃣ AppRadius 가이드

### 핵심 원칙

**둥글수록 친절해 보인다, 하지만 과하면 유치하다**

```dart
class AppRadius {
  static const double sm = 8;   // 배지 / Chip
  static const double md = 12;  // 카드 / 버튼 (기본)
  static const double lg = 16;  // 바텀시트
  static const double xl = 20;  // 큰 바텀시트
}
```

### 적용 규칙

| 요소 | Radius | 예시 |
|------|--------|------|
| 카드 (CardContainer) | `md` (12) | 기본 카드 |
| 버튼 | `md` (12) | 모든 버튼 |
| 배지 / Chip | `sm` (8) | 상태 배지 |
| 바텀시트 | `lg` (16~20) | 모달 시트 |
| 아이콘 배경 | `sm` (8) | 아이콘 컨테이너 |

### ❌ 금지 규칙

- **radius 혼용 금지** (한 화면에서 여러 radius 사용 금지)
- **한 카드 안에서 radius 2종 이상 사용 금지**

```dart
// ✅ 올바른 사용
CardContainer(
  borderRadius: BorderRadius.circular(AppRadius.md),  // 일관된 radius
)

// ❌ 잘못된 사용
Container(
  borderRadius: BorderRadius.circular(8),  // 하드코딩
  child: Container(
    borderRadius: BorderRadius.circular(16),  // 혼용
  ),
)
```

---

## 5️⃣ AppElevation 가이드 (중요)

### 핵심 원칙

**헤이제노는 그림자를 거의 쓰지 않는다**

### 기본 원칙

- **Shadow ❌**
- **Border + Background 대비 ⭕**

```dart
class AppElevation {
  static const double none = 0;  // 기본값
}
```

### 예외적으로 허용되는 경우 (아주 제한적)

- BottomSheet
- Floating CTA

```dart
// 예외적 사용 (제한적)
BoxShadow(
  blurRadius: 8,
  color: Colors.black.withOpacity(0.05),
  offset: Offset(0, 2),
)
```

### ❌ 금지 규칙

👉 **홈 카드에는 절대 사용 금지**

```dart
// ✅ 올바른 사용 (Border 사용)
CardContainer(
  showBorder: true,  // Border로 구분
  backgroundColor: Colors.white,
)

// ❌ 잘못된 사용
Container(
  decoration: BoxDecoration(
    boxShadow: [...],  // 홈 카드에 Shadow 사용 금지
  ),
)
```

---

## 6️⃣ CardContainer 최종 규칙

### 기본 구조

```dart
CardContainer(
  padding: EdgeInsets.all(AppSpacing.lg),  // 기본 16px
  borderRadius: AppRadius.md,              // 기본 12px
  backgroundColor: AppColors.surface,      // 기본 White
  showBorder: true,                        // Border로 구분
  isHomeStyle: true,                       // 홈 화면 스타일 (선택)
  child: Column(...),
)
```

### 카드 디자인 원칙

- **카드마다 역할이 명확해야 함**
- **정보 밀도 ↑ / 장식 ↓**
- **타이틀은 항상 h3**

```dart
// ✅ 올바른 카드 구조
CardContainer(
  isHomeStyle: true,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('현재 급여 사료', style: AppTypography.h3),  // h3 타이틀
      const SizedBox(height: AppSpacing.md),
      Text('설명', style: AppTypography.body),
    ],
  ),
)
```

---

## 7️⃣ 홈 화면 전용 UI 원칙 (핵심)

### 핵심 원칙

**홈은 "추천 화면"이 아니다**

- 홈의 주인공은 **"현재 급여 사료"**
- 추천은 **문제 발생 시만** 등장
- 혜택은 **항상 하단, 보조**

### 홈 정보 우선순위

1. **현재 급여 사료** (메인)
2. **가격 / 소진 상태** (조건부)
3. **조건부 추천** (문제 발생 시만)
4. **혜택 / 포인트** (하단, 보조)

### 레이아웃 구조

```dart
Scaffold(
  body: SafeArea(
    child: Column(
      children: [
        // 1. 상단 고정 바
        const TopBar(title: '헤이제노'),
        
        // 2. 스크롤 가능한 콘텐츠
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  // 1️⃣ 펫 프로필 헤더
                  _buildPetSummaryHeader(),
                  const SizedBox(height: AppSpacing.md),
                  
                  // 2️⃣ 현재 급여 사료 카드 (메인)
                  _buildCurrentFoodCard(),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // 3️⃣ 상태 신호 카드 (조건부)
                  _buildStatusSignalCards(),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // 4️⃣ 추천 카드 (조건부, 문제 발생 시만)
                  if (_shouldShowRecommendation)
                    _buildRecommendationCard(),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // 5️⃣ 혜택 카드 (하단, 보조)
                  _buildBenefitsSection(),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  ),
)
```

---

## 8️⃣ 애니메이션 원칙 (헤이제노 스타일)

### 핵심 원칙

**빠르게 반응하고, 마무리는 부드럽게**

### Duration

- **짧은 액션**: 300ms
- **기본**: 400ms
- **긴 액션**: 500ms

### Curve

- **진입**: `Curves.easeOut`
- **상태 완료**: `Curves.easeOutBack` or `scale + opacity`

### 페이드인 애니메이션

```dart
TweenAnimationBuilder<double>(
  tween: Tween<double>(begin: 0.0, end: 1.0),
  duration: const Duration(milliseconds: 400),
  curve: Curves.easeOut,
  builder: (context, value, child) {
    return Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - value)),
        child: child,
      ),
    );
  },
  child: YourWidget(),
)
```

### 순차적 애니메이션

```dart
items.asMap().entries.map((entry) {
  final index = entry.key;
  return TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0.0, end: 1.0),
    duration: Duration(milliseconds: (200 + (index * 50)).toInt()),
    curve: Curves.easeOut,
    builder: (context, value, child) {
      return Opacity(
        opacity: value,
        child: Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: child,
        ),
      );
    },
    child: ItemWidget(items[index]),
  );
}).toList()
```

### ❌ 금지 규칙

- **Bounce 과다**
- **iOS스럽지 않은 튀는 효과**

---

## 9️⃣ 컴포넌트 가이드

### TopBar (상단 고정 바)

**용도**: 메인 탭 화면의 상단 고정 바

```dart
const TopBar(
  title: '헤이제노',
  hasNewNotifications: false,
  onNotificationTap: () {
    // 알림 화면으로 이동
  },
)
```

**특징**:
- 높이: 56px
- 알림 아이콘 포함 (오른쪽)
- 하단 경계선 포함
- iOS 스타일

**적용 화면**: 홈, 찜한 사료, 혜택, 더보기

---

### FigmaAppBar (서브 페이지용)

**용도**: 서브 페이지의 상단 바 (뒤로가기 버튼 포함)

```dart
const FigmaAppBar(
  title: '상품 상세',
  onBack: () => Navigator.pop(context),
)
```

---

### 버튼

#### CupertinoButton (Primary Blue - 결정/이동)

```dart
CupertinoButton(
  color: AppColors.primaryBlue,  // 결정/이동용
  borderRadius: BorderRadius.circular(AppRadius.md),
  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
  onPressed: () {},
  child: Text('비교해보기', style: AppTypography.button.copyWith(
    color: Colors.white,
  )),
)
```

#### OutlinedButton (테두리 버튼)

```dart
OutlinedButton(
  onPressed: () {},
  style: OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    side: const BorderSide(
      color: AppColors.primaryBlue,  // 결정/이동용
      width: 1.5,
    ),
  ),
  child: Text('비교해보기', style: AppTypography.button.copyWith(
    color: AppColors.primaryBlue,
  )),
)
```

---

## 🔟 타이포그래피

### 텍스트 스타일

| 스타일 | 크기 | 굵기 | 용도 | 예시 |
|--------|------|------|------|------|
| `h1` | 42px (모바일: 34px) | 900 | 메인 히어로 타이틀 | "헤이제노" |
| `h2` | 26px | 900 | 섹션 제목 | "오늘의 추천" |
| `h3` | 18px | 900 | 카드 제목 | "현재 급여 사료" |
| `body` | 16px | 400 | 본문 텍스트 | 일반 설명 |
| `body2` | 16px | 400 | 보조 본문 | 회색 텍스트 |
| `small` | 14px | 400 | 작은 텍스트 | 캡션, 부가 정보 |
| `caption` | 13px | 700 | 배지/칩 | "최저가" |
| `button` | 16px | 800 | 버튼 텍스트 | "등록하기" |

### 사용 예시

```dart
// 제목
Text('헤이제노', style: AppTypography.h2)

// 본문
Text('설명 텍스트', style: AppTypography.body)

// 보조 텍스트
Text('부가 정보', style: AppTypography.small.copyWith(
  color: AppColors.textSecondary,
))

// 버튼
Text('등록하기', style: AppTypography.button)
```

---

## ✅ 최종 체크리스트

새로운 화면/컴포넌트를 만들 때 확인:

- [ ] **PrimaryBlue / PetGreen 역할 구분했는가**
  - 결정/이동 → PrimaryBlue
  - 상태/안심 → PetGreen
  
- [ ] **이모지 1섹션 1개 지켰는가**
  - 섹션당 최대 1개
  - 본문 중간 사용 금지
  
- [ ] **AppSpacing만 사용했는가**
  - 하드코딩 간격 없음
  - SizedBox(height: 20) 금지
  
- [ ] **AppRadius 일관성 유지했는가**
  - 카드: md (12)
  - 버튼: md (12)
  - 배지: sm (8)
  
- [ ] **Shadow 제거했는가**
  - 홈 카드에 Shadow 사용 금지
  - Border로 구분
  
- [ ] **홈에서 "추천"이 과하지 않은가**
  - 현재 급여 사료가 메인
  - 추천은 조건부만
  
- [ ] **애니메이션 Duration/Curve 적절한가**
  - 300-500ms
  - Curves.easeOut
  
- [ ] **iOS 스타일 적용했는가**
  - CupertinoScrollbar + BouncingScrollPhysics
  - CupertinoButton 사용

---

## 📚 참고 파일

- `frontend/lib/app/theme/app_colors.dart` - 색상 정의
- `frontend/lib/app/theme/app_typography.dart` - 타이포그래피 정의
- `frontend/lib/app/theme/app_spacing.dart` - 간격 정의
- `frontend/lib/app/theme/app_radius.dart` - 반경 정의
- `frontend/lib/app/theme/app_shadows.dart` - 그림자 정의 (거의 사용 안 함)
- `frontend/lib/ui/widgets/top_bar.dart` - 상단 바 컴포넌트
- `frontend/lib/ui/widgets/card_container.dart` - 카드 컴포넌트

---

**버전**: v1.0 (Final)  
**마지막 업데이트**: 2024년
