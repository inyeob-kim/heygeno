# 데이터베이스 스키마 구조

> **최근 변경사항**: 2026-02-05에 MVP용 스키마 개선사항이 적용되었습니다.
> 자세한 내용은 [SCHEMA_CHANGES_APPLIED.md](./SCHEMA_CHANGES_APPLIED.md)를 참조하세요.

## 전체 테이블 목록

### 1. 사용자 관련
- `users` - 사용자 정보
- `pets` - 반려동물 정보
- `pet_health_concerns` - 펫 건강 고민 (다대다)
- `pet_food_allergies` - 펫 식품 알레르기 (다대다)
- `pet_other_allergies` - 펫 기타 알레르기
- `pet_current_foods` - 펫 현재 급여 사료

### 2. 코드 테이블
- `health_concern_codes` - 건강 고민 코드
- `allergen_codes` - 알레르겐 코드
- `claim_codes` - 기능성 클레임 코드

### 3. 상품 관련
- `products` - 상품 기본 정보
- `product_offers` - 상품 판매처 정보
- `product_ingredient_profiles` - 상품 성분 프로필
- `product_nutrition_facts` - 상품 영양 정보
- `product_allergens` - 상품 알레르겐 (다대다)
- `product_claims` - 상품 기능성 클레임 (다대다)

### 4. 가격 관련
- `price_snapshots` - 가격 스냅샷 (히스토리)
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
- timezone: VARCHAR(50) NOT NULL DEFAULT 'Asia/Seoul'
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
- species: ENUM('DOG', 'CAT') NOT NULL
- age_mode: ENUM('BIRTHDATE', 'APPROX') NOT NULL
- birthdate: DATE (nullable, age_mode='BIRTHDATE'일 때)
- approx_age_months: INTEGER (nullable, age_mode='APPROX'일 때)
- breed_code: VARCHAR(50) (nullable)
- sex: ENUM('MALE', 'FEMALE', 'UNKNOWN') NOT NULL DEFAULT 'UNKNOWN'
- is_neutered: BOOLEAN (nullable)
- weight_kg: NUMERIC(5,2) NOT NULL
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

예시:
- ALLERGY: 알레르기
- DIGESTIVE: 장/소화
- DENTAL: 치아/구강
- OBESITY: 비만
- RESPIRATORY: 호흡기
- SKIN: 피부/털
- JOINT: 관절
- EYE: 눈/눈물
- KIDNEY: 신장/요로
- HEART: 심장
- SENIOR: 노령
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
- size_label: VARCHAR(50) (nullable, 예: "3kg")
- species: ENUM('DOG', 'CAT') (nullable, 전용 사료면 지정)
- is_active: BOOLEAN NOT NULL DEFAULT true
- created_at: TIMESTAMP WITH TIME ZONE
- updated_at: TIMESTAMP WITH TIME ZONE

인덱스:
- idx_products_active (is_active)
- idx_products_brand (brand_name)
- UNIQUE (brand_name, product_name, size_label) [NEW] 중복 방지
```

### 9. product_offers (상품 판매처)
```sql
- id: UUID (PK)
- product_id: UUID (FK -> products.id, CASCADE)
- merchant: ENUM('COUPANG', 'NAVER', 'BRAND') NOT NULL
- merchant_product_id: VARCHAR(255) NOT NULL
- vendor_item_id: BIGINT (nullable, UNIQUE) [NEW] 쿠팡 vendorItemId 매핑용
- normalized_key: VARCHAR(255) (nullable) [NEW] 안정적 매핑 키
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
- UNIQUE (vendor_item_id) [NEW]
```

### 10. product_ingredient_profiles (상품 성분 프로필)
```sql
- product_id: UUID (PK, FK -> products.id, CASCADE)
- ingredients_text: TEXT (nullable, 원재료 원문)
- additives_text: TEXT (nullable, 첨가물 원문)
- parsed: JSONB (nullable, 토큰화/정규화 결과)
- source: VARCHAR(200) (nullable, 공식홈/포장지/크롤링 등)
- version: INTEGER NOT NULL DEFAULT 1 [NEW] 포뮬러 변경 추적용
- updated_at: TIMESTAMPTZ NOT NULL DEFAULT now()
```

### 11. product_nutrition_facts (상품 영양 정보)
```sql
- product_id: UUID (PK, FK -> products.id, CASCADE)
- protein_pct: NUMERIC(5,2) (nullable)
- fat_pct: NUMERIC(5,2) (nullable)
- fiber_pct: NUMERIC(5,2) (nullable)
- moisture_pct: NUMERIC(5,2) (nullable)
- ash_pct: NUMERIC(5,2) (nullable)
- kcal_per_100g: INTEGER (nullable)
- calcium_pct: NUMERIC(5,2) (nullable)
- phosphorus_pct: NUMERIC(5,2) (nullable)
- aafco_statement: TEXT (nullable)
- version: INTEGER NOT NULL DEFAULT 1 [NEW] 포뮬러 변경 추적용
- updated_at: VARCHAR NOT NULL DEFAULT 'now()'
```

### 12. product_allergens (상품 알레르겐)
```sql
- product_id: UUID (PK, FK -> products.id, CASCADE)
- allergen_code: VARCHAR(30) (PK, FK -> allergen_codes.code)
- confidence: SMALLINT NOT NULL DEFAULT 80 (0-100)
- source: VARCHAR(200) (nullable)

인덱스:
- idx_product_allergens_allergen (allergen_code)
- CHECK (confidence BETWEEN 0 AND 100)
```

### 13. claim_codes (기능성 클레임 코드)
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

### 14. product_claims (상품 기능성 클레임)
```sql
- product_id: UUID (PK, FK -> products.id, CASCADE)
- claim_code: VARCHAR(30) (PK, FK -> claim_codes.code)
- evidence_level: SMALLINT NOT NULL DEFAULT 50 (0-100)
- note: TEXT (nullable)

인덱스:
- idx_product_claims_claim (claim_code)
- CHECK (evidence_level BETWEEN 0 AND 100)
```

### 15. price_snapshots (가격 스냅샷)
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
- captured_source: VARCHAR(50) NOT NULL DEFAULT 'COUPANG_API' [NEW] 가격 스냅샷 출처
- meta: JSONB (nullable)
- created_at: TIMESTAMP WITH TIME ZONE

인덱스:
- idx_price_snapshots_offer_time (offer_id, captured_at DESC)
- idx_price_snapshots_offer_final (offer_id, final_price)
```

### 16. price_summaries (가격 요약)
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

### 17. trackings (가격 추적)
```sql
- id: UUID (PK)
- user_id: UUID (FK -> users.id, CASCADE)
- pet_id: UUID (FK -> pets.id, CASCADE)
- product_id: UUID (FK -> products.id, CASCADE)
- status: ENUM('ACTIVE', 'PAUSED', 'DELETED') NOT NULL DEFAULT 'ACTIVE'
- last_checked_at: TIMESTAMP WITH TIME ZONE (nullable) [MID-TERM] 마지막 가격 확인 시간
- next_check_at: TIMESTAMP WITH TIME ZONE (nullable) [MID-TERM] 다음 가격 확인 예정 시간
- created_at: TIMESTAMP WITH TIME ZONE
- updated_at: TIMESTAMP WITH TIME ZONE

인덱스:
- idx_trackings_user (user_id)
- idx_trackings_pet (pet_id)
- idx_trackings_product (product_id)
- UNIQUE (user_id, pet_id, product_id)
```

### 18. alerts (알림 설정)
```sql
- id: UUID (PK)
- tracking_id: UUID (FK -> trackings.id, CASCADE)
- rule_type: ENUM('BELOW_AVG', 'NEW_LOW', 'TARGET_PRICE') NOT NULL
- target_price: INTEGER (nullable, TARGET_PRICE일 때만)
- cooldown_hours: INTEGER NOT NULL DEFAULT 24
- is_enabled: BOOLEAN NOT NULL DEFAULT true
- last_triggered_at: TIMESTAMP WITH TIME ZONE (nullable)
- last_sent_price: INTEGER (nullable) [MID-TERM] 알림 중복 발송 방지용 마지막 전송 가격
- created_at: TIMESTAMP WITH TIME ZONE
- updated_at: TIMESTAMP WITH TIME ZONE

인덱스:
- idx_alerts_tracking_enabled (tracking_id, is_enabled)
```

### 19. alert_events (알림 이벤트)
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

### 20. recommendation_runs (추천 실행 로그)
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

### 21. recommendation_items (추천 아이템)
```sql
- run_id: UUID (PK, FK -> recommendation_runs.id, CASCADE)
- product_id: UUID (PK, FK -> products.id, CASCADE)
- rank: INTEGER NOT NULL
- score: NUMERIC(8,4) NOT NULL
- reasons: JSONB NOT NULL (추천 이유 배열)
- score_components: JSONB (nullable) [MID-TERM] 추천 이유 디버깅 + 설명용 세부 점수 분해

인덱스:
- idx_rec_items_run_rank (run_id, rank)
```

### 22. outbound_clicks (외부 클릭 추적)
```sql
- id: UUID (PK)
- user_id: UUID (FK -> users.id, CASCADE)
- pet_id: UUID (FK -> pets.id, SET NULL, nullable)
- product_id: UUID (FK -> products.id, CASCADE)
- offer_id: UUID (FK -> product_offers.id, SET NULL, nullable)
- source: VARCHAR(20) NOT NULL (HOME/DETAIL/ALERT)
- clicked_at: TIMESTAMP WITH TIME ZONE NOT NULL
- session_id: VARCHAR(255) (nullable)
- estimated_commission: NUMERIC(10,2) (nullable) [MID-TERM] 어필리에이트 수익 분석용 예상 커미션
- actual_commission: NUMERIC(10,2) (nullable) [MID-TERM] 어필리에이트 수익 분석용 실제 커미션
- meta: JSONB (nullable)
- created_at: TIMESTAMP WITH TIME ZONE

인덱스:
- idx_clicks_product_time (product_id, clicked_at DESC)
- idx_clicks_user_time (user_id, clicked_at DESC)
```

---

## 관계도 (ERD)

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

## 주요 특징

1. **UUID 기반**: 모든 테이블이 UUID를 PK로 사용
2. **CASCADE 삭제**: 부모 삭제 시 자식도 자동 삭제 (대부분)
3. **TimestampMixin**: created_at, updated_at 자동 관리
4. **코드 테이블**: 건강 고민, 알레르겐, 클레임은 코드 테이블로 정규화
5. **가격 추적**: final_price 기준으로 통일
6. **JSONB 활용**: 유연한 데이터 저장 (context, reasons, meta 등)
7. **인덱스 최적화**: 자주 조회되는 컬럼에 인덱스 설정
