# UI 리디자인 QA 체크리스트

## ✅ 1. Bottom Tab 구조 확인

### 탭 구성
- [ ] **Home 탭**: house 아이콘, "Home" 라벨
- [ ] **Match 탭**: sparkles (auto_awesome) 아이콘, "Match" 라벨
- [ ] **Market 탭**: shopping_bag 아이콘, "Market" 라벨
- [ ] **Alerts 탭**: bell 아이콘, "Alerts" 라벨

### 네비게이션
- [ ] 각 탭 클릭 시 해당 화면으로 이동
- [ ] 탭 간 전환 시 상태 유지 (StatefulShellRoute.indexedStack)
- [ ] Legacy 경로 리다이렉트 확인:
  - [ ] `/find` → `/match`
  - [ ] `/deals` → `/market`
  - [ ] `/watch` → `/alerts`
  - [ ] `/market` → `/market` (유지)

### More 탭 제거
- [ ] 하단 탭에 "More" 없음
- [ ] Home 우상단 프로필 아이콘으로 접근 가능
- [ ] `/me` 경로로 접근 가능

---

## ✅ 2. Market 탭 USP 확인

### 헤더 구조
- [ ] Title: "Market"
- [ ] Subtitle: "Compare prices across Amazon, Chewy, Petco & more"
- [ ] Subtitle이 명확히 보임 (회색 텍스트, 14px)

### 상품 카드
- [ ] 카드 리스트 형태 (그리드보다 우선)
- [ ] 상품 클릭 시 상세 페이지로 이동
- [ ] 상세 페이지에서 멀티플랫폼 가격 비교 표시 (TODO: 구현 필요)

### 검색 및 필터
- [ ] 검색 바 정상 동작
- [ ] 카테고리 필터 칩 정상 동작
- [ ] 빈 검색 결과 시 EmptyState 표시

---

## ✅ 3. Match 탭 확인

### 헤더
- [ ] sparkles 아이콘 (auto_awesome) 표시
- [ ] 제목: "Find the perfect match for {petName}" 또는 "Let's match {petName} with better nutrition"
- [ ] 서브텍스트 표시

### 추천 결과
- [ ] 숫자 나열 금지 (요약 문장 + 배지 형태)
- [ ] 점수는 기본 숨김
- [ ] 상세에서만 점수/성분 수치 공개

### AI 매칭 느낌
- [ ] sparkles 아이콘으로 AI 느낌 강조
- [ ] 카드형 필터/질문 흐름
- [ ] "신뢰 카드 리스트" 스타일

---

## ✅ 4. Home 화면 Rover 스타일 확인

### Hero 영역
- [ ] "Hey {petName}! 🐾" 큰 헤더
- [ ] "Ready to find food that fits?" 서브텍스트
- [ ] 적절한 여백 (24px 이상)

### Pet Summary Card
- [ ] 큰 원형 이미지 (80x80)
- [ ] 한 줄 요약: "{petName} • Senior • 30.2 lb • Neutered"
- [ ] 건강고민 최대 2개 + '+N more'
- [ ] 알레르기: "Avoid: Pork, Beef" 형태

### Current Food Card
- [ ] "What's {petName} eating right now?" 제목
- [ ] "We'll compare ingredients and track the best price." 서브텍스트
- [ ] "Add current food" 버튼

### Recommendation CTA
- [ ] "Find {petName}'s best match" 제목
- [ ] "Personalized for allergies, age, and health needs." 서브텍스트
- [ ] "Get recommendations" 버튼

### Alerts Preview
- [ ] "Alerts" 섹션 헤더
- [ ] 최대 2개 알림 표시 (TODO: 실제 데이터 연동)
- [ ] "See all alerts" 링크 → Alerts 탭 이동

### 여백
- [ ] Screen padding: 24px 이상
- [ ] 카드 간 간격: 16~24px
- [ ] 섹션 간 간격: 24~40px

---

## ✅ 5. i18n (미국 현지화) 확인

### 기본 Locale
- [ ] en_US가 기본 Locale
- [ ] flutter_localizations 설정 완료
- [ ] AppLocalizations.delegate 포함

### 단위 변환
- [ ] 무게: kg → lb 표시 (예: "30.2 lb")
- [ ] 통화: USD 포맷 (예: "$29.99")
- [ ] 날짜: MMM d, yyyy (예: "Jan 15, 2024")
- [ ] 시간: 12h AM/PM (예: "2:30 PM")

### 내부 계산
- [ ] 내부 계산 로직은 변경 없음 (표시만 변환)
- [ ] kg → lb 변환은 표시용만 (Formatters.weightLb)

### 하드코딩 문자열
- [ ] 주요 화면에서 하드코딩 문자열 제거
- [ ] l10n 키 사용 (일부 TODO 남아있음)

---

## ✅ 6. 컴포넌트 단일화 확인

### 버튼
- [ ] PrimaryButton만 사용 (AppPrimaryButton 사용 안 함)
- [ ] SecondaryButton 사용
- [ ] 버튼 높이: 48~56px
- [ ] Pill 형태 (rounded-full)

### 카드
- [ ] AppCard만 사용 (CardContainer 사용 안 함)
- [ ] 카드 radius: 20~24px
- [ ] Soft shadow 적용

### EmptyState
- [ ] EmptyState 컴포넌트만 사용
- [ ] EmptyStateWidget 사용 안 함
- [ ] 친근한 영어 메시지
- [ ] 단일 액션 버튼

### SectionHeader
- [ ] SectionHeader 컴포넌트만 사용
- [ ] FigmaSectionHeader 사용 안 함

### Design Tokens
- [ ] 매직 넘버 padding/radius 제거
- [ ] DesignTokens.Spacing 사용
- [ ] DesignTokens.BorderRadiusTokens 사용
- [ ] DesignTokens.Elevation 사용

---

## ✅ 7. 색상 팔레트 유지 확인

- [ ] 기존 ColorScheme 값 그대로 유지
- [ ] DesignColors는 기존 AppColors 값 재사용
- [ ] 색상 값 변경 없음

---

## ✅ 8. 기능 로직 변경 없음 확인

- [ ] 데이터 흐름 변경 없음
- [ ] API 호출 로직 변경 없음
- [ ] 상태 관리 로직 변경 없음
- [ ] 라우팅 로직 변경 없음 (경로만 변경)
- [ ] 비즈니스 규칙 변경 없음

---

## ✅ 9. 반응형 확인

- [ ] 모바일 (기본): 정상 표시
- [ ] 태블릿 (640px+): 여백 확대 (32px)
- [ ] 텍스트 오버플로우 처리
- [ ] 긴 영어 문장 줄바꿈

---

## ✅ 10. 성능 확인

- [ ] 화면 전환 부드러움
- [ ] 스크롤 성능
- [ ] 이미지 로딩
- [ ] 메모리 사용량

---

## 📝 테스트 시나리오

### 시나리오 1: 탭 네비게이션
1. 앱 실행
2. Home 탭 확인
3. Match 탭 클릭 → Match 화면 이동
4. Market 탭 클릭 → Market 화면 이동
5. Alerts 탭 클릭 → Alerts 화면 이동
6. 각 탭에서 뒤로가기 → 탭 유지

### 시나리오 2: Market USP 확인
1. Market 탭 진입
2. "Compare prices across Amazon, Chewy, Petco & more" 서브텍스트 확인
3. 상품 검색
4. 상품 카드 클릭
5. 상세 페이지에서 가격 비교 확인 (TODO)

### 시나리오 3: Match AI 느낌
1. Match 탭 진입
2. sparkles 아이콘 확인
3. "Find the perfect match for {petName}" 헤더 확인
4. 추천 시작 버튼 클릭
5. 추천 결과에서 숫자 나열 없음 확인

### 시나리오 4: Home Rover 스타일
1. Home 탭 진입
2. Hero Section 확인 ("Hey {petName}! 🐾")
3. Pet Summary Card 확인 (큰 원형 이미지, 한 줄 요약)
4. Current Food Card 확인
5. Recommendation CTA 확인
6. Alerts Preview 확인
7. 여백 확인 (24px 이상)

### 시나리오 5: 단위 변환
1. Home 화면에서 무게 확인 (lb 표시)
2. 가격 확인 (USD 포맷)
3. 날짜 확인 (US 포맷)
4. 시간 확인 (12h AM/PM)

---

## 🎯 완료 기준

- [x] 4탭 구조 정상 동작
- [x] Market에서 비교 구조 명확히 보임
- [x] Match가 검색이 아닌 추천 엔진으로 보임
- [x] Home에서 Rover 체감
- [x] 영어 기본, USD/lb/US date/time 포맷 적용
- [x] 기능 로직 변화 없음

**모든 체크리스트 항목을 확인하세요!** ✅
