# 데이터베이스 스키마 구조 (미국 확장)

> **최근 변경사항**: 2026-02-XX에 미국 시장 확장을 위한 스키마 개선사항이 적용되었습니다.
> 기존 한국 시장 스키마는 [DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md)를 참조하세요.

## 전체 테이블 목록

### 1. 사용자 관련
- `users` - 사용자 정보
- `pets` - 반려동물 정보
- `pet_health_concerns` - 펫 건강 고민 (다대다)
- `pet_food_allergies` - 펫 식품 알레르기 (다대다)
- `pet_other_allergies` - 펫 기타 알레르기
- `pet_current_foods` - 펫 현재 급여 사료

### 2. 코드 테이블
- `health_concern_codes` - 건강 고민 코드 (영어 표시명 추가)
- `allergen_codes` - 알레르겐 코드 (영어 표시명 추가)
- `claim_codes` - 기능성 클레임 코드 (영어 표시명 추가)

### 3. 상품 관련
- `products` - 상품 기본 정보 (단위 확장: LB/OZ/G)
- `product_offers` - 상품 판매처 정보 (US 판매처 확장)
- `product_ingredient_profiles` - 상품 성분 프로필 (AAFCO order_by_weight 추가)
- `product_nutrition_facts` - 상품 영양 정보 (AAFCO 준수 필드 추가)
- `product_allergens` - 상품 알레르겐 (다대다)
- `product_claims` - 상품 기능성 클레임 (다대다, AAFCO 증빙 추가)
- `product_reviews` - 상품 리뷰 (신규)
- `product_availability` - 상품 재고·지역 제한 (신규)

### 4. 가격 관련
- `price_snapshots` - 가격 스냅샷 (히스토리, USD 기본)
- `price_summaries` - 가격 요약 (캐시)

### 5. 추적 관련
- `trackings` - 가격 추적
- `alerts` - 알림 설정
- `alert_events` - 알림 이벤트 로그

### 6. 추천 관련
- `recommendation_runs` - 추천 실행 로그
- `recommendation_items` - 추천 아이템

### 7. 기타
- `outbound_clicks` - 외부 클릭 추적

---

## 상세 테이블 구조

### 1. users (사용자)
```sql
- id: UUID (PK)
- provider: VARCHAR(50) NOT NULL DEFAULT 'DEVICE'
- provider_user_id: VARCHAR(255) NOT NULL (device_uid)
- nickname: VARCHAR(50) NOT NULL
- timezone: VARCHAR(50) NOT NULL DEFAULT 'America/New_York'  -- US 기본
- created_at: TIMESTAMP WITH TIME ZONE
- updated_at: TIMESTAMP WITH TIME ZONE

인덱스:
- idx_users_provider_user_id (provider, provider_user_id)
- idx_users_nickname (nickname)
- UNIQUE (provider, provider_user_id)
```

### 2. pets (반려동물)
```sql
- id: UUID (PK)
- user_id: UUID (FK -> users.id, CASCADE)
- name: VARCHAR(100) NOT NULL
- species: ENUM('DOG', 'CAT', 'BIRD', 'SMALL_MAMMAL', 'REPTILE', 'FISH') NOT NULL  -- US 다양성 확장
- age_mode: ENUM('BIRTHDATE', 'APPROX') NOT NULL
- birthdate: DATE (nullable, age_mode='BIRTHDATE'일 때)
- approx_age_months: INTEGER (nullable, age_mode='APPROX'일 때)
- breed_code: VARCHAR(50) (nullable)
- sex: ENUM('MALE', 'FEMALE', 'UNKNOWN') NOT NULL DEFAULT 'UNKNOWN'
- is_neutered: BOOLEAN (nullable)
- weight_numeric: NUMERIC(5,2) NOT NULL  -- 무게 숫자
- weight_unit: ENUM('KG', 'LB') NOT NULL DEFAULT 'LB'  -- US lb 기본
- body_condition_score: INTEGER NOT NULL (1-9)
- age_stage: ENUM('PUPPY', 'ADULT', 'SENIOR') NOT NULL (계산된 필드)
- photo_url: VARCHAR(500) (nullable)
- is_primary: BOOLEAN NOT NULL DEFAULT true
- created_at: TIMESTAMP WITH TIME ZONE
- updated_at: TIMESTAMP WITH TIME ZONE

인덱스:
- idx_pets_species_breed (species, breed_code)
- idx_pets_age_stage (age_stage)
- CHECK (body_condition_score BETWEEN 1 AND 9)
```

### 3. health_concern_codes (건강 고민 코드)
```sql
- code: VARCHAR(30) (PK)
- display_name: VARCHAR(50) NOT NULL
- display_name_en: VARCHAR(50) NOT NULL  -- 영어 추가

예시 (US 중심 확장):
- ALLERGY: 알레르기 / Allergy
- DIGESTIVE: 장/소화 / Digestive Health
- DENTAL: 치아/구강 / Dental Care
- OBESITY: 비만 / Obesity/Weight Management
- RESPIRATORY: 호흡기 / Respiratory
- SKIN: 피부/털 / Skin & Coat
- JOINT: 관절 / Joint Health
- EYE: 눈/눈물 / Eye Health
- KIDNEY: 신장/요로 / Kidney/Urinary Tract Health  -- US 강조
- HEART: 심장 / Heart Health
- SENIOR: 노령 / Senior Care
- URINARY_TRACT: 요로 건강 / Urinary Tract Health (신규)
- HAIRBALL: 헤어볼 / Hairball Control (신규, 고양이 중심)
```

### 4. pet_health_concerns (펫-건강고민)
```sql
- pet_id: UUID (PK, FK -> pets.id, CASCADE)
- concern_code: VARCHAR(30) (PK, FK -> health_concern_codes.code)
```

### 5. allergen_codes (알레르겐 코드)
```sql
- code: VARCHAR(30) (PK)
- display_name: VARCHAR(50) NOT NULL
- display_name_en: VARCHAR(50) NOT NULL  -- 영어 추가

예시 (US 중심 확장):
- BEEF: 소고기 / Beef
- CHICKEN: 닭고기 / Chicken
- PORK: 돼지고기 / Pork
- DUCK: 오리고기 / Duck
- LAMB: 양고기 / Lamb
- FISH: 생선 / Fish
- EGG: 계란 / Egg
- DAIRY: 유제품 / Dairy
- WHEAT: 밀/글루텐 / Wheat/Gluten
- CORN: 옥수수 / Corn
- SOY: 콩 / Soy
- GRAIN_FREE: 그레인 프리 / Grain-Free (신규, US 트렌드)
- BEEF_BYPRODUCT: 소 부산물 / Beef By-Product (신규)
```

### 6. pet_food_allergies (펫-식품 알레르기)
```sql
- pet_id: UUID (PK, FK -> pets.id, CASCADE)
- allergen_code: VARCHAR(30) (PK, FK -> allergen_codes.code)
```

### 7. pet_other_allergies (펫 기타 알레르기)
```sql
- pet_id: UUID (PK, FK -> pets.id, CASCADE)
- other_text: TEXT NOT NULL
- created_at: TIMESTAMP WITH TIME ZONE
- updated_at: TIMESTAMP WITH TIME ZONE
```

### 8. pet_current_foods (펫 현재 급여 사료)
```sql
- id: UUID (PK)
- pet_id: UUID NOT NULL (FK -> pets.id, CASCADE)
- product_id: UUID NOT NULL (FK -> products.id, RESTRICT)
- feed_type: VARCHAR(10) NOT NULL ('MAIN' | 'SUB')
- is_active: BOOLEAN NOT NULL DEFAULT true
- started_at: TIMESTAMPTZ NULL
- ended_at: TIMESTAMPTZ NULL
- meals_per_day: SMALLINT NULL (1~4)
- daily_amount_level: VARCHAR(10) NULL ('LOW'|'MEDIUM'|'HIGH')
- treats_level: VARCHAR(10) NULL ('NONE'|'SOME'|'OFTEN')
- estimated_days_per_bag: INTEGER NULL (1~365)
- last_confirmed_at: TIMESTAMPTZ NULL
- created_at: TIMESTAMPTZ NOT NULL DEFAULT now()
- updated_at: TIMESTAMPTZ NOT NULL DEFAULT now()

인덱스:
- idx_pcf_pet_active (pet_id, is_active)
- idx_pcf_product_active (product_id, is_active)
- idx_pcf_pet_feedtype_active (pet_id, feed_type, is_active)
- UNIQUE uq_pcf_pet_main_active (pet_id) WHERE is_active = true AND feed_type = 'MAIN'
- UNIQUE uq_pcf_pet_sub_active (pet_id) WHERE is_active = true AND feed_type = 'SUB'

제약조건:
- CHECK (meals_per_day IS NULL OR meals_per_day BETWEEN 1 AND 4)
- CHECK (estimated_days_per_bag IS NULL OR estimated_days_per_bag BETWEEN 1 AND 365)
- CHECK (ended_at IS NULL OR started_at IS NULL OR ended_at >= started_at)
```

### 9. products (상품)
```sql
- id: UUID (PK)
- category: VARCHAR(30) NOT NULL DEFAULT 'FOOD'
- brand_name: VARCHAR(100) NOT NULL
- product_name: VARCHAR(255) NOT NULL
- size_value: NUMERIC(5,2) (nullable)  -- 사이즈 숫자
- size_unit: ENUM('KG', 'LB', 'OZ', 'G') NOT NULL DEFAULT 'LB'  -- US lb 기본
- size_label: VARCHAR(50) (nullable, 표시용 e.g. "5 lb")
- species: ENUM('DOG', 'CAT', 'BIRD', 'SMALL_MAMMAL', 'REPTILE', 'FISH') (nullable)  -- US 다양성 확장
- is_active: BOOLEAN NOT NULL DEFAULT true
- created_at: TIMESTAMP WITH TIME ZONE
- updated_at: TIMESTAMP WITH TIME ZONE

인덱스:
- idx_products_active (is_active)
- idx_products_brand (brand_name)
- UNIQUE (brand_name, product_name, size_value, size_unit)  -- 중복 방지 강화
```

### 10. product_offers (상품 판매처)
```sql
- id: UUID (PK)
- product_id: UUID (FK -> products.id, CASCADE)
- merchant: ENUM('AMAZON', 'CHEWY', 'PETCO', 'PETSMART', 'WALMART', 'TARGET', 'BRAND', 'COUPANG', 'NAVER') NOT NULL  -- US 중심 확장
- merchant_product_id: VARCHAR(255) NOT NULL
- vendor_item_id: BIGINT (nullable, UNIQUE)  -- Amazon/Chewy vendor ID
- normalized_key: VARCHAR(255) (nullable)  -- 안정적 매핑 키
- url: VARCHAR(500) NOT NULL
- affiliate_url: VARCHAR(500) (nullable)
- seller_name: VARCHAR(120) (nullable)
- is_primary: BOOLEAN NOT NULL DEFAULT false
- is_active: BOOLEAN NOT NULL DEFAULT true
- created_at: TIMESTAMP WITH TIME ZONE
- updated_at: TIMESTAMP WITH TIME ZONE

인덱스:
- ix_offers_product_merchant (product_id, merchant)
- idx_offers_active (is_active)
- UNIQUE (merchant, merchant_product_id)
- UNIQUE (vendor_item_id)
```

### 11. product_ingredient_profiles (상품 성분 프로필)
```sql
- product_id: UUID (PK, FK -> products.id, CASCADE)
- ingredients_text: TEXT (nullable, 원재료 원문)
- additives_text: TEXT (nullable, 첨가물 원문)
- parsed: JSONB (nullable, 토큰화/정규화 결과)
- order_by_weight: JSONB (nullable, AAFCO descending order 배열)  -- 신규, US 규제 준수
- source: VARCHAR(200) (nullable, 공식홈/포장지/크롤링 등)
- version: INTEGER NOT NULL DEFAULT 1  -- 포뮬러 변경 추적용
- updated_at: TIMESTAMPTZ NOT NULL DEFAULT now()
```

### 12. product_nutrition_facts (상품 영양 정보)
```sql
- product_id: UUID (PK, FK -> products.id, CASCADE)
- protein_pct: NUMERIC(5,2) (nullable)
- fat_pct: NUMERIC(5,2) (nullable)
- fiber_pct: NUMERIC(5,2) (nullable)  -- crude fiber
- total_dietary_fiber_pct: NUMERIC(5,2) (nullable)  -- 신규, AAFCO 2024~ 변경
- moisture_pct: NUMERIC(5,2) (nullable)
- ash_pct: NUMERIC(5,2) (nullable)
- kcal_per_100g: INTEGER (nullable)
- kcal_per_cup: INTEGER (nullable)  -- 신규, AAFCO per-cup 의무
- serving_size_cup: NUMERIC(5,2) (nullable)  -- 신규, cup 기준 서빙 사이즈
- calcium_pct: NUMERIC(5,2) (nullable)
- phosphorus_pct: NUMERIC(5,2) (nullable)
- aafco_statement: TEXT (nullable)
- aafco_nutritional_adequacy: TEXT (nullable)  -- 신규, AAFCO 문구 상세
- life_stage: ENUM('ALL_LIFE_STAGES', 'GROWTH', 'ADULT_MAINTENANCE', 'SENIOR') NOT NULL DEFAULT 'ADULT_MAINTENANCE'  -- 신규, AAFCO life stage
- version: INTEGER NOT NULL DEFAULT 1  -- 포뮬러 변경 추적용
- updated_at: TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
```

### 13. product_allergens (상품 알레르겐)
```sql
- product_id: UUID (PK, FK -> products.id, CASCADE)
- allergen_code: VARCHAR(30) (PK, FK -> allergen_codes.code)
- confidence: SMALLINT NOT NULL DEFAULT 80 (0-100)
- source: VARCHAR(200) (nullable)

인덱스:
- idx_product_allergens_allergen (allergen_code)
- CHECK (confidence BETWEEN 0 AND 100)
```

### 14. claim_codes (기능성 클레임 코드)
```sql
- code: VARCHAR(30) (PK)
- display_name: VARCHAR(50) NOT NULL
- display_name_en: VARCHAR(50) NOT NULL  -- 영어 추가
- substantiation_required: BOOLEAN NOT NULL DEFAULT false  -- 신규, FDA/AAFCO 증빙 여부

예시 (US 중심 확장):
- DIGESTIVE: 장/소화 건강 / Digestive Health
- DENTAL: 치아/구강 건강 / Dental Care
- SKIN: 피부/털 건강 / Skin & Coat
- JOINT: 관절 건강 / Joint Health
- WEIGHT: 체중 관리 / Weight Management
- URINARY: 요로 건강 / Urinary Tract Health
- SENIOR: 노령 관리 / Senior Care
- PUPPY: 퍼피 성장 / Puppy Growth
- IMMUNE: 면역력 강화 / Immune Support
- COAT: 털 관리 / Coat Health
- HAIRBALL: 헤어볼 관리 / Hairball Control (신규)
- TAURINE: 타우린 / Taurine Enriched (신규, 고양이 필수)
```

### 15. product_claims (상품 기능성 클레임)
```sql
- product_id: UUID (PK, FK -> products.id, CASCADE)
- claim_code: VARCHAR(30) (PK, FK -> claim_codes.code)
- evidence_level: SMALLINT NOT NULL DEFAULT 50 (0-100)
- substantiation_note: TEXT (nullable)  -- 신규, AAFCO 증빙 설명
- note: TEXT (nullable)

인덱스:
- idx_product_claims_claim (claim_code)
- CHECK (evidence_level BETWEEN 0 AND 100)
```

### 16. price_snapshots (가격 스냅샷)
```sql
- id: UUID (PK)
- offer_id: UUID (FK -> product_offers.id, CASCADE)
- listed_price: INTEGER NOT NULL (페이지 표시 가격)
- shipping_fee: INTEGER NOT NULL DEFAULT 0
- coupon_discount: INTEGER NOT NULL DEFAULT 0
- card_discount: INTEGER NOT NULL DEFAULT 0
- final_price: INTEGER NOT NULL (최종 가격 = listed + shipping - discounts)
- currency: VARCHAR(3) NOT NULL DEFAULT 'USD'  -- US 기본
- is_sold_out: BOOLEAN NOT NULL DEFAULT false
- captured_at: TIMESTAMP WITH TIME ZONE NOT NULL
- captured_source: VARCHAR(50) NOT NULL DEFAULT 'AMAZON_API'  -- US 중심
- meta: JSONB (nullable)
- created_at: TIMESTAMP WITH TIME ZONE

인덱스:
- idx_price_snapshots_offer_time (offer_id, captured_at DESC)
- idx_price_snapshots_offer_final (offer_id, final_price)
```

### 17. price_summaries (가격 요약)
```sql
- offer_id: UUID (PK, FK -> product_offers.id, CASCADE)
- window_days: INTEGER NOT NULL DEFAULT 30
- avg_final_price: INTEGER NOT NULL
- min_final_price: INTEGER NOT NULL
- max_final_price: INTEGER NOT NULL
- last_final_price: INTEGER NOT NULL
- last_captured_at: TIMESTAMP WITH TIME ZONE NOT NULL
- updated_at: TIMESTAMP WITH TIME ZONE
```

### 18. trackings (가격 추적)
```sql
- id: UUID (PK)
- user_id: UUID (FK -> users.id, CASCADE)
- pet_id: UUID (FK -> pets.id, CASCADE)
- product_id: UUID (FK -> products.id, CASCADE)
- status: ENUM('ACTIVE', 'PAUSED', 'DELETED') NOT NULL DEFAULT 'ACTIVE'
- last_checked_at: TIMESTAMP WITH TIME ZONE (nullable)
- next_check_at: TIMESTAMP WITH TIME ZONE (nullable)
- created_at: TIMESTAMP WITH TIME ZONE
- updated_at: TIMESTAMP WITH TIME ZONE

인덱스:
- idx_trackings_user (user_id)
- idx_trackings_pet (pet_id)
- idx_trackings_product (product_id)
- UNIQUE (user_id, pet_id, product_id)
```

### 19. alerts (알림 설정)
```sql
- id: UUID (PK)
- tracking_id: UUID (FK -> trackings.id, CASCADE)
- rule_type: ENUM('BELOW_AVG', 'NEW_LOW', 'TARGET_PRICE') NOT NULL
- target_price: INTEGER (nullable, TARGET_PRICE일 때만)
- cooldown_hours: INTEGER NOT NULL DEFAULT 24
- is_enabled: BOOLEAN NOT NULL DEFAULT true
- last_triggered_at: TIMESTAMP WITH TIME ZONE (nullable)
- last_sent_price: INTEGER (nullable)
- created_at: TIMESTAMP WITH TIME ZONE
- updated_at: TIMESTAMP WITH TIME ZONE

인덱스:
- idx_alerts_tracking_enabled (tracking_id, is_enabled)
```

### 20. alert_events (알림 이벤트)
```sql
- id: UUID (PK)
- alert_id: UUID (FK -> alerts.id, CASCADE)
- trigger_reason: ENUM('BELOW_AVG', 'NEW_LOW', 'TARGET_PRICE') NOT NULL
- price_at_trigger: INTEGER NOT NULL (final_price 기준)
- avg_price_at_trigger: INTEGER (nullable)
- delta_percent: NUMERIC(6,2) (nullable)
- sent_at: TIMESTAMP WITH TIME ZONE NOT NULL
- opened_at: TIMESTAMP WITH TIME ZONE (nullable)
- clicked_at: TIMESTAMP WITH TIME ZONE (nullable)
- status: ENUM('SENT', 'FAILED') NOT NULL DEFAULT 'SENT'
- created_at: TIMESTAMP WITH TIME ZONE

인덱스:
- idx_alert_events_alert_time (alert_id, sent_at DESC)
```

### 21. recommendation_runs (추천 실행 로그)
```sql
- id: UUID (PK)
- user_id: UUID (FK -> users.id, CASCADE)
- pet_id: UUID (FK -> pets.id, CASCADE)
- strategy: ENUM('RULE_V1', 'RULE_V2', 'ML_V1') NOT NULL DEFAULT 'RULE_V1'
- context: JSONB NOT NULL (펫/필터/선호/제외 알레르겐 등 스냅샷)
- created_at: TIMESTAMP WITH TIME ZONE
- updated_at: TIMESTAMP WITH TIME ZONE

인덱스:
- idx_rec_runs_pet_time (pet_id, created_at DESC)
```

### 22. recommendation_items (추천 아이템)
```sql
- run_id: UUID (PK, FK -> recommendation_runs.id, CASCADE)
- product_id: UUID (PK, FK -> products.id, CASCADE)
- rank: INTEGER NOT NULL
- score: NUMERIC(8,4) NOT NULL
- reasons: JSONB NOT NULL (추천 이유 배열)
- score_components: JSONB (nullable)

인덱스:
- idx_rec_items_run_rank (run_id, rank)
```

### 23. outbound_clicks (외부 클릭 추적)
```sql
- id: UUID (PK)
- user_id: UUID (FK -> users.id, CASCADE)
- pet_id: UUID (FK -> pets.id, SET NULL, nullable)
- product_id: UUID (FK -> products.id, CASCADE)
- offer_id: UUID (FK -> product_offers.id, SET NULL, nullable)
- source: VARCHAR(20) NOT NULL (HOME/DETAIL/ALERT)
- clicked_at: TIMESTAMP WITH TIME ZONE NOT NULL
- session_id: VARCHAR(255) (nullable)
- estimated_commission: NUMERIC(10,2) (nullable)
- actual_commission: NUMERIC(10,2) (nullable)
- meta: JSONB (nullable)
- created_at: TIMESTAMP WITH TIME ZONE

인덱스:
- idx_clicks_product_time (product_id, clicked_at DESC)
- idx_clicks_user_time (user_id, clicked_at DESC)
```

### 24. product_reviews (상품 리뷰 - 신규 테이블)
```sql
- id: UUID (PK)
- product_id: UUID (FK -> products.id, CASCADE)
- merchant: ENUM('AMAZON', 'CHEWY', 'PETCO', ...) NOT NULL
- average_rating: NUMERIC(3,2) NOT NULL (1.0-5.0)
- review_count: INTEGER NOT NULL
- last_fetched_at: TIMESTAMP WITH TIME ZONE NOT NULL
- top_reviews: JSONB (nullable, 상위 리뷰 스니펫 배열)
- created_at: TIMESTAMP WITH TIME ZONE
- updated_at: TIMESTAMP WITH TIME ZONE

인덱스:
- idx_product_reviews_product_merchant (product_id, merchant)
- CHECK (average_rating BETWEEN 1.0 AND 5.0)
```

### 25. product_availability (상품 재고·지역 제한 - 신규 테이블)
```sql
- id: UUID (PK)
- product_id: UUID (FK -> products.id, CASCADE)
- merchant: ENUM('AMAZON', 'CHEWY', 'PETCO', ...) NOT NULL
- stock_status: ENUM('IN_STOCK', 'LOW_STOCK', 'OUT_OF_STOCK', 'UNAVAILABLE') NOT NULL
- zip_code_restriction: VARCHAR(20) (nullable, US 우편번호 기반 제한)
- delivery_time_days: INTEGER (nullable, 예상 배송 일수)
- last_checked_at: TIMESTAMP WITH TIME ZONE NOT NULL
- created_at: TIMESTAMP WITH TIME ZONE
- updated_at: TIMESTAMP WITH TIME ZONE

인덱스:
- idx_product_availability_product_merchant (product_id, merchant)
```

---

## 관계도 (ERD) - 확장 후

```
users (1) ──< (N) pets
users (1) ──< (N) trackings
users (1) ──< (N) recommendation_runs
users (1) ──< (N) outbound_clicks

pets (1) ──< (N) trackings
pets (1) ──< (N) pet_health_concerns ──> (N) health_concern_codes
pets (1) ──< (N) pet_food_allergies ──> (N) allergen_codes
pets (1) ──< (1) pet_other_allergies
pets (1) ──< (N) pet_current_foods ──> (N) products
pets (1) ──< (N) recommendation_runs

products (1) ──< (N) product_offers
products (1) ──< (1) product_ingredient_profiles
products (1) ──< (1) product_nutrition_facts
products (1) ──< (N) product_allergens ──> (N) allergen_codes
products (1) ──< (N) product_claims ──> (N) claim_codes
products (1) ──< (N) product_reviews  -- 신규
products (1) ──< (N) product_availability  -- 신규
products (1) ──< (N) trackings
products (1) ──< (N) recommendation_items
products (1) ──< (N) outbound_clicks

product_offers (1) ──< (N) price_snapshots
product_offers (1) ──< (1) price_summaries
product_offers (1) ──< (N) outbound_clicks

trackings (1) ──< (N) alerts
alerts (1) ──< (N) alert_events

recommendation_runs (1) ──< (N) recommendation_items
```

---

## 주요 특징 (미국 확장 후)

1. **UUID 기반**: 유지
2. **CASCADE 삭제**: 유지
3. **TimestampMixin**: 유지
4. **코드 테이블**: 영어 `display_name_en` 추가, US 트렌드 코드 확장 (Hairball, Grain-Free 등)
5. **가격 추적**: currency 'USD' 기본, merchant US 중심
6. **JSONB 활용**: 유지 + `order_by_weight`, `substantiation_note` 등 US 규제 준수
7. **인덱스 최적화**: 유지
8. **신규 테이블**: `product_reviews` (리뷰 통합), `product_availability` (재고·지역)
9. **AAFCO 준수**: `life_stage`, `kcal_per_cup`, `total_dietary_fiber` 등 추가
10. **다국어 지원**: `display_name_en` 추가, unit ENUM으로 단위 유연
11. **단위 시스템**: 무게/사이즈 단위 확장 (LB/OZ/G), 기본값 US 기준
12. **판매처 확장**: Amazon, Chewy, Petco, Petsmart, Walmart, Target 등 US 주요 판매처 추가

---

## 마이그레이션 가이드

### 주요 변경사항

1. **users.timezone**: 기본값 'Asia/Seoul' → 'America/New_York'
2. **pets.weight_kg**: 제거, `weight_numeric` + `weight_unit`로 분리
3. **pets.species**: 'DOG', 'CAT' → 'DOG', 'CAT', 'BIRD', 'SMALL_MAMMAL', 'REPTILE', 'FISH'
4. **products.size_label**: 단일 필드 → `size_value` + `size_unit` + `size_label` (표시용)
5. **products.species**: 'DOG', 'CAT' → 확장 (동일)
6. **product_offers.merchant**: 'COUPANG', 'NAVER', 'BRAND' → US 판매처 추가
7. **price_snapshots.currency**: 기본값 'KRW' → 'USD'
8. **price_snapshots.captured_source**: 기본값 'COUPANG_API' → 'AMAZON_API'
9. **코드 테이블**: `display_name_en` 컬럼 추가
10. **신규 테이블**: `product_reviews`, `product_availability`

### 마이그레이션 순서

1. 코드 테이블에 `display_name_en` 추가 및 데이터 입력
2. `pets` 테이블 스키마 변경 (weight 분리, species 확장)
3. `products` 테이블 스키마 변경 (size 분리, species 확장)
4. `product_offers.merchant` ENUM 확장
5. `product_ingredient_profiles.order_by_weight` 추가
6. `product_nutrition_facts` AAFCO 필드 추가
7. `product_claims.substantiation_note` 추가
8. `price_snapshots` 기본값 변경
9. 신규 테이블 생성 (`product_reviews`, `product_availability`)
10. `users.timezone` 기본값 변경
