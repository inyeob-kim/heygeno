# 🐾 Pet Food App

**반려동물 사료 가격 추적 및 스마트 알림 서비스**

반려동물을 키우는 사람들을 위한 사료 가격 모니터링 및 최적 구매 시점 알림 서비스입니다. 우리 아이에게 맞는 사료를 추천하고, 가격 변동을 실시간으로 추적하여 최저가 구매 기회를 놓치지 않도록 도와줍니다.

---

## 📋 서비스 개요

### 핵심 기능

1. **반려동물 프로필 관리**
   - 견종, 체중, 연령대 기반 프로필 등록
   - 프로필별 맞춤 사료 추천

2. **사료 가격 추적**
   - 관심 사료의 가격 변동 실시간 모니터링
   - 평균가 대비 가격 분석
   - 최근 30일 가격 히스토리 제공

3. **스마트 알림**
   - 가격 하락 알림 (평균가 대비, 최저가 등)
   - 소진 임박 알림 (사료가 얼마나 남았는지 계산)
   - 타겟 가격 도달 알림

4. **맞춤 추천**
   - 반려동물 프로필 기반 사료 추천
   - 오늘 사면 좋은 사료 제안

5. **구매 최적화**
   - 정기배송 vs 단품 구매 비교
   - 급여 일수 계산 (우리 아이 기준)
   - 최저가 구매 시점 추천

### 주요 화면

- **홈 (오늘)**: 현재 상태 및 추천 사료
- **관심**: 추적 중인 사료 리스트
- **사료 선택**: 대표 사료 둘러보기 (200+ 상품)
- **사료 상세**: 가격 정보, 구매 옵션, 정기배송 판단
- **알림**: 가격 하락 및 소진 임박 알림
- **마이**: 프로필 관리, 알림 설정

---

## 🏗️ 프로젝트 구조

```
pet-food-app/
├── backend/                    # FastAPI 백엔드
│   ├── app/
│   │   ├── main.py            # FastAPI 앱 진입점
│   │   ├── core/              # 설정, DB, Redis, 보안
│   │   ├── db/                # DB Base, Session
│   │   ├── models/            # SQLAlchemy ORM 모델
│   │   ├── schemas/           # Pydantic 스키마 (API 요청/응답)
│   │   ├── api/               # API 라우터
│   │   ├── services/          # 비즈니스 로직
│   │   └── workers/           # 백그라운드 작업 (크롤링, 알림)
│   ├── alembic/               # DB 마이그레이션
│   └── requirements.txt       # Python 의존성
│
└── frontend/                   # Flutter 프론트엔드
    └── lib/
        ├── main.dart          # 앱 진입점
        ├── app/               # App Shell (라우터, 테마, 설정)
        ├── core/              # 공통 레이어 (네트워크, 에러, 위젯)
        ├── data/              # 데이터 레이어 (모델, 리포지토리, 더미 데이터)
        ├── features/           # Feature-first 구조
        └── ui/                 # 공통 UI 컴포넌트 (토스 스타일)
```

---

## 🛠️ 기술 스택

### Backend

- **Framework**: FastAPI 0.104.1
- **Database**: PostgreSQL 15 (asyncpg)
- **ORM**: SQLAlchemy 2.0 (async)
- **Migration**: Alembic
- **Cache**: Redis 7
- **Authentication**: JWT (python-jose)
- **Background Jobs**: APScheduler
- **Validation**: Pydantic 2.5

### Frontend

- **Framework**: Flutter (SDK >=3.8.0)
- **State Management**: Riverpod 2.4.9
- **Routing**: GoRouter 12.1.3
- **HTTP Client**: Dio 5.4.0
- **Code Generation**: json_serializable
- **Environment**: flutter_dotenv

### Infrastructure

- **Container**: Docker & Docker Compose
- **Database**: PostgreSQL 15
- **Cache**: Redis 7

---

## 🚀 시작하기

### 사전 요구사항

- Python 3.11+
- Flutter SDK 3.8.0+
- Docker & Docker Compose
- PostgreSQL 15
- Redis 7

### Backend 설정

1. **환경 변수 설정**
```bash
cd backend
cp .env.example .env
# .env 파일 수정 (DATABASE_URL, REDIS_URL 등)
```

2. **의존성 설치**
```bash
pip install -r requirements.txt
```

3. **Docker Compose로 인프라 실행**
```bash
# 프로젝트 루트에서 실행
docker compose up -d postgres redis
```

4. **데이터베이스 마이그레이션**
```bash
cd backend

# 초기 마이그레이션 생성 (최초 1회)
alembic revision --autogenerate -m "init"

# 마이그레이션 적용
alembic upgrade head
```

5. **서버 실행**
```bash
# 개발 모드 (모든 네트워크 인터페이스에서 접근 가능)
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

# 또는 localhost만 (시뮬레이터용)
uvicorn app.main:app --reload
```

### Frontend 설정

1. **의존성 설치**
```bash
cd frontend
flutter pub get
```

2. **환경 변수 설정**
```bash
# frontend/.env 파일 생성
echo "API_BASE_URL=http://localhost:8000/api/v1" > .env
echo "DEVICE_API_BASE_URL=http://192.168.x.x:8000/api/v1" >> .env
```

3. **코드 생성 (DTO)**
```bash
# DTO 모델의 fromJson/toJson 메서드 생성
flutter pub run build_runner build --delete-conflicting-outputs
```

4. **앱 실행**
```bash
flutter run
```

---

## 📚 주요 기능 상세

### 1. 반려동물 프로필 관리

- **등록 정보**: 견종, 체중 범위, 연령대 (퍼피/어덜트/시니어)
- **프로필 기반 추천**: 등록한 정보를 바탕으로 맞춤 사료 추천

### 2. 사료 가격 추적

- **실시간 모니터링**: 관심 사료의 가격 변동 추적
- **가격 분석**:
  - 현재 가격 vs 평균가 비교
  - 최근 30일 가격 히스토리
  - 최저가 여부 판단
- **쇼핑몰별 비교**: 쿠팡, 네이버 등 여러 쇼핑몰 가격 비교

### 3. 스마트 알림 시스템

- **가격 하락 알림**:
  - 평균가 대비 일정 % 하락 시
  - 최근 30일 최저가 도달 시
  - 사용자 설정 타겟 가격 도달 시
- **소진 임박 알림**:
  - 반려동물 체중 및 급여량 기반 소진 일수 계산
  - 소진 전 미리 알림

### 4. 맞춤 추천

- **프로필 기반 추천**: 견종, 체중, 연령대에 맞는 사료 추천
- **오늘 사면 좋은 사료**: 현재 가격이 유리한 사료 제안

### 5. 구매 최적화

- **정기배송 vs 단품 비교**: 가격 및 편의성 비교
- **급여 일수 계산**: 우리 아이 기준으로 사료가 얼마나 가는지 계산
- **최저가 구매 시점**: 가격 히스토리 기반 구매 추천

---

## 🎨 UI/UX 디자인

### 디자인 시스템 (토스 스타일)

- **색상**: 토스 블루 (#3182F6) 기반의 밝고 깔끔한 톤
- **타이포그래피**: 큰 타이틀 (28-32px), 명확한 계층 구조
- **카드**: 둥근 모서리 (20px), 부드러운 그림자
- **버튼**: 큰 터치 영역 (56px 높이), 명확한 CTA
- **간격**: 넓은 여백 (20px 페이지 패딩)

### 주요 원칙

1. **한 화면 = 한 가지 핵심 행동**
2. **정보는 카드 단위로 구성**
3. **"지금 해야 할 이유"가 항상 보여야 함**
4. **가격/알림/소진 같은 행동 트리거는 상단에**

---

## 📖 API 문서

서버 실행 후 다음 URL에서 확인 가능:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

### 주요 API 엔드포인트

- `GET /api/v1/pets` - 반려동물 목록
- `POST /api/v1/pets` - 반려동물 등록
- `GET /api/v1/products` - 사료 목록
- `GET /api/v1/recommendations/{pet_id}` - 맞춤 추천
- `GET /api/v1/trackings` - 추적 중인 사료 목록
- `POST /api/v1/trackings` - 사료 추적 시작
- `GET /api/v1/alerts` - 알림 목록

---

## 🏛️ 아키텍처 원칙

### 레이어 분리

**Backend:**
```
API Layer → Service Layer → Data Access Layer
```

**Frontend:**
```
Presentation Layer → Domain Layer → Data Layer
```

### 주요 원칙

1. **단일 책임 원칙**: 각 클래스/함수는 하나의 책임만
2. **의존성 역전**: 상위 레이어는 하위 레이어에 의존하지 않음
3. **도메인 로직 분리**: 화면/라우터에는 비즈니스 로직 없음
4. **Feature-first 구조**: 기능별로 코드 조직화

자세한 개발 가이드라인은 `.cursor/rules/architecture.mdc` 파일을 참고하세요.

---

## 📝 개발 가이드

### 코드 생성

**Backend (마이그레이션):**
```bash
# 모델 변경 후
alembic revision --autogenerate -m "description"
alembic upgrade head
```

**Frontend (DTO):**
```bash
# 모델 변경 후
flutter pub run build_runner build --delete-conflicting-outputs
```

### 환경 변수

**Backend (.env):**
```env
DATABASE_URL=postgresql+asyncpg://user:password@localhost:5432/petfood
REDIS_URL=redis://localhost:6379
SECRET_KEY=your-secret-key
```

**Frontend (.env):**
```env
API_BASE_URL=http://localhost:8000/api/v1
DEVICE_API_BASE_URL=http://192.168.x.x:8000/api/v1
```

---

## 📄 라이선스

MIT License

---

**Made with ❤️ for pet parents**
