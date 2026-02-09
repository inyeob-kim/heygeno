# 관리자 대시보드 설계 및 기능 정리

> **최종 업데이트**: 2026-02-05

## 개요

관리자 대시보드는 상품 및 성분 정보를 관리하기 위한 웹 인터페이스입니다. 순수 HTML/JavaScript로 구현되어 있으며, 백엔드 API를 통해 데이터를 저장/수정합니다.

---

## 저장 및 수정하는 데이터

### 1. 상품 기본 정보 (`products` 테이블)

**저장/수정 항목**:
- `brand_name` (브랜드명) - 필수
- `product_name` (상품명) - 필수
- `size_label` (용량, 예: "3kg") - 선택
- `category` (카테고리) - 기본값: "FOOD"
- `species` (반려동물 종류) - DOG/CAT/공용(null)
- `is_active` (활성 상태) - true/false

**제약사항**:
- UNIQUE 제약: (brand_name, product_name, size_label) 조합으로 중복 방지
- 삭제는 소프트 삭제 (is_active = false)

---

### 2. 성분 정보 (`product_ingredient_profiles` 테이블)

**저장/수정 항목**:
- `ingredients_text` (원재료 원문) - TEXT
- `additives_text` (첨가물 원문) - TEXT
- `source` (출처) - VARCHAR(200), 예: "공식홈", "포장지", "크롤링"
- `parsed` (파싱 결과) - JSONB (향후 자동 파싱 결과 저장용)
- `version` (버전) - 자동 증가 (포뮬러 변경 추적)

**특징**:
- 1:1 관계 (product_id가 PK)
- 생성/수정 모두 `PUT` 메서드로 처리 (upsert 방식)
- 수정 시 `version` 자동 증가

---

### 3. 영양 정보 (`product_nutrition_facts` 테이블)

**저장/수정 항목**:
- `protein_pct` (단백질 %) - NUMERIC(5,2)
- `fat_pct` (지방 %) - NUMERIC(5,2)
- `fiber_pct` (섬유질 %) - NUMERIC(5,2)
- `moisture_pct` (수분 %) - NUMERIC(5,2)
- `ash_pct` (회분 %) - NUMERIC(5,2)
- `kcal_per_100g` (칼로리/100g) - INTEGER
- `calcium_pct` (칼슘 %) - NUMERIC(5,2)
- `phosphorus_pct` (인 %) - NUMERIC(5,2)
- `aafco_statement` (AAFCO 기준) - TEXT
- `version` (버전) - 자동 증가

**특징**:
- 1:1 관계 (product_id가 PK)
- 모든 영양소는 퍼센트(%) 단위
- 생성/수정 모두 `PUT` 메서드로 처리 (upsert 방식)

---

### 4. 알레르겐 정보 (`product_allergens` 테이블)

**저장/수정 항목**:
- `allergen_code` (알레르겐 코드) - FK → `allergen_codes.code`
  - 예: BEEF, CHICKEN, PORK, DUCK, LAMB, FISH, EGG, DAIRY, WHEAT, CORN, SOY
- `confidence` (신뢰도) - SMALLINT (0-100), 기본값: 80
- `source` (출처) - VARCHAR(200)

**특징**:
- 다대다 관계 (복합 PK: product_id, allergen_code)
- 한 상품에 여러 알레르겐 추가 가능
- 개별 알레르겐 추가/수정/삭제 가능

---

### 5. 기능성 클레임 (`product_claims` 테이블)

**저장/수정 항목**:
- `claim_code` (클레임 코드) - FK → `claim_codes.code`
  - 예: DIGESTIVE, DENTAL, SKIN, JOINT, WEIGHT, URINARY, SENIOR, PUPPY, IMMUNE, COAT
- `evidence_level` (증거 수준) - SMALLINT (0-100), 기본값: 50
- `note` (비고) - TEXT

**특징**:
- 다대다 관계 (복합 PK: product_id, claim_code)
- 한 상품에 여러 클레임 추가 가능
- 개별 클레임 추가/수정/삭제 가능

---

## 설계 구조

### 아키텍처 개요

```
┌─────────────────────────────────────────┐
│   Frontend (HTML/JavaScript)            │
│   frontend_admin/index.html              │
│   - 순수 HTML/CSS/JavaScript             │
│   - Fetch API로 백엔드 호출              │
└──────────────┬──────────────────────────┘
               │ HTTP REST API
               ▼
┌─────────────────────────────────────────┐
│   Backend API Layer                     │
│   backend/app/api/v1/admin.py           │
│   - 라우팅만 담당                        │
│   - 요청/응답 변환                       │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│   Service Layer                         │
│   - ProductService (기본 정보)           │
│   - AdminService (성분/영양/알레르겐/클레임)│
│   - 비즈니스 로직 처리                   │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│   Database Layer                        │
│   - SQLAlchemy ORM                      │
│   - PostgreSQL                          │
└─────────────────────────────────────────┘
```

---

### 레이어별 역할

#### 1. 프론트엔드 레이어 (`frontend_admin/index.html`)

**역할**:
- 사용자 인터페이스 제공
- API 호출 및 데이터 표시
- 폼 입력 및 유효성 검사

**주요 함수**:
- `loadProducts()` - 상품 목록 조회
- `selectProduct()` - 상품 선택 및 상세 정보 로드
- `saveProduct()` - 상품 생성/수정
- `deleteProduct()` - 상품 삭제 (소프트)
- `loadIngredientData()` - 성분 정보 조회
- `saveIngredient()` - 성분 정보 저장/수정
- `loadNutritionData()` - 영양 정보 조회
- `saveNutrition()` - 영양 정보 저장/수정
- `loadAllergenData()` - 알레르겐 목록 조회
- `addAllergen()` / `deleteAllergen()` - 알레르겐 추가/삭제
- `loadClaimData()` - 클레임 목록 조회
- `addClaim()` / `deleteClaim()` - 클레임 추가/삭제

**UI 구조**:
- 좌측: 상품 목록 (스크롤 가능)
- 우측: 상품 상세 정보 (탭 기반)
  - 기본 정보 탭
  - 성분 정보 탭
  - 영양 정보 탭
  - 알레르겐 탭
  - 기능성 클레임 탭

---

#### 2. API 레이어 (`backend/app/api/v1/admin.py`)

**역할**:
- HTTP 요청/응답 처리
- 라우팅만 담당 (도메인 로직 없음)
- 스키마 검증 및 변환

**엔드포인트 구조**:

```
# 상품 기본 정보
GET    /api/v1/admin/products                    # 목록 조회
GET    /api/v1/admin/products/{product_id}       # 상세 조회
POST   /api/v1/admin/products                   # 생성
PUT    /api/v1/admin/products/{product_id}       # 수정
DELETE /api/v1/admin/products/{product_id}       # 삭제 (소프트)

# 성분 정보
GET    /api/v1/admin/products/{product_id}/ingredient  # 조회
PUT    /api/v1/admin/products/{product_id}/ingredient  # 생성/수정 (upsert)

# 영양 정보
GET    /api/v1/admin/products/{product_id}/nutrition   # 조회
PUT    /api/v1/admin/products/{product_id}/nutrition   # 생성/수정 (upsert)

# 알레르겐
GET    /api/v1/admin/allergen-codes                    # 코드 목록
GET    /api/v1/admin/products/{product_id}/allergens    # 상품 알레르겐 목록
POST   /api/v1/admin/products/{product_id}/allergens    # 알레르겐 추가
PUT    /api/v1/admin/products/{product_id}/allergens/{code}  # 알레르겐 수정
DELETE /api/v1/admin/products/{product_id}/allergens/{code}  # 알레르겐 삭제

# 클레임
GET    /api/v1/admin/claim-codes                       # 코드 목록
GET    /api/v1/admin/products/{product_id}/claims      # 상품 클레임 목록
POST   /api/v1/admin/products/{product_id}/claims      # 클레임 추가
PUT    /api/v1/admin/products/{product_id}/claims/{code}  # 클레임 수정
DELETE /api/v1/admin/products/{product_id}/claims/{code}  # 클레임 삭제
```

---

#### 3. 서비스 레이어

##### 3.1 `ProductService` (`backend/app/services/product_service.py`)

**역할**: 상품 기본 정보 CRUD

**메서드**:
- `get_all_products()` - 모든 상품 조회 (비활성 포함 옵션)
- `get_product_by_id()` - 상품 ID로 조회
- `create_product()` - 상품 생성 (중복 체크 포함)
- `update_product()` - 상품 수정
- `delete_product()` - 상품 삭제 (소프트 삭제)

---

##### 3.2 `AdminService` (`backend/app/services/admin_service.py`)

**역할**: 성분/영양/알레르겐/클레임 관리

**성분 정보 메서드**:
- `get_ingredient_profile()` - 성분 정보 조회
- `create_or_update_ingredient_profile()` - 생성 또는 수정 (upsert)

**영양 정보 메서드**:
- `get_nutrition_facts()` - 영양 정보 조회
- `create_or_update_nutrition_facts()` - 생성 또는 수정 (upsert)

**알레르겐 메서드**:
- `get_allergen_codes()` - 알레르겐 코드 목록 조회
- `get_product_allergens()` - 상품 알레르겐 목록 조회
- `add_product_allergen()` - 알레르겐 추가 (중복 체크)
- `update_product_allergen()` - 알레르겐 수정
- `delete_product_allergen()` - 알레르겐 삭제

**클레임 메서드**:
- `get_claim_codes()` - 클레임 코드 목록 조회
- `get_product_claims()` - 상품 클레임 목록 조회
- `add_product_claim()` - 클레임 추가 (중복 체크)
- `update_product_claim()` - 클레임 수정
- `delete_product_claim()` - 클레임 삭제

---

#### 4. 스키마 레이어

##### 4.1 `ProductCreate` / `ProductUpdate` (`backend/app/schemas/product.py`)

**역할**: 상품 생성/수정 요청 검증

---

##### 4.2 관리자 스키마 (`backend/app/schemas/admin.py`)

**역할**: 성분/영양/알레르겐/클레임 요청/응답 검증

**스키마 목록**:
- `IngredientProfileRead/Create/Update`
- `NutritionFactsRead/Create/Update`
- `ProductAllergenRead/Create/Update`
- `ProductClaimRead/Create/Update`
- `AllergenCodeRead`
- `ClaimCodeRead`

---

## 설계 원칙

### 1. 단일 책임 원칙 (SRP)

- **API 라우터**: 라우팅만 담당, 도메인 로직 없음
- **서비스**: 비즈니스 로직만 담당
- **스키마**: 데이터 검증 및 변환만 담당

### 2. 의존성 역전 원칙 (DIP)

- 서비스는 추상화(Repository)에 의존
- API는 서비스에 의존

### 3. RESTful API 설계

- 리소스 중심 URL 구조
- HTTP 메서드로 동작 구분 (GET/POST/PUT/DELETE)
- 적절한 HTTP 상태 코드 사용

### 4. Upsert 패턴

- 성분/영양 정보는 `PUT` 메서드로 생성/수정 통합
- 기존 데이터가 있으면 수정, 없으면 생성

### 5. 소프트 삭제

- 상품 삭제는 실제 삭제가 아닌 `is_active = false`로 처리
- 데이터 무결성 보장

---

## 데이터 흐름 예시

### 상품 생성 흐름

```
1. 사용자가 HTML 폼에 정보 입력
   ↓
2. JavaScript: saveProduct() 호출
   ↓
3. Fetch API: POST /api/v1/admin/products
   ↓
4. API 라우터: ProductCreate 스키마 검증
   ↓
5. ProductService.create_product() 호출
   - 중복 체크 (brand_name, product_name, size_label)
   - Product 모델 생성
   - DB 저장
   ↓
6. ProductRead 스키마로 응답 변환
   ↓
7. HTML: 상품 목록 새로고침
```

### 성분 정보 수정 흐름

```
1. 사용자가 "성분 정보" 탭에서 "수정" 버튼 클릭
   ↓
2. JavaScript: editIngredient() 호출
   - GET /api/v1/admin/products/{id}/ingredient로 기존 데이터 조회
   ↓
3. 모달 폼 표시 (기존 데이터로 채움)
   ↓
4. 사용자가 수정 후 "저장" 클릭
   ↓
5. JavaScript: saveIngredient() 호출
   ↓
6. Fetch API: PUT /api/v1/admin/products/{id}/ingredient
   ↓
7. API 라우터: IngredientProfileUpdate 스키마 검증
   ↓
8. AdminService.create_or_update_ingredient_profile() 호출
   - 기존 데이터 조회
   - 있으면 수정, 없으면 생성
   - version 자동 증가
   ↓
9. IngredientProfileRead 스키마로 응답 변환
   ↓
10. HTML: 성분 정보 탭 새로고침
```

### 알레르겐 추가 흐름

```
1. 사용자가 "알레르겐" 탭에서 "수정" 버튼 클릭
   ↓
2. JavaScript: editAllergen() 호출
   - GET /api/v1/admin/products/{id}/allergens (등록된 알레르겐)
   - GET /api/v1/admin/allergen-codes (전체 코드 목록)
   ↓
3. 모달 표시 (등록된 알레르겐 제외한 코드만 드롭다운에 표시)
   ↓
4. 사용자가 알레르겐 선택 후 "추가" 클릭
   ↓
5. JavaScript: addAllergen() 호출
   ↓
6. Fetch API: POST /api/v1/admin/products/{id}/allergens
   ↓
7. API 라우터: ProductAllergenCreate 스키마 검증
   ↓
8. AdminService.add_product_allergen() 호출
   - 중복 체크 (product_id, allergen_code)
   - ProductAllergen 모델 생성
   - DB 저장
   ↓
9. ProductAllergenRead 스키마로 응답 변환
   ↓
10. HTML: 알레르겐 목록 새로고침
```

---

## 주요 기능 요약

| 기능 | 테이블 | CRUD | 비고 |
|------|--------|------|------|
| 상품 기본 정보 | `products` | ✅ Create<br>✅ Read<br>✅ Update<br>✅ Delete (소프트) | 중복 방지 제약 |
| 성분 정보 | `product_ingredient_profiles` | ✅ Read<br>✅ Upsert | 1:1 관계, 버전 관리 |
| 영양 정보 | `product_nutrition_facts` | ✅ Read<br>✅ Upsert | 1:1 관계, 버전 관리 |
| 알레르겐 | `product_allergens` | ✅ Read<br>✅ Create<br>✅ Update<br>✅ Delete | 다대다 관계 |
| 클레임 | `product_claims` | ✅ Read<br>✅ Create<br>✅ Update<br>✅ Delete | 다대다 관계 |

---

## 보안 및 권한

**현재 상태**: 인증/권한 미구현

**향후 개선 사항**:
- 관리자 인증 추가 (JWT 토큰 등)
- 역할 기반 접근 제어 (RBAC)
- API 엔드포인트 보호

---

## 사용 기술 스택

### 프론트엔드
- 순수 HTML5
- CSS3 (Flexbox, Grid)
- Vanilla JavaScript (ES6+)
- Fetch API

### 백엔드
- FastAPI
- SQLAlchemy (ORM)
- PostgreSQL
- Pydantic (스키마 검증)

---

## 파일 구조

```
frontend_admin/
└── index.html          # 관리자 대시보드 (단일 파일)

backend/
├── app/
│   ├── api/v1/
│   │   └── admin.py              # 관리자 API 라우터
│   ├── services/
│   │   ├── product_service.py    # 상품 기본 정보 서비스
│   │   └── admin_service.py      # 성분/영양/알레르겐/클레임 서비스
│   └── schemas/
│       ├── product.py            # 상품 스키마
│       └── admin.py              # 관리자 스키마
```

---

## 향후 개선 사항

1. **인증/권한**: 관리자 로그인 및 권한 관리
2. **대량 등록**: CSV/Excel 파일로 상품 일괄 등록
3. **검색/필터**: 상품 검색 및 필터링 기능
4. **이미지 관리**: 상품 이미지 업로드 및 관리
5. **판매처 관리**: product_offers 테이블 관리 UI
6. **가격 정보**: price_snapshots 히스토리 조회
7. **통계 대시보드**: 상품별 통계 및 분석
