# 상품 관련 테이블 구조

> **최종 업데이트**: 2026-02-05

## 개요

상품 관련 테이블은 크게 **기본 정보**, **성분/영양 정보**, **판매처/가격 정보**로 구성됩니다.

---

## 1. 핵심 테이블

### 1.1 `products` - 상품 기본 정보
**목적**: 상품의 기본 식별 정보 저장

```sql
- id: UUID (PK)
- category: VARCHAR(30) NOT NULL DEFAULT 'FOOD'
- brand_name: VARCHAR(100) NOT NULL
- product_name: VARCHAR(255) NOT NULL
- size_label: VARCHAR(50) (nullable, 예: "3kg", "5kg")
- species: ENUM('DOG', 'CAT') (nullable, 전용 사료면 지정, 공용이면 NULL)
- is_active: BOOLEAN NOT NULL DEFAULT true
- created_at: TIMESTAMP WITH TIME ZONE
- updated_at: TIMESTAMP WITH TIME ZONE

인덱스:
- idx_products_active (is_active)
- idx_products_brand (brand_name)
- UNIQUE (brand_name, product_name, size_label) [중복 방지]
```

**관계**:
- 1:N → `product_offers` (판매처)
- 1:1 → `product_ingredient_profiles` (성분 정보)
- 1:1 → `product_nutrition_facts` (영양 정보)
- 1:N → `product_allergens` (알레르겐)
- 1:N → `product_claims` (기능성 클레임)
- 1:N → `trackings` (가격 추적)
- 1:N → `recommendation_items` (추천 아이템)
- 1:N → `outbound_clicks` (외부 클릭)

---

## 2. 성분/영양 정보 테이블

### 2.1 `product_ingredient_profiles` - 상품 성분 프로필
**목적**: 원재료 및 첨가물 원문 저장, 성분 분석용

```sql
- product_id: UUID (PK, FK -> products.id, CASCADE)
- ingredients_text: TEXT (nullable, 원재료 원문)
- additives_text: TEXT (nullable, 첨가물 원문)
- parsed: JSONB (nullable, 토큰화/정규화 결과)
- source: VARCHAR(200) (nullable, 공식홈/포장지/크롤링 등)
- version: INTEGER NOT NULL DEFAULT 1 [포뮬러 변경 추적용]
- updated_at: VARCHAR NOT NULL DEFAULT 'now()'
```

**특징**:
- 1:1 관계 (product_id가 PK)
- `parsed` 필드에 JSONB로 파싱 결과 저장 가능
- `version`으로 포뮬러 변경 이력 추적

---

### 2.2 `product_nutrition_facts` - 상품 영양 정보
**목적**: 보장성분 및 칼로리 등 정형화된 영양 정보 저장

```sql
- product_id: UUID (PK, FK -> products.id, CASCADE)
- protein_pct: NUMERIC(5,2) (nullable, 단백질 %)
- fat_pct: NUMERIC(5,2) (nullable, 지방 %)
- fiber_pct: NUMERIC(5,2) (nullable, 섬유질 %)
- moisture_pct: NUMERIC(5,2) (nullable, 수분 %)
- ash_pct: NUMERIC(5,2) (nullable, 회분 %)
- kcal_per_100g: INTEGER (nullable, 칼로리/100g)
- calcium_pct: NUMERIC(5,2) (nullable, 칼슘 %)
- phosphorus_pct: NUMERIC(5,2) (nullable, 인 %)
- aafco_statement: TEXT (nullable, AAFCO 기준 문구)
- version: INTEGER NOT NULL DEFAULT 1 [포뮬러 변경 추적용]
- updated_at: VARCHAR NOT NULL DEFAULT 'now()'
```

**특징**:
- 1:1 관계 (product_id가 PK)
- 모든 영양소는 퍼센트(%) 단위
- `version`으로 포뮬러 변경 이력 추적

---

## 3. 알레르겐/클레임 테이블

### 3.1 `allergen_codes` - 알레르겐 코드 (참조 테이블)
**목적**: 알레르겐 코드 표준화

```sql
- code: VARCHAR(30) (PK)
- display_name: VARCHAR(50) NOT NULL

예시:
- BEEF: 소고기
- CHICKEN: 닭고기
- PORK: 돼지고기
- DUCK: 오리고기
- LAMB: 양고기
- FISH: 생선
- EGG: 계란
- DAIRY: 유제품
- WHEAT: 밀/글루텐
- CORN: 옥수수
- SOY: 콩
```

---

### 3.2 `product_allergens` - 상품 알레르겐 (다대다)
**목적**: 상품이 포함하는 알레르겐 정보 (필터링 핵심)

```sql
- product_id: UUID (PK, FK -> products.id, CASCADE)
- allergen_code: VARCHAR(30) (PK, FK -> allergen_codes.code)
- confidence: SMALLINT NOT NULL DEFAULT 80 (0-100, 신뢰도)
- source: VARCHAR(200) (nullable, 출처)

인덱스:
- idx_product_allergens_allergen (allergen_code)
- CHECK (confidence BETWEEN 0 AND 100)
```

**특징**:
- 복합 PK (product_id, allergen_code)
- `confidence`로 신뢰도 표시 (0-100)
- 상품별로 여러 알레르겐 가능

---

### 3.3 `claim_codes` - 기능성 클레임 코드 (참조 테이블)
**목적**: 기능성 클레임 코드 표준화

```sql
- code: VARCHAR(30) (PK)
- display_name: VARCHAR(50) NOT NULL

예시:
- DIGESTIVE: 장/소화 건강
- DENTAL: 치아/구강 건강
- SKIN: 피부/털 건강
- JOINT: 관절 건강
- WEIGHT: 체중 관리
- URINARY: 요로 건강
- SENIOR: 노령 관리
- PUPPY: 퍼피 성장
- IMMUNE: 면역력 강화
- COAT: 털 관리
```

---

### 3.4 `product_claims` - 상품 기능성 클레임 (다대다)
**목적**: 상품의 기능성 클레임 정보

```sql
- product_id: UUID (PK, FK -> products.id, CASCADE)
- claim_code: VARCHAR(30) (PK, FK -> claim_codes.code)
- evidence_level: SMALLINT NOT NULL DEFAULT 50 (0-100, 증거 수준)
- note: TEXT (nullable, 비고)

인덱스:
- idx_product_claims_claim (claim_code)
- CHECK (evidence_level BETWEEN 0 AND 100)
```

**특징**:
- 복합 PK (product_id, claim_code)
- `evidence_level`로 증거 수준 표시 (0-100)
- 상품별로 여러 클레임 가능

---

## 4. 판매처/가격 정보 테이블

### 4.1 `product_offers` - 상품 판매처
**목적**: 상품의 판매처 정보 (쿠팡, 네이버 등)

```sql
- id: UUID (PK)
- product_id: UUID (FK -> products.id, CASCADE)
- merchant: ENUM('COUPANG', 'NAVER', 'BRAND') NOT NULL
- merchant_product_id: VARCHAR(255) NOT NULL (판매처 상품 ID)
- vendor_item_id: BIGINT (nullable, UNIQUE) [쿠팡 vendorItemId 매핑용]
- normalized_key: VARCHAR(255) (nullable) [안정적 매핑 키]
- url: VARCHAR(500) NOT NULL
- affiliate_url: VARCHAR(500) (nullable, 어필리에이트 URL)
- seller_name: VARCHAR(120) (nullable, 판매자명)
- is_primary: BOOLEAN NOT NULL DEFAULT false (주 판매처 여부)
- is_active: BOOLEAN NOT NULL DEFAULT true
- created_at: TIMESTAMP WITH TIME ZONE
- updated_at: TIMESTAMP WITH TIME ZONE

인덱스:
- ix_offers_product_merchant (product_id, merchant)
- idx_offers_active (is_active)
- UNIQUE (merchant, merchant_product_id)
- UNIQUE (vendor_item_id)
```

**특징**:
- 한 상품에 여러 판매처 가능 (쿠팡, 네이버 등)
- `vendor_item_id`: 쿠팡 파트너스 API의 vendorItemId 매핑
- `normalized_key`: 안정적인 매핑을 위한 키

---

### 4.2 `price_snapshots` - 가격 스냅샷
**목적**: 가격 히스토리 저장 (product_offers와 연결)

```sql
- id: UUID (PK)
- offer_id: UUID (FK -> product_offers.id, CASCADE)
- listed_price: INTEGER NOT NULL (페이지 표시 가격)
- shipping_fee: INTEGER NOT NULL DEFAULT 0
- coupon_discount: INTEGER NOT NULL DEFAULT 0
- card_discount: INTEGER NOT NULL DEFAULT 0
- final_price: INTEGER NOT NULL (최종 가격 = listed + shipping - discounts)
- currency: VARCHAR(3) NOT NULL DEFAULT 'KRW'
- is_sold_out: BOOLEAN NOT NULL DEFAULT false
- captured_at: TIMESTAMP WITH TIME ZONE NOT NULL
- captured_source: VARCHAR(50) NOT NULL DEFAULT 'COUPANG_API' [가격 스냅샷 출처]
- meta: JSONB (nullable)
- created_at: TIMESTAMP WITH TIME ZONE

인덱스:
- idx_price_snapshots_offer_time (offer_id, captured_at DESC)
- idx_price_snapshots_offer_final (offer_id, final_price)
```

**특징**:
- `final_price` 기준으로 통일
- `captured_source`로 출처 기록 (쿠팡 외 플랫폼 대비)

---

### 4.3 `price_summaries` - 가격 요약
**목적**: 가격 통계 캐시 (product_offers와 연결)

```sql
- offer_id: UUID (PK, FK -> product_offers.id, CASCADE)
- window_days: INTEGER NOT NULL DEFAULT 30 (기간)
- avg_final_price: INTEGER NOT NULL (평균 가격)
- min_final_price: INTEGER NOT NULL (최저가)
- max_final_price: INTEGER NOT NULL (최고가)
- last_final_price: INTEGER NOT NULL (최근 가격)
- last_captured_at: TIMESTAMP WITH TIME ZONE NOT NULL
- updated_at: TIMESTAMP WITH TIME ZONE
```

**특징**:
- 성능 최적화를 위한 캐시 테이블
- `window_days`로 기간 설정 가능

---

## 5. 관련 테이블 (상품과 연결)

### 5.1 `trackings` - 가격 추적
**목적**: 사용자가 특정 상품의 가격을 추적

```sql
- id: UUID (PK)
- user_id: UUID (FK -> users.id, CASCADE)
- pet_id: UUID (FK -> pets.id, CASCADE)
- product_id: UUID (FK -> products.id, CASCADE)
- status: ENUM('ACTIVE', 'PAUSED', 'DELETED') NOT NULL DEFAULT 'ACTIVE'
- last_checked_at: TIMESTAMP WITH TIME ZONE (nullable) [마지막 가격 확인 시간]
- next_check_at: TIMESTAMP WITH TIME ZONE (nullable) [다음 가격 확인 예정 시간]
- created_at: TIMESTAMP WITH TIME ZONE
- updated_at: TIMESTAMP WITH TIME ZONE

인덱스:
- idx_trackings_user (user_id)
- idx_trackings_pet (pet_id)
- idx_trackings_product (product_id)
- UNIQUE (user_id, pet_id, product_id)
```

---

### 5.2 `recommendation_items` - 추천 아이템
**목적**: 추천 알고리즘 결과 저장

```sql
- run_id: UUID (PK, FK -> recommendation_runs.id, CASCADE)
- product_id: UUID (PK, FK -> products.id, CASCADE)
- rank: INTEGER NOT NULL (순위)
- score: NUMERIC(8,4) NOT NULL (점수)
- reasons: JSONB NOT NULL (추천 이유 배열)
- score_components: JSONB (nullable) [세부 점수 분해]

인덱스:
- idx_rec_items_run_rank (run_id, rank)
```

---

### 5.3 `outbound_clicks` - 외부 클릭 추적
**목적**: 상품 클릭 추적 및 어필리에이트 수익 분석

```sql
- id: UUID (PK)
- user_id: UUID (FK -> users.id, CASCADE)
- pet_id: UUID (FK -> pets.id, SET NULL, nullable)
- product_id: UUID (FK -> products.id, CASCADE)
- offer_id: UUID (FK -> product_offers.id, SET NULL, nullable)
- source: VARCHAR(20) NOT NULL (HOME/DETAIL/ALERT)
- clicked_at: TIMESTAMP WITH TIME ZONE NOT NULL
- session_id: VARCHAR(255) (nullable)
- estimated_commission: NUMERIC(10,2) (nullable) [예상 커미션]
- actual_commission: NUMERIC(10,2) (nullable) [실제 커미션]
- meta: JSONB (nullable)
- created_at: TIMESTAMP WITH TIME ZONE

인덱스:
- idx_clicks_product_time (product_id, clicked_at DESC)
- idx_clicks_user_time (user_id, clicked_at DESC)
```

---

## 테이블 관계도

```
products (1) ──< (N) product_offers
products (1) ──< (1) product_ingredient_profiles
products (1) ──< (1) product_nutrition_facts
products (1) ──< (N) product_allergens ──> (N) allergen_codes
products (1) ──< (N) product_claims ──> (N) claim_codes
products (1) ──< (N) trackings
products (1) ──< (N) recommendation_items
products (1) ──< (N) outbound_clicks

product_offers (1) ──< (N) price_snapshots
product_offers (1) ──< (1) price_summaries
product_offers (1) ──< (N) outbound_clicks
```

---

## 주요 특징

1. **정규화**: 알레르겐과 클레임은 코드 테이블로 분리
2. **버전 관리**: 성분/영양 정보에 `version` 필드로 포뮬러 변경 추적
3. **유연성**: JSONB 필드로 파싱 결과, 메타데이터 등 저장
4. **성능**: 가격 요약 테이블로 통계 캐싱
5. **CASCADE 삭제**: 상품 삭제 시 관련 정보 자동 삭제
6. **UNIQUE 제약**: 브랜드명+상품명+용량 조합으로 중복 방지

---

## 데이터 흐름

1. **상품 등록**: `products` 테이블에 기본 정보 저장
2. **성분/영양 입력**: `product_ingredient_profiles`, `product_nutrition_facts`에 상세 정보 저장
3. **알레르겐/클레임 태깅**: `product_allergens`, `product_claims`에 태그 추가
4. **판매처 등록**: `product_offers`에 쿠팡/네이버 등 판매처 정보 저장
5. **가격 수집**: `price_snapshots`에 가격 히스토리 저장
6. **가격 요약**: `price_summaries`에 통계 캐싱
