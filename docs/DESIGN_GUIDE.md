# 쌤대신 디자인 가이드

이 문서는 디자인 시스템을 상세히 정리한 가이드입니다. 다른 프로젝트에 그대로 적용할 수 있도록 모든 디자인 토큰, 컴포넌트, 레이아웃 규칙을 포함합니다.

---

## 📋 목차

1. [디자인 토큰 (Design Tokens)](#1-디자인-토큰-design-tokens)
2. [색상 시스템](#2-색상-시스템)
3. [타이포그래피](#3-타이포그래피)
4. [간격 시스템](#4-간격-시스템)
5. [그림자 & 효과](#5-그림자--효과)
6. [컴포넌트 스타일](#6-컴포넌트-스타일)
7. [레이아웃 시스템](#7-레이아웃-시스템)
8. [반응형 디자인](#8-반응형-디자인)
9. [애니메이션 & 트랜지션](#9-애니메이션--트랜지션)
10. [구현 예제](#10-구현-예제)

---

## 1. 디자인 토큰 (Design Tokens)

### CSS 변수 정의

모든 디자인 토큰은 CSS 변수로 정의되어 있으며, `:root`에 선언됩니다.

```css
:root {
  /* 배경색 */
  --bg: #f7f8fb;
  --card: #ffffff;
  
  /* 텍스트 색상 */
  --text: #0f172a;
  --muted: #64748b;
  
  /* 경계선 */
  --line: #e5e7eb;
  
  /* Primary 색상 */
  --primary: #2563eb;
  --primary2: #1d4ed8;
  
  /* Border Radius */
  --radius: 18px;
  
  /* 그림자 */
  --shadow: 0 10px 30px rgba(15, 23, 42, 0.08);
  
  /* Chip/Badge 배경 */
  --chip: #eef2ff;
  
  /* AI 관련 색상 */
  --ai: #7c3aed;
  --ai2: #6d28d9;
  --aiChip: #f3e8ff;
}
```

---

## 2. 색상 시스템

### 기본 색상 팔레트

#### 배경색
- **Background (`--bg`)**: `#f7f8fb`
  - 메인 페이지 배경색
  - 부드러운 회색 톤으로 눈의 피로를 줄임

- **Card (`--card`)**: `#ffffff`
  - 카드, 모달 등 컨테이너 배경색
  - 순수한 흰색으로 콘텐츠를 강조

#### 텍스트 색상
- **Text (`--text`)**: `#0f172a`
  - 주요 텍스트 색상 (Slate 900)
  - 높은 가독성을 위한 진한 색상

- **Muted (`--muted`)**: `#64748b`
  - 보조 텍스트 색상 (Slate 500)
  - 설명, 부제목 등에 사용

#### 경계선
- **Line (`--line`)**: `#e5e7eb`
  - 경계선, 구분선 색상 (Gray 200)
  - 부드러운 구분을 위한 연한 회색

### Primary 색상

- **Primary (`--primary`)**: `#2563eb`
  - 메인 액션 색상 (Blue 600)
  - 버튼, 링크, 강조 요소에 사용

- **Primary Hover (`--primary2`)**: `#1d4ed8`
  - Primary의 호버 상태 (Blue 700)
  - 더 진한 톤으로 상호작용 피드백 제공

### AI 관련 색상

- **AI (`--ai`)**: `#7c3aed`
  - AI 기능 강조 색상 (Violet 600)
  - AI 섹션, 배지 등에 사용

- **AI Hover (`--ai2`)**: `#6d28d9`
  - AI의 호버 상태 (Violet 700)

- **AI Chip (`--aiChip`)**: `#f3e8ff`
  - AI 관련 칩/배지 배경색 (Violet 100)

### Chip/Badge 색상

- **Chip Background (`--chip`)**: `#eef2ff`
  - 일반 칩/배지 배경색 (Blue 100)

- **Chip Text**: `#1e3a8a` (Blue 900)
- **AI Chip Text**: `#4c1d95` (Violet 900)

### 투명도 사용

- **Primary Border**: `rgba(37, 99, 235, 0.18)` - Primary 색상의 18% 투명도
- **AI Border**: `rgba(124, 58, 237, 0.18)` - AI 색상의 18% 투명도
- **AI Border Strong**: `rgba(124, 58, 237, 0.22)` - AI 색상의 22% 투명도
- **Modal Overlay**: `rgba(15, 23, 42, 0.55)` - 배경 오버레이
- **Shadow**: `rgba(15, 23, 42, 0.08)` - 그림자 효과

### 그라데이션

#### Primary 그라데이션
```css
background: linear-gradient(180deg, rgba(37, 99, 235, 0.06), rgba(255, 255, 255, 0.92));
border: 1px solid rgba(37, 99, 235, 0.18);
```

#### AI 그라데이션
```css
background:
  radial-gradient(900px 240px at 12% 0%, rgba(124, 58,237, 0.14), transparent 55%),
  radial-gradient(700px 260px at 88% 10%, rgba(37, 99, 235, 0.08), transparent 55%),
  linear-gradient(180deg, rgba(255, 255, 255, 1), rgba(248, 250, 252, 1));
border: 1px solid rgba(124, 58, 237, 0.18);
```

---

## 3. 타이포그래피

### 폰트 패밀리

```css
font-family: system-ui, -apple-system, "Segoe UI", Roboto, "Noto Sans KR", sans-serif;
```

- 시스템 기본 폰트 우선 사용
- 한국어 지원을 위해 "Noto Sans KR" 포함
- 폴백으로 sans-serif 사용

### 폰트 크기

#### 제목 (Headings)
- **H1**: `42px` (모바일: `34px`)
  - 메인 히어로 섹션 제목
  - `letter-spacing: -1px` (자간 조정)
  - `margin: 0 0 12px`

- **H2**: `26px`
  - 섹션 제목
  - `letter-spacing: -0.5px`
  - `margin: 0 0 10px`

- **H3**: `18px`
  - 서브 섹션 제목
  - `letter-spacing: -0.2px`
  - `margin: 20px 0 10px` (첫 번째는 `margin-top: 0`)

#### 본문
- **Lead**: `17px`
  - 강조되는 본문 텍스트
  - `color: var(--muted)`
  - `margin: 0 0 18px`

- **Body**: 기본 (보통 `16px`)
  - 일반 본문 텍스트
  - `line-height: 1.6` (메인 페이지)
  - `line-height: 1.75` (약관/개인정보 페이지)

- **Small**: `14px`
  - 작은 설명 텍스트
  - Footer 등에 사용

- **Badge/Chip**: `13px`
  - 배지, 칩 텍스트
  - `font-weight: 700` 또는 `800`

### 폰트 굵기

- **900 (Black)**: 브랜드명, 주요 CTA 버튼, 제목
- **800 (Extra Bold)**: 배지, 칩, 강조 텍스트
- **700 (Bold)**: 배지, 칩, 네비게이션 링크
- **600 (Semi Bold)**: 기본 (명시되지 않은 경우)
- **400 (Regular)**: 본문 텍스트

### Line Height

- **본문**: `1.6` (메인 페이지)
- **약관/법적 문서**: `1.75` (가독성 향상)

---

## 4. 간격 시스템

### 패딩 (Padding)

#### 컨테이너
- **Wrap Padding**: `28px 18px 80px`
  - 상단: `28px`
  - 좌우: `18px`
  - 하단: `80px`

- **Nav Padding**: `14px 18px` (모바일: `12px 14px`)

#### 카드
- **Card Padding**: `28px`
- **Item Padding**: `16px`
- **Panel Padding**: `18px` (모달)
- **Callout Padding**: `18px` 또는 `16px`

#### 버튼
- **Primary Button**: `12px 16px`
- **Nav CTA**: `10px 12px` (모바일: `9px 10px`)
- **Modal Button**: `10px 12px`

#### 칩/배지
- **Badge**: `6px 12px` (모바일: `6px 10px`)
- **Chip**: `8px 10px`
- **AI Badge**: `6px 12px`
- **AI Kicker**: `7px 10px`

### 마진 (Margin)

#### 섹션 간격
- **Section Margin Top**: `32px`
- **Section Margin Top (약관)**: `18px`

#### 요소 간격
- **Hero Margin Top**: `28px`
- **Card Margin Top**: `14px` (일반)
- **Item Margin**: `0` (카드 내부)
- **List Item Margin**: `8px 0` (일반), `6px 0` (약관)

#### 그리드 간격
- **Grid Gap**: `14px`
- **Step Grid Gap**: `14px`
- **Button Row Gap**: `10px`
- **Nav Gap**: `12px` (내부), `10px` (요소 간)

### Gap (Flexbox/Grid)

- **Nav Inner Gap**: `12px`
- **Nav Right Gap**: `10px`
- **Button Row Gap**: `10px`
- **Grid Gap**: `14px`
- **Step Gap**: `14px`
- **Chips Gap**: `8px`
- **Footer Links Gap**: `10px`

---

## 5. 그림자 & 효과

### 그림자

#### 기본 카드 그림자
```css
--shadow: 0 10px 30px rgba(15, 23, 42, 0.08);
```

#### 버튼 그림자
```css
box-shadow: 0 10px 22px rgba(37, 99, 235, 0.18);
```

#### AI 마크 그림자
```css
box-shadow: 0 10px 22px rgba(124, 58, 237, 0.18);
```

#### 모달 그림자
```css
box-shadow: 0 18px 60px rgba(15, 23, 42, 0.25);
```

### Border Radius

- **기본 Radius (`--radius`)**: `18px`
  - 카드, 모달 등 주요 컨테이너

- **버튼 Radius**: `14px` (일반), `12px` (모달)
- **Nav CTA Radius**: `999px` (완전한 둥근 모서리)
- **Chip/Badge Radius**: `999px`
- **Step Num Radius**: `10px`
- **Media Radius**: `14px`
- **Panel Radius**: `16px`
- **Callout Radius**: `16px` 또는 `18px`
- **Code Radius**: `8px`

### Border

- **기본 Border**: `1px solid var(--line)`
- **Primary Border**: `1px solid rgba(37, 99, 235, 0.18)`
- **AI Border**: `1px solid rgba(124, 58, 237, 0.18)`
- **AI Border Strong**: `1px solid rgba(124, 58, 237, 0.22)`
- **Dashed Border**: `1px dashed var(--line)` (약관 섹션 구분)

---

## 6. 컴포넌트 스타일

### 네비게이션 (Navigation)

#### 구조
```css
.nav {
  position: sticky;
  top: 0;
  z-index: 10;
  background: #fff;
  border-bottom: 1px solid var(--line);
}

.navInner {
  max-width: 1040px;
  margin: 0 auto;
  padding: 14px 18px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}
```

#### 브랜드
```css
.brand {
  display: flex;
  align-items: center;
  gap: 10px;
  font-weight: 900;
  font-size: 18px; /* 모바일: 16px */
  white-space: nowrap;
}

.brand img {
  height: 36px; /* 모바일: 32px */
  width: auto;
}
```

#### Nav CTA 버튼
```css
.navCta {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 10px 12px; /* 모바일: 9px 10px */
  border-radius: 999px;
  font-weight: 900;
  font-size: 13px; /* 모바일: 12px */
  color: #fff;
  background: var(--primary);
  border: 1px solid var(--primary);
  box-shadow: 0 10px 22px rgba(37, 99, 235, 0.18);
  white-space: nowrap;
  transition: transform 0.06s ease, background 0.12s ease, border-color 0.12s ease;
}

.navCta:hover {
  transform: translateY(-1px);
  background: var(--primary2);
  border-color: var(--primary2);
}
```

#### 배지
```css
.badge {
  font-size: 13px; /* 모바일: 12px */
  padding: 6px 12px; /* 모바일: 6px 10px */
  border-radius: 999px;
  background: var(--chip);
  color: #1e3a8a;
  font-weight: 700;
  border: 1px solid rgba(37, 99, 235, 0.18);
  white-space: nowrap;
}
```

### 카드 (Card)

```css
.card {
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: var(--radius);
  padding: 28px;
  box-shadow: var(--shadow);
}
```

### 버튼 (Button)

#### 기본 버튼
```css
.btn {
  padding: 12px 16px;
  border-radius: 14px;
  font-weight: 800;
  border: 1px solid var(--line);
  background: #fff;
  transition: transform 0.06s ease, background 0.12s ease, border-color 0.12s ease;
  cursor: pointer;
}

.btn:hover {
  transform: translateY(-1px);
}
```

#### Primary 버튼
```css
.btn.primary {
  background: var(--primary);
  color: #fff;
  border-color: var(--primary);
}

.btn.primary:hover {
  background: var(--primary2);
  border-color: var(--primary2);
}
```

#### Subtle 버튼
```css
.btn.subtle {
  background: #fff;
  border-color: #dbe3f4;
}
```

#### 버튼 행
```css
.btnRow {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-top: 14px;
}
```

### 칩 (Chip)

```css
.chip {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  padding: 8px 10px;
  border-radius: 999px;
  background: var(--chip);
  border: 1px solid rgba(37, 99, 235, 0.18);
  color: #1e3a8a;
  font-weight: 700;
  white-space: nowrap;
}

.chips {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 12px;
}
```

### Callout 박스

```css
.callout {
  margin-top: 14px;
  border: 1px solid rgba(37, 99, 235, 0.22);
  background: linear-gradient(180deg, rgba(37, 99, 235, 0.08), rgba(255, 255, 255, 0.92));
  border-radius: 18px;
  padding: 18px;
}

.callout p {
  margin: 6px 0;
  color: var(--muted);
}

.callout b {
  color: #0f172a;
}
```

### Warm Line (따뜻한 메시지 박스)

```css
.warmLine {
  margin-top: 14px;
  padding: 14px 14px;
  border-radius: 16px;
  border: 1px solid rgba(37, 99, 235, 0.18);
  background: linear-gradient(180deg, rgba(37, 99, 235, 0.06), rgba(255, 255, 255, 0.92));
  color: var(--muted);
}

.warmLine b {
  color: #0f172a;
}
```

### Step (단계 표시)

```css
.step {
  display: flex;
  gap: 14px;
  align-items: flex-start;
}

.stepNum {
  width: 32px;
  height: 32px;
  border-radius: 10px;
  background: var(--chip);
  color: #1d4ed8;
  font-weight: 900;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  border: 1px solid rgba(37, 99, 235, 0.18);
}

.step p {
  margin: 4px 0 0;
  color: var(--muted);
}
```

### Item (그리드 아이템)

```css
.item {
  border: 1px solid var(--line);
  border-radius: 16px;
  background: #fff;
  padding: 16px;
}

.item b {
  display: block;
  margin-bottom: 6px;
}

.item p {
  margin: 0;
  color: var(--muted);
}
```

### Media (이미지/비디오)

```css
.media {
  margin-top: 10px;
  border-radius: 14px;
  overflow: hidden;
  border: 1px solid var(--line);
  background: #fff;
}

.media img,
.media video {
  width: 100%;
  display: block;
}
```

### AI 섹션 컴포넌트

#### AI Wrap
```css
.aiWrap {
  border: 1px solid rgba(124, 58, 237, 0.18);
  background:
    radial-gradient(900px 240px at 12% 0%, rgba(124, 58, 237, 0.14), transparent 55%),
    radial-gradient(700px 260px at 88% 10%, rgba(37, 99, 235, 0.08), transparent 55%),
    linear-gradient(180deg, rgba(255, 255, 255, 1), rgba(248, 250, 252, 1));
}
```

#### AI Mark
```css
.aiMark {
  width: 34px;
  height: 34px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 900;
  color: #fff;
  background: linear-gradient(135deg, var(--ai), var(--primary));
  box-shadow: 0 10px 22px rgba(124, 58, 237, 0.18);
}
```

#### AI Badge
```css
.aiBadge {
  font-size: 13px;
  padding: 6px 12px;
  border-radius: 999px;
  background: var(--aiChip);
  color: #4c1d95;
  border: 1px solid rgba(124, 58, 237, 0.22);
  font-weight: 800;
  white-space: nowrap;
}
```

#### AI Panel
```css
.aiPanel {
  border: 1px solid rgba(124, 58, 237, 0.18);
  border-radius: 16px;
  background: #fff;
  padding: 16px;
}

.aiPanel h3 {
  margin: 0 0 6px;
  font-size: 18px;
  letter-spacing: -0.2px;
}

.aiPanel p {
  margin: 0;
  color: var(--muted);
}
```

#### AI Kicker
```css
.aiKicker {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  padding: 7px 10px;
  border-radius: 999px;
  background: rgba(124, 58, 237, 0.08);
  border: 1px solid rgba(124, 58, 237, 0.18);
  color: #4c1d95;
  font-weight: 800;
  margin: 10px 0 0;
}
```

### 모달 (Modal)

#### Overlay
```css
.modalOverlay {
  position: fixed;
  inset: 0;
  background: rgba(15, 23, 42, 0.55);
  display: none;
  align-items: center;
  justify-content: center;
  padding: 18px;
  z-index: 9999;
}
```

#### Modal
```css
.modal {
  width: 100%;
  max-width: 520px;
  background: #fff;
  border: 1px solid var(--line);
  border-radius: 18px;
  box-shadow: 0 18px 60px rgba(15, 23, 42, 0.25);
  padding: 18px;
}

.modalTitle {
  margin: 0 0 6px;
  font-weight: 900;
  letter-spacing: -0.3px;
}

.modalBody {
  margin: 0 0 14px;
  color: var(--muted);
}

.modalActions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  flex-wrap: wrap;
}

.modalActions .btn {
  padding: 10px 12px;
  border-radius: 12px;
}
```

### Footer

```css
footer {
  margin-top: 40px;
  padding-top: 20px;
  border-top: 1px solid var(--line);
  color: var(--muted);
  font-size: 14px;
  display: flex;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 10px;
  align-items: center;
}

.footerLinks {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
  align-items: center;
}

.footerLinks a {
  color: var(--muted);
}

.footerLinks a:hover {
  color: #334155;
}
```

### 리스트 (List)

```css
.list {
  padding-left: 18px;
  color: var(--muted);
  margin: 0;
}

.list li {
  margin: 8px 0;
}
```

---

## 7. 레이아웃 시스템

### 컨테이너

#### Wrap (메인 컨테이너)
```css
.wrap {
  max-width: 1040px;
  margin: 0 auto;
  padding: 28px 18px 80px;
}
```

#### Nav Inner
```css
.navInner {
  max-width: 1040px;
  margin: 0 auto;
  padding: 14px 18px;
}
```

### 그리드 레이아웃

#### Hero Grid
```css
.hero {
  margin-top: 28px;
  display: grid;
  grid-template-columns: 1.2fr 1fr;
  gap: 20px;
}
```

#### Step Grid
```css
.stepGrid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 14px;
  margin-top: 16px;
}
```

#### Grid 2
```css
.grid2 {
  margin-top: 14px;
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 14px;
}
```

#### AI Grid
```css
.aiGrid {
  margin-top: 14px;
  display: grid;
  grid-template-columns: 1.1fr 0.9fr;
  gap: 14px;
}
```

### CTA Card

```css
.ctaCard {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  flex-wrap: wrap;
}
```

---

## 8. 반응형 디자인

### 브레이크포인트

- **모바일**: `max-width: 520px`
- **태블릿**: `max-width: 900px`
- **데스크톱**: `900px` 이상

### 모바일 스타일 (`max-width: 520px`)

```css
@media (max-width: 520px) {
  .navInner {
    padding: 12px 14px;
  }
  
  .brand {
    font-size: 16px;
  }
  
  .brand img {
    height: 32px;
  }
  
  .navCta {
    padding: 9px 10px;
    font-size: 12px;
  }
  
  .badge {
    padding: 6px 10px;
    font-size: 12px;
  }
  
  h1 {
    font-size: 34px;
  }
}
```

### 태블릿 스타일 (`max-width: 900px`)

```css
@media (max-width: 900px) {
  .hero {
    grid-template-columns: 1fr;
  }
  
  .stepGrid {
    grid-template-columns: 1fr;
  }
  
  .grid2 {
    grid-template-columns: 1fr;
  }
  
  .aiGrid {
    grid-template-columns: 1fr;
  }
}
```

### 모바일 최소 너비 (`max-width: 420px`)

```css
@media (max-width: 420px) {
  h1 {
    font-size: 34px;
  }
}
```

---

## 9. 애니메이션 & 트랜지션

### 트랜지션

#### 버튼 트랜지션
```css
transition: transform 0.06s ease, background 0.12s ease, border-color 0.12s ease;
```

- **Transform**: `0.06s ease` - 빠른 피드백
- **Background/Border**: `0.12s ease` - 부드러운 색상 변화

#### 호버 효과
```css
.btn:hover {
  transform: translateY(-1px);
}
```

- 버튼이 살짝 위로 올라가는 효과
- 시각적 피드백 제공

### 애니메이션 사용 예

- **비디오**: `autoplay muted loop playsinline` 속성 사용
- **모달**: JavaScript로 `display: flex/none` 토글

---

## 10. 구현 예제

### 완전한 HTML 템플릿

```html
<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>프로젝트 이름</title>
  
  <style>
    :root {
      --bg: #f7f8fb;
      --card: #ffffff;
      --text: #0f172a;
      --muted: #64748b;
      --line: #e5e7eb;
      --primary: #2563eb;
      --primary2: #1d4ed8;
      --radius: 18px;
      --shadow: 0 10px 30px rgba(15, 23, 42, 0.08);
      --chip: #eef2ff;
      --ai: #7c3aed;
      --ai2: #6d28d9;
      --aiChip: #f3e8ff;
    }

    * {
      box-sizing: border-box;
    }

    body {
      margin: 0;
      font-family: system-ui, -apple-system, "Segoe UI", Roboto, "Noto Sans KR", sans-serif;
      background: var(--bg);
      color: var(--text);
      line-height: 1.6;
    }

    a {
      color: inherit;
      text-decoration: none;
    }

    .wrap {
      max-width: 1040px;
      margin: 0 auto;
      padding: 28px 18px 80px;
    }

    .card {
      background: var(--card);
      border: 1px solid var(--line);
      border-radius: var(--radius);
      padding: 28px;
      box-shadow: var(--shadow);
    }

    h1 {
      margin: 0 0 12px;
      font-size: 42px;
      letter-spacing: -1px;
    }

    .lead {
      color: var(--muted);
      font-size: 17px;
      margin: 0 0 18px;
    }

    .btn {
      padding: 12px 16px;
      border-radius: 14px;
      font-weight: 800;
      border: 1px solid var(--line);
      background: #fff;
      transition: transform 0.06s ease, background 0.12s ease, border-color 0.12s ease;
      cursor: pointer;
    }

    .btn:hover {
      transform: translateY(-1px);
    }

    .btn.primary {
      background: var(--primary);
      color: #fff;
      border-color: var(--primary);
    }

    .btn.primary:hover {
      background: var(--primary2);
      border-color: var(--primary2);
    }

    @media (max-width: 900px) {
      .hero {
        grid-template-columns: 1fr;
      }
    }

    @media (max-width: 520px) {
      h1 {
        font-size: 34px;
      }
    }
  </style>
</head>
<body>
  <div class="wrap">
    <div class="card">
      <h1>프로젝트 제목</h1>
      <p class="lead">프로젝트 설명</p>
      <button class="btn primary">시작하기</button>
    </div>
  </div>
</body>
</html>
```

### CSS 변수만 사용하기

```css
/* 다른 프로젝트에 적용할 때는 이 변수들만 복사하면 됩니다 */
:root {
  --bg: #f7f8fb;
  --card: #ffffff;
  --text: #0f172a;
  --muted: #64748b;
  --line: #e5e7eb;
  --primary: #2563eb;
  --primary2: #1d4ed8;
  --radius: 18px;
  --shadow: 0 10px 30px rgba(15, 23, 42, 0.08);
  --chip: #eef2ff;
  --ai: #7c3aed;
  --ai2: #6d28d9;
  --aiChip: #f3e8ff;
}
```

---

## 📝 사용 가이드라인

### 색상 사용

1. **Primary 색상**은 주요 액션(버튼, 링크)에만 사용
2. **Muted 색상**은 보조 텍스트, 설명에 사용
3. **AI 색상**은 AI 관련 기능에만 사용하여 구분

### 간격 사용

1. **14px**는 가장 자주 사용되는 간격 (그리드, 요소 간)
2. **28px**는 섹션, 카드 패딩에 사용
3. **10px**는 작은 요소 간 간격 (버튼, 칩)

### 컴포넌트 사용

1. **Card**는 모든 주요 콘텐츠를 감싸는 컨테이너
2. **Button**은 항상 `.btnRow` 내에서 사용
3. **Chip**은 `.chips` 컨테이너 내에서 사용

### 반응형 고려사항

1. 모든 그리드는 모바일에서 1열로 변경
2. 폰트 크기는 모바일에서 약간 작아짐
3. 패딩은 모바일에서 약간 줄어듦

---

## 🎨 디자인 철학

1. **명확성**: 정보의 계층 구조가 명확함
2. **일관성**: 모든 페이지에서 동일한 디자인 토큰 사용
3. **접근성**: 충분한 대비와 가독성 확보
4. **부드러움**: 둥근 모서리와 부드러운 그림자로 친근한 느낌
5. **효율성**: 최소한의 스타일로 최대의 효과

---

## 📚 참고 자료

- 실제 구현: `ssamdaeshin-landing/index.html`
- 개인정보처리방침: `ssamdaeshin-landing/privacy/index.html`
- 이용약관: `ssamdaeshin-landing/terms/terms.html`

---

**마지막 업데이트**: 2025년 1월
