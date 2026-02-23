# UI 리디자인 진행 상황

## ✅ 완료된 작업

### PR 1: Design System 토큰 확정 ✅
- Typography H1을 28~32로 명시
- BadgePill 별칭 추가
- 모든 토큰 확인 및 보완 완료

### PR 2: ThemeData 통일 ✅
- TextTheme을 Design System Typography로 업데이트
- 영어 기본 폰트(Roboto) 설정
- ButtonTheme에 Design System Typography 적용
- 색상 팔레트 유지 확인

### PR 3: 버튼 컴포넌트 단일화 ✅
- Design System PrimaryButton에 `isSmall`, `width` 옵션 추가
- 기존 버튼들 Deprecated 표시
- 주요 사용처 마이그레이션 완료

### PR 4: 카드 컴포넌트 단일화 ✅
- `CardContainer` Deprecated 표시
- 주요 사용처를 `AppCard`로 마이그레이션

### PR 5: EmptyState & SectionHeader 단일화 ✅
- 기존 컴포넌트들 Deprecated 표시
- Design System 컴포넌트로 통일

### PR 6: Bottom Tab 재정의 ✅
- 5탭 → 4탭 구조로 변경 (Home, Find, Deals, Alerts)
- 라우터 브랜치 재구성
- 탭 아이콘/라벨 변경
- Legacy 경로 리다이렉트 설정

**⚠️ 주의사항**:
- Find 탭 화면은 현재 HomeScreen을 임시로 사용 중
- 별도 Find 화면 생성 필요 (추천 시작 화면)
- l10n 파일 생성 필요 (`flutter gen-l10n` 실행)

---

## 🔄 진행 중

### PR 7: Home 화면 리디자인
- Rover/Chewy 스타일로 재배치
- 여백 + 카드 중심 + 신뢰 톤

---

## 📋 남은 작업

### PR 8: Find/Deals/Alerts 화면 리디자인
- Find 탭: 추천 화면 리디자인
- Deals 탭: 최저가 비교 화면 리디자인
- Alerts 탭: 알림 화면 리디자인

### PR 9: 미국 현지화
- i18n + 포맷터 (USD, lb, US date/time)
- 하드코딩 문자열 → l10n 키 치환

### PR 10: QA 체크리스트
- 이미 작성 완료 (`frontend/docs/UI_REDESIGN_QA_CHECKLIST.md`)

---

## 🚨 알려진 이슈

1. **l10n 파일 생성 필요**: `flutter gen-l10n` 실행 필요
2. **Find 탭 화면**: 별도 화면 생성 필요 (현재 HomeScreen 임시 사용)
3. **점진적 마이그레이션**: 일부 컴포넌트는 Deprecated 표시만 하고 사용처 마이그레이션은 점진적으로 진행

---

## 📝 다음 단계

1. PR 7 완료 (Home 화면 리디자인)
2. Find 탭 전용 화면 생성
3. PR 8 진행 (Find/Deals/Alerts 화면 리디자인)
4. PR 9 진행 (미국 현지화)
5. l10n 파일 생성 및 최종 QA
