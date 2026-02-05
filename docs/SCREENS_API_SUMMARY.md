# 📱 화면별 기능 및 API 정리

## 1. 초기 스플래시 (InitialSplashScreen)
**기능**
- 헤이제노 로고 3초 표시
- 온보딩 완료 여부 확인 후 라우팅

**API**
- 없음 (로컬 스토리지 확인)

---

## 2. 온보딩 (OnboardingFlow)
**기능**
- 11단계 회원가입 프로세스
- 닉네임, 펫 정보, 건강 정보 수집
- 사진 업로드 (선택)

**API**
- `POST /onboarding/complete` - 온보딩 완료

---

## 3. 홈 (HomeScreen)
**기능**
- Primary Pet 정보 표시
- 맞춤 추천 상품 Top 1 표시
- 추천 상품 상세보기

**API**
- `GET /pets/primary` - Primary Pet 조회
- `GET /products/recommendations?pet_id={id}` - 추천 상품 목록

**상태**
- 로딩 / Pet 있음 / Pet 없음 / 에러

---

## 4. 관심 (WatchScreen)
**기능**
- 찜한 사료 목록 표시
- 정렬 (맞춤 점수, 최저가, 안정 가격, 인기)
- 가격 알림 토글
- 평균 대비 저렴한 상품 개수 표시

**API**
- `GET /trackings` - 추적 목록 조회
- `GET /products/{id}` - 상품 상세 (각 추적별)
- `DELETE /trackings/{id}` - 추적 삭제

---

## 5. 마켓 (MarketScreen)
**기능**
- 전체 상품 목록 표시
- 핫딜, 인기 상품 섹션
- 카테고리 필터 (전체/강아지/고양이 등)
- 검색 기능

**API**
- `GET /products` - 상품 목록 조회

---

## 6. 혜택 (BenefitsScreen)
**기능**
- 포인트 잔액 표시
- 미션 목록 및 완료 상태
- 포인트 사용 방법 안내

**API**
- 없음 (현재 Mock 데이터)

---

## 7. 마이 (MyScreen)
**기능**
- 사용자 프로필 정보
- 펫 건강 리포트 요약
- 최근 추천 히스토리
- 알림 설정
- 포인트 잔액

**API**
- 없음 (현재 Mock 데이터)

---

## 8. 상품 상세 (ProductDetailScreen)
**기능**
- 상품 이미지, 정보 표시
- 가격 추이 그래프
- 맞춤 점수 및 분석
- 영양 성분 표시
- 찜하기/가격 알림 설정
- 최저가 구매 링크

**API**
- `GET /products/{id}` - 상품 상세 조회
- `GET /products/{id}/offers` - 판매처 목록
- `POST /trackings` - 추적 시작
- `POST /clicks` - 클릭 로그

---

## 📊 API 엔드포인트 전체 목록

### Pets
- `GET /pets/primary` - Primary Pet 조회
- `GET /pets` - Pet 목록
- `POST /pets` - Pet 생성

### Products
- `GET /products` - 상품 목록
- `GET /products/{id}` - 상품 상세
- `GET /products/recommendations?pet_id={id}` - 추천 상품
- `GET /products/{id}/offers` - 판매처 목록

### Trackings
- `GET /trackings` - 추적 목록
- `POST /trackings` - 추적 시작
- `DELETE /trackings/{id}` - 추적 삭제

### Alerts
- `GET /alerts` - 알림 목록
- `POST /alerts` - 알림 생성
- `DELETE /alerts/{id}` - 알림 삭제

### Onboarding
- `POST /onboarding/complete` - 온보딩 완료

### Clicks
- `POST /clicks` - 클릭 로그

---

## 🔄 데이터 흐름

1. **앱 시작** → 스플래시 → 온보딩 완료 확인
2. **온보딩 미완료** → 온보딩 플로우 → 완료 시 서버 저장
3. **온보딩 완료** → 홈 화면 → Primary Pet 조회 → 추천 상품 로드
4. **상품 선택** → 상품 상세 → 추적 시작 → 관심 화면에 표시
