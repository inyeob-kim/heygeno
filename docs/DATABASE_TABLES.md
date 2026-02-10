# 데이터베이스 테이블 구조 (전체 컬럼 상세)

> 최종 업데이트: 2026-02-05
> 실제 모델 파일 기반 정리

---

## 1. 사용자 관련

### 1.1 users (사용자)
| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| id | UUID | PK | 사용자 고유 ID |
| provider | VARCHAR(50) | NOT NULL, DEFAULT 'DEVICE' | 인증 제공자 (현재는 DEVICE만) |
| provider_user_id | VARCHAR(255) | NOT NULL | device_uid |
| nickname | VARCHAR(50) | NOT NULL | 닉네임 |
| timezone | VARCHAR(50) | NOT NULL, DEFAULT 'Asia/Seoul' | 타임존 |
| created_at | TIMESTAMP WITH TIME ZONE | | 생성 시간 |
| updated_at | TIMESTAMP WITH TIME ZONE | | 수정 시간 |

**인덱스:**
- `idx_users_provider_user_id` (provider, provider_user_id)
- `idx_users_nickname` (nickname)
- UNIQUE (provider, provider_user_id)

---

### 1.2 pets (반려동물)
| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| id | UUID | PK | 반려동물 고유 ID |
| user_id | UUID | FK → users.id, CASCADE, NOT NULL | 사용자 ID |
| name | VARCHAR(100) | NOT NULL | 반려동물 이름 |
| species | ENUM('DOG', 'CAT') | NOT NULL | 종류 |
| age_mode | ENUM('BIRTHDATE', 'APPROX') | NOT NULL | 나이 입력 방식 |
| birthdate | DATE | NULLABLE | 생년월일 (age_mode='BIRTHDATE'일 때) |
| approx_age_months | INTEGER | NULLABLE | 대략 나이 개월수 (age_mode='APPROX'일 때) |
| breed_code | VARCHAR(50) | NULLABLE | 품종 코드 |
| sex | ENUM('MALE', 'FEMALE', 'UNKNOWN') | NOT NULL, DEFAULT 'UNKNOWN' | 성별 |
| is_neutered | BOOLEAN | NULLABLE | 중성화 여부 |
| weight_kg | NUMERIC(5,2) | NOT NULL | 체중 (kg) |
| body_condition_score | INTEGER | NOT NULL, CHECK(1-9) | 체형 점수 (1-9) |
| age_stage | ENUM('PUPPY', 'ADULT', 'SENIOR') | NOT NULL | 나이 단계 (계산된 필드) |
| photo_url | VARCHAR(500) | NULLABLE | 사진 URL |
| is_primary | BOOLEAN | NOT NULL, DEFAULT true | 기본 펫 여부 |
| created_at | TIMESTAMP WITH TIME ZONE | | 생성 시간 |
| updated_at | TIMESTAMP WITH TIME ZONE | | 수정 시간 |

**인덱스:**
- `idx_pets_species_breed` (species, breed_code)
- `idx_pets_age_stage` (age_stage)

---

### 1.3 health_concern_codes (건강 고민 코드)
| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| code | VARCHAR(30) | PK | 건강 고민 코드 |
| display_name | VARCHAR(50) | NOT NULL | 표시명 |

**예시 코드:**
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

---

### 1.4 pet_health_concerns (펫-건강고민)
| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| pet_id | UUID | PK, FK → pets.id, CASCADE | 반려동물 ID |
| concern_code | VARCHAR(30) | PK, FK → health_concern_codes.code | 건강 고민 코드 |

---

### 1.5 allergen_codes (알레르겐 코드)
| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| code | VARCHAR(30) | PK | 알레르겐 코드 |
| display_name | VARCHAR(50) | NOT NULL | 표시명 |

**예시 코드:**
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

---

### 1.6 pet_food_allergies (펫-식품 알레르기)
| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| pet_id | UUID | PK, FK → pets.id, CASCADE | 반려동물 ID |
| allergen_code | VARCHAR(30) | PK, FK → allergen_codes.code | 알레르겐 코드 |

---

### 1.7 pet_other_allergies (펫 기타 알레르기)
| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| pet_id | UUID | PK, FK → pets.id, CASCADE | 반려동물 ID |
| other_text | TEXT | NOT NULL | 기타 알레르기 텍스트 |
| created_at | TIMESTAMP WITH TIME ZONE | | 생성 시간 |
| updated_at | TIMESTAMP WITH TIME ZONE | | 수정 시간 |

---

### 1.8 pet_current_foods (펫 현재 급여 사료)
| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| id | UUID | PK | 현재 급여 사료 ID |
| pet_id | UUID | FK → pets.id, CASCADE, NOT NULL | 반려동물 ID |
| product_id | UUID | FK → products.id, RESTRICT, NOT NULL | 상품 ID |
| feed_type | VARCHAR(10) | NOT NULL | 급여 타입 ('MAIN' \| 'SUB') |
| is_active | BOOLEAN | NOT NULL, DEFAULT true | 활성화 여부 |
| started_at | TIMESTAMP WITH TIME ZONE | NULLABLE | 시작 시간 |
| ended_at | TIMESTAMP WITH TIME ZONE | NULLABLE | 종료 시간 |
| meals_per_day | SMALLINT | NULLABLE, CHECK(1-4) | 하루 급여 횟수 (1~4) |
| daily_amount_level | VARCHAR(10) | NULLABLE | 일일 급여량 수준 ('LOW' \| 'MEDIUM' \| 'HIGH') |
| treats_level | VARCHAR(10) | NULLABLE | 간식 수준 ('NONE' \| 'SOME' \| 'OFTEN') |
| estimated_days_per_bag | INTEGER | NULLABLE, CHECK(1-365) | 봉지당 예상 일수 (1~365) |
| last_confirmed_at | TIMESTAMP WITH TIME ZONE | NULLABLE | 마지막 확인 시간 |
| created_at | TIMESTAMP WITH TIME ZONE | | 생성 시간 |
| updated_at | TIMESTAMP WITH TIME ZONE | | 수정 시간 |

**인덱스:**
- `idx_pcf_pet_active` (pet_id, is_active)
- `idx_pcf_product_active` (product_id, is_active)
- `idx_pcf_pet_feedtype_active` (pet_id, feed_type, is_active)
- UNIQUE `uq_pcf_pet_main_active` (pet_id) WHERE is_active = true AND feed_type = 'MAIN'
- UNIQUE `uq_pcf_pet_sub_active` (pet_id) WHERE is_active = true AND feed_type = 'SUB'

**제약조건:**
- `chk_meals_per_day`: meals_per_day IS NULL OR meals_per_day BETWEEN 1 AND 4
- `chk_estimated_days`: estimated_days_per_bag IS NULL OR estimated_days_per_bag BETWEEN 1 AND 365
- `chk_ended_after_started`: ended_at IS NULL OR started_at IS NULL OR ended_at >= started_at

**특징:**
- Partial unique index로 활성 MAIN은 펫당 1개만, 활성 SUB도 펫당 1개만 허용
- product_id는 RESTRICT로 설정되어 상품 삭제 시 현재 급여 중인 사료가 있으면 삭제 방지

---

## 2. 상품 관련

### 2.1 products (상품)
| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| id | UUID | PK | 상품 고유 ID |
| category | VARCHAR(30) | NOT NULL, DEFAULT 'FOOD' | 카테고리 (현재는 FOOD만) |
| brand_name | VARCHAR(100) | NOT NULL | 브랜드명 |
| product_name | VARCHAR(255) | NOT NULL | 상품명 |
| size_label | VARCHAR(50) | NULLABLE | 크기 라벨 (예: "3kg", "5kg") |
| species | ENUM('DOG', 'CAT') | NULLABLE | 전용 종류 (공용이면 NULL) |
| is_active | BOOLEAN | NOT NULL, DEFAULT true | 활성화 여부 |
| created_at | TIMESTAMP WITH TIME ZONE | | 생성 시간 |
| updated_at | TIMESTAMP WITH TIME ZONE | | 수정 시간 |

**인덱스:**
- `idx_products_active` (is_active)
- `idx_products_brand` (brand_name)
- UNIQUE (brand_name, product_name, size_label)

---

### 2.2 product_offers (상품 판매처)
| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| id | UUID | PK | 판매처 정보 ID |
| product_id | UUID | FK → products.id, CASCADE, NOT NULL | 상품 ID |
| merchant | ENUM('COUPANG', 'NAVER', 'BRAND') | NOT NULL | 판매처 |
| merchant_product_id | VARCHAR(255) | NOT NULL | 판매처 상품 ID |
| vendor_item_id | BIGINT | NULLABLE, UNIQUE | 쿠팡 vendorItemId 매핑용 |
| normalized_key | VARCHAR(255) | NULLABLE | 안정적 매핑 키 |
| url | VARCHAR(500) | NOT NULL | 상품 URL |
| affiliate_url | VARCHAR(500) | NULLABLE | 어필리에이트 URL |
| seller_name | VARCHAR(120) | NULLABLE | 판매자명 (네이버/오픈마켓 대비) |
| is_primary | BOOLEAN | NOT NULL, DEFAULT false | 기본 판매처 여부 |
| is_active | BOOLEAN | NOT NULL, DEFAULT true | 활성화 여부 |
| created_at | TIMESTAMP WITH TIME ZONE | | 생성 시간 |
| updated_at | TIMESTAMP WITH TIME ZONE | | 수정 시간 |

**인덱스:**
- `ix_offers_product_merchant` (product_id, merchant)
- `idx_offers_active` (is_active)
- UNIQUE (merchant, merchant_product_id)
- UNIQUE (vendor_item_id)

---

### 2.3 product_ingredient_profiles (상품 성분 프로필)
| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| product_id | UUID | PK, FK → products.id, CASCADE | 상품 ID |
| ingredients_text | TEXT | NULLABLE | 원재료 원문 |
| additives_text | TEXT | NULLABLE | 첨가물 원문 |
| parsed | JSONB | NULLABLE | 토큰화/정규화 결과 (AI 파싱 결과) |
| source | VARCHAR(200) | NULLABLE | 출처 (공식홈/포장지/크롤링 등) |
| version | INTEGER | NOT NULL, DEFAULT 1 | 포뮬러 변경 추적용 버전 |
| updated_at | TIMESTAMP WITH TIME ZONE | NOT NULL, DEFAULT now() | 업데이트 시간 |

---

### 2.4 product_nutrition_facts (상품 영양 정보)
| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| product_id | UUID | PK, FK → products.id, CASCADE | 상품 ID |
| protein_pct | NUMERIC(5,2) | NULLABLE | 단백질 함량 (%) |
| fat_pct | NUMERIC(5,2) | NULLABLE | 지방 함량 (%) |
| fiber_pct | NUMERIC(5,2) | NULLABLE | 섬유질 함량 (%) |
| moisture_pct | NUMERIC(5,2) | NULLABLE | 수분 함량 (%) |
| ash_pct | NUMERIC(5,2) | NULLABLE | 회분 함량 (%) |
| kcal_per_100g | INTEGER | NULLABLE | 100g당 칼로리 |
| calcium_pct | NUMERIC(5,2) | NULLABLE | 칼슘 함량 (%) |
| phosphorus_pct | NUMERIC(5,2) | NULLABLE | 인 함량 (%) |
| aafco_statement | TEXT | NULLABLE | AAFCO 문구 |
| version | INTEGER | NOT NULL, DEFAULT 1 | 포뮬러 변경 추적용 버전 |
| updated_at | TIMESTAMP WITH TIME ZONE | NOT NULL, DEFAULT now() | 업데이트 시간 |

---

### 2.5 product_allergens (상품 알레르겐)
| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| product_id | UUID | PK, FK → products.id, CASCADE | 상품 ID |
| allergen_code | VARCHAR(30) | PK, FK → allergen_codes.code | 알레르겐 코드 |
| confidence | SMALLINT | NOT NULL, DEFAULT 80, CHECK(0-100) | 신뢰도 (0-100) |
| source | VARCHAR(200) | NULLABLE | 출처 |

**인덱스:**
- `idx_product_allergens_allergen` (allergen_code)

---

### 2.6 claim_codes (기능성 클레임 코드)
| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| code | VARCHAR(30) | PK | 클레임 코드 |
| display_name | VARCHAR(50) | NOT NULL | 표시명 |

**예시 코드:**
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

---

### 2.7 product_claims (상품 기능성 클레임)
| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| product_id | UUID | PK, FK → products.id, CASCADE | 상품 ID |
| claim_code | VARCHAR(30) | PK, FK → claim_codes.code | 클레임 코드 |
| evidence_level | SMALLINT | NOT NULL, DEFAULT 50, CHECK(0-100) | 증거 수준 (0-100) |
| note | TEXT | NULLABLE | 메모 |

**인덱스:**
- `idx_product_claims_claim` (claim_code)

---

## 3. 가격 관련

### 3.1 price_snapshots (가격 스냅샷)
| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| id | UUID | PK | 스냅샷 ID |
| offer_id | UUID | FK → product_offers.id, CASCADE, NOT NULL | 판매처 ID |
| listed_price | INTEGER | NOT NULL | 페이지 표시 가격 |
| shipping_fee | INTEGER | NOT NULL, DEFAULT 0 | 배송비 |
| coupon_discount | INTEGER | NOT NULL, DEFAULT 0 | 쿠폰 할인 |
| card_discount | INTEGER | NOT NULL, DEFAULT 0 | 카드 할인 |
| final_price | INTEGER | NOT NULL | 최종 가격 (listed + shipping - discounts) |
| currency | VARCHAR(3) | NOT NULL, DEFAULT 'KRW' | 통화 |
| is_sold_out | BOOLEAN | NOT NULL, DEFAULT false | 품절 여부 |
| captured_at | TIMESTAMP WITH TIME ZONE | NOT NULL | 캡처 시간 |
| captured_source | VARCHAR(50) | NOT NULL, DEFAULT 'COUPANG_API' | 가격 스냅샷 출처 |
| meta | JSONB | NULLABLE | 메타데이터 |
| created_at | TIMESTAMP WITH TIME ZONE | NOT NULL | 생성 시간 |

**인덱스:**
- `idx_price_snapshots_offer_time` (offer_id, captured_at DESC)
- `idx_price_snapshots_offer_final` (offer_id, final_price)

---

### 3.2 price_summaries (가격 요약)
| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| offer_id | UUID | PK, FK → product_offers.id, CASCADE | 판매처 ID |
| window_days | INTEGER | NOT NULL, DEFAULT 30 | 기간 (일) |
| avg_final_price | INTEGER | NOT NULL | 평균 최종 가격 |
| min_final_price | INTEGER | NOT NULL | 최소 최종 가격 |
| max_final_price | INTEGER | NOT NULL | 최대 최종 가격 |
| last_final_price | INTEGER | NOT NULL | 마지막 최종 가격 |
| last_captured_at | TIMESTAMP WITH TIME ZONE | NOT NULL | 마지막 캡처 시간 |
| updated_at | TIMESTAMP WITH TIME ZONE | NOT NULL | 업데이트 시간 |

---

## 4. 추적 관련

### 4.1 trackings (가격 추적)
| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| id | UUID | PK | 추적 ID |
| user_id | UUID | FK → users.id, CASCADE, NOT NULL | 사용자 ID |
| pet_id | UUID | FK → pets.id, CASCADE, NOT NULL | 반려동물 ID |
| product_id | UUID | FK → products.id, CASCADE, NOT NULL | 상품 ID |
| status | ENUM('ACTIVE', 'PAUSED', 'DELETED') | NOT NULL, DEFAULT 'ACTIVE' | 상태 |
| last_checked_at | TIMESTAMP WITH TIME ZONE | NULLABLE | 마지막 가격 확인 시간 |
| next_check_at | TIMESTAMP WITH TIME ZONE | NULLABLE | 다음 가격 확인 예정 시간 |
| created_at | TIMESTAMP WITH TIME ZONE | | 생성 시간 |
| updated_at | TIMESTAMP WITH TIME ZONE | | 수정 시간 |

**인덱스:**
- `idx_trackings_user` (user_id)
- `idx_trackings_pet` (pet_id)
- `idx_trackings_product` (product_id)
- UNIQUE (user_id, pet_id, product_id)

---

### 4.2 alerts (알림 설정)
| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| id | UUID | PK | 알림 ID |
| tracking_id | UUID | FK → trackings.id, CASCADE, NOT NULL | 추적 ID |
| rule_type | ENUM('BELOW_AVG', 'NEW_LOW', 'TARGET_PRICE') | NOT NULL | 규칙 타입 |
| target_price | INTEGER | NULLABLE | 목표 가격 (TARGET_PRICE일 때만) |
| cooldown_hours | INTEGER | NOT NULL, DEFAULT 24 | 쿨다운 시간 (시간) |
| is_enabled | BOOLEAN | NOT NULL, DEFAULT true | 활성화 여부 |
| last_triggered_at | TIMESTAMP WITH TIME ZONE | NULLABLE | 마지막 트리거 시간 |
| last_sent_price | INTEGER | NULLABLE | 알림 중복 발송 방지용 마지막 전송 가격 |
| created_at | TIMESTAMP WITH TIME ZONE | | 생성 시간 |
| updated_at | TIMESTAMP WITH TIME ZONE | | 수정 시간 |

**인덱스:**
- `idx_alerts_tracking_enabled` (tracking_id, is_enabled)

---

### 4.3 alert_events (알림 이벤트)
| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| id | UUID | PK | 이벤트 ID |
| alert_id | UUID | FK → alerts.id, CASCADE, NOT NULL | 알림 ID |
| trigger_reason | ENUM('BELOW_AVG', 'NEW_LOW', 'TARGET_PRICE') | NOT NULL | 트리거 이유 |
| price_at_trigger | INTEGER | NOT NULL | 트리거 시 가격 (final_price 기준) |
| avg_price_at_trigger | INTEGER | NULLABLE | 트리거 시 평균 가격 |
| delta_percent | NUMERIC(6,2) | NULLABLE | 변화율 (%) |
| sent_at | TIMESTAMP WITH TIME ZONE | NOT NULL | 전송 시간 |
| opened_at | TIMESTAMP WITH TIME ZONE | NULLABLE | 열람 시간 |
| clicked_at | TIMESTAMP WITH TIME ZONE | NULLABLE | 클릭 시간 |
| status | ENUM('SENT', 'FAILED') | NOT NULL, DEFAULT 'SENT' | 상태 |
| created_at | TIMESTAMP WITH TIME ZONE | NOT NULL | 생성 시간 |

**인덱스:**
- `idx_alert_events_alert_time` (alert_id, sent_at DESC)

---

## 5. 추천 관련

### 5.1 recommendation_runs (추천 실행 로그)
| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| id | UUID | PK | 실행 ID |
| user_id | UUID | FK → users.id, CASCADE, NOT NULL | 사용자 ID |
| pet_id | UUID | FK → pets.id, CASCADE, NOT NULL | 반려동물 ID |
| strategy | ENUM('RULE_V1', 'RULE_V2', 'ML_V1') | NOT NULL, DEFAULT 'RULE_V1' | 추천 전략 |
| context | JSONB | NOT NULL | 펫/필터/선호/제외 알레르겐 등 스냅샷 |
| created_at | TIMESTAMP WITH TIME ZONE | | 생성 시간 |
| updated_at | TIMESTAMP WITH TIME ZONE | | 수정 시간 |

**인덱스:**
- `idx_rec_runs_pet_time` (pet_id, created_at DESC)

---

### 5.2 recommendation_items (추천 아이템)
| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| run_id | UUID | PK, FK → recommendation_runs.id, CASCADE | 실행 ID |
| product_id | UUID | PK, FK → products.id, CASCADE | 상품 ID |
| rank | INTEGER | NOT NULL | 순위 |
| score | NUMERIC(8,4) | NOT NULL | 점수 |
| reasons | JSONB | NOT NULL | 추천 이유 배열 |
| score_components | JSONB | NULLABLE | 추천 이유 디버깅 + 설명용 세부 점수 분해 |

**인덱스:**
- `idx_rec_items_run_rank` (run_id, rank)

---

## 6. 포인트 관련

### 6.1 point_wallets (포인트 지갑)
| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| user_id | UUID | PK, FK → users.id, CASCADE | 사용자 ID |
| balance | INTEGER | NOT NULL, DEFAULT 0 | 잔액 |
| updated_at | TIMESTAMP WITH TIME ZONE | NOT NULL | 업데이트 시간 |

---

### 6.2 point_ledger (포인트 장부)
| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| id | UUID | PK | 장부 ID |
| user_id | UUID | FK → users.id, CASCADE, NOT NULL | 사용자 ID |
| delta | INTEGER | NOT NULL | 변화량 (+1000 / -500) |
| reason | TEXT | NOT NULL | 사유 (예: campaign:first_tracking_1000p) |
| ref_type | VARCHAR(50) | NULLABLE | 참조 타입 (예: campaign_reward) |
| ref_id | UUID | NULLABLE | 참조 ID |
| created_at | TIMESTAMP WITH TIME ZONE | NOT NULL | 생성 시간 |

**인덱스:**
- `idx_point_ledger_user` (user_id)

---

## 7. 캠페인 관련

### 7.1 campaigns (캠페인)
| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| id | UUID | PK | 캠페인 ID |
| key | TEXT | NOT NULL, UNIQUE | 캠페인 키 (예: 'first_tracking_1000p') |
| kind | VARCHAR(20) | NOT NULL | 종류 (EVENT \| NOTICE \| AD) |
| placement | VARCHAR(30) | NOT NULL | 배치 (HOME_MODAL \| HOME_BANNER \| NOTICE_CENTER) |
| template | VARCHAR(30) | NOT NULL | 템플릿 (image_top \| no_image \| product_spotlight) |
| priority | INTEGER | NOT NULL, DEFAULT 100 | 우선순위 |
| is_enabled | BOOLEAN | NOT NULL, DEFAULT true | 활성화 여부 |
| start_at | TIMESTAMP WITH TIME ZONE | NOT NULL | 시작 시간 |
| end_at | TIMESTAMP WITH TIME ZONE | NOT NULL | 종료 시간 |
| content | JSONB | NOT NULL, DEFAULT '{}' | 내용 (제목, 본문, 이미지 URL 등) |
| created_at | TIMESTAMP WITH TIME ZONE | | 생성 시간 |
| updated_at | TIMESTAMP WITH TIME ZONE | | 수정 시간 |

**인덱스:**
- `idx_campaigns_active` (is_enabled, start_at, end_at, priority)

---

### 7.2 campaign_rules (캠페인 규칙)
| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| id | UUID | PK | 규칙 ID |
| campaign_id | UUID | FK → campaigns.id, CASCADE, NOT NULL | 캠페인 ID |
| rule | JSONB | NOT NULL | 조건 규칙 (JSON Rule Engine) |
| created_at | TIMESTAMP WITH TIME ZONE | NOT NULL | 생성 시간 |

**인덱스:**
- `idx_campaign_rules_campaign` (campaign_id)
- `idx_campaign_rules_gin` (rule) - GIN 인덱스

---

### 7.3 campaign_actions (캠페인 액션)
| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| id | UUID | PK | 액션 ID |
| campaign_id | UUID | FK → campaigns.id, CASCADE, NOT NULL | 캠페인 ID |
| trigger | VARCHAR(50) | NOT NULL | 트리거 (FIRST_TRACKING_CREATED \| ALERT_CLICKED \| REFERRAL_CONFIRMED) |
| action_type | VARCHAR(30) | NOT NULL | 액션 타입 (GRANT_POINTS \| SHOW_ONLY) |
| action | JSONB | NOT NULL | 액션 내용 (예: { "points": 1000 }) |
| created_at | TIMESTAMP WITH TIME ZONE | NOT NULL | 생성 시간 |

**인덱스:**
- `idx_campaign_actions_campaign` (campaign_id)
- `idx_campaign_actions_trigger` (trigger)

---

### 7.4 user_campaign_impressions (유저 캠페인 노출 기록)
| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| id | UUID | PK | 노출 기록 ID |
| user_id | UUID | FK → users.id, CASCADE, NOT NULL | 사용자 ID |
| campaign_id | UUID | FK → campaigns.id, CASCADE, NOT NULL | 캠페인 ID |
| first_seen_at | TIMESTAMP WITH TIME ZONE | NOT NULL | 최초 노출 시간 |
| last_seen_at | TIMESTAMP WITH TIME ZONE | NOT NULL | 마지막 노출 시간 |
| seen_count | INTEGER | NOT NULL, DEFAULT 1 | 노출 횟수 |
| suppress_until | TIMESTAMP WITH TIME ZONE | NULLABLE | 억제 종료 시간 |

**인덱스:**
- `idx_user_campaign_impressions_user` (user_id)
- UNIQUE (user_id, campaign_id)

---

### 7.5 user_campaign_rewards (유저 캠페인 보상)
| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| id | UUID | PK | 보상 ID |
| user_id | UUID | FK → users.id, CASCADE, NOT NULL | 사용자 ID |
| campaign_id | UUID | FK → campaigns.id, CASCADE, NOT NULL | 캠페인 ID |
| action_id | UUID | FK → campaign_actions.id, CASCADE, NOT NULL | 액션 ID |
| status | VARCHAR(20) | NOT NULL | 상태 (GRANTED \| FAILED \| PENDING) |
| granted_at | TIMESTAMP WITH TIME ZONE | NULLABLE | 지급 시간 |
| idempotency_key | TEXT | NULLABLE | 중복 지급 방지용 키 |

**인덱스:**
- `idx_user_campaign_rewards_user` (user_id)
- UNIQUE (user_id, campaign_id, action_id)

---

## 8. 리퍼럴 관련

### 8.1 referral_codes (리퍼럴 코드)
| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| inviter_user_id | UUID | PK, FK → users.id, CASCADE | 초대자 사용자 ID |
| code | TEXT | NOT NULL, UNIQUE | 리퍼럴 코드 |
| created_at | TIMESTAMP WITH TIME ZONE | NOT NULL | 생성 시간 |

---

### 8.2 referrals (리퍼럴 기록)
| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| id | UUID | PK | 리퍼럴 ID |
| code | TEXT | FK → referral_codes.code, NOT NULL | 리퍼럴 코드 |
| invitee_user_id | UUID | FK → users.id, SET NULL, NULLABLE | 피초대자 사용자 ID |
| invitee_device_id | TEXT | NULLABLE | 가입 전 device_uid |
| status | VARCHAR(20) | NOT NULL | 상태 (PENDING \| CONFIRMED \| REWARDED) |
| confirmed_at | TIMESTAMP WITH TIME ZONE | NULLABLE | 확인 시간 |
| created_at | TIMESTAMP WITH TIME ZONE | NOT NULL | 생성 시간 |

**인덱스:**
- `idx_referrals_code` (code)
- `idx_referrals_status` (status)
- UNIQUE (invitee_user_id)

---

## 9. 기타

### 9.1 outbound_clicks (외부 클릭 추적)
| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| id | UUID | PK | 클릭 ID |
| user_id | UUID | FK → users.id, CASCADE, NOT NULL | 사용자 ID |
| pet_id | UUID | FK → pets.id, SET NULL, NULLABLE | 반려동물 ID |
| product_id | UUID | FK → products.id, CASCADE, NOT NULL | 상품 ID |
| offer_id | UUID | FK → product_offers.id, SET NULL, NULLABLE | 판매처 ID |
| source | VARCHAR(20) | NOT NULL | 출처 (HOME \| DETAIL \| ALERT) |
| clicked_at | TIMESTAMP WITH TIME ZONE | NOT NULL | 클릭 시간 |
| session_id | VARCHAR(255) | NULLABLE | 세션 ID |
| estimated_commission | NUMERIC(10,2) | NULLABLE | 예상 커미션 |
| actual_commission | NUMERIC(10,2) | NULLABLE | 실제 커미션 |
| meta | JSONB | NULLABLE | 메타데이터 |
| created_at | TIMESTAMP WITH TIME ZONE | NOT NULL | 생성 시간 |

**인덱스:**
- `idx_clicks_product_time` (product_id, clicked_at DESC)
- `idx_clicks_user_time` (user_id, clicked_at DESC)

---

## 테이블 관계 요약

### 주요 관계:
- `users` (1) ──< (N) `pets`
- `users` (1) ──< (N) `trackings`
- `users` (1) ──< (N) `recommendation_runs`
- `users` (1) ──< (N) `outbound_clicks`
- `pets` (1) ──< (N) `pet_health_concerns` ──> (N) `health_concern_codes`
- `pets` (1) ──< (N) `pet_food_allergies` ──> (N) `allergen_codes`
- `pets` (1) ──< (1) `pet_other_allergies`
- `pets` (1) ──< (N) `pet_current_foods` ──> (N) `products`
- `products` (1) ──< (N) `product_offers`
- `products` (1) ──< (1) `product_ingredient_profiles`
- `products` (1) ──< (1) `product_nutrition_facts`
- `products` (1) ──< (N) `product_allergens` ──> (N) `allergen_codes`
- `products` (1) ──< (N) `product_claims` ──> (N) `claim_codes`
- `product_offers` (1) ──< (N) `price_snapshots`
- `product_offers` (1) ──< (1) `price_summaries`
- `trackings` (1) ──< (N) `alerts`
- `alerts` (1) ──< (N) `alert_events`
- `recommendation_runs` (1) ──< (N) `recommendation_items`
- `campaigns` (1) ──< (N) `campaign_rules`
- `campaigns` (1) ──< (N) `campaign_actions`
- `campaigns` (1) ──< (N) `user_campaign_impressions`
- `campaigns` (1) ──< (N) `user_campaign_rewards`

---

## 주요 특징

1. **UUID 기반**: 모든 테이블이 UUID를 PK로 사용
2. **CASCADE 삭제**: 부모 삭제 시 자식도 자동 삭제 (대부분)
3. **TimestampMixin**: created_at, updated_at 자동 관리
4. **코드 테이블**: 건강 고민, 알레르겐, 클레임은 코드 테이블로 정규화
5. **가격 추적**: final_price 기준으로 통일
6. **JSONB 활용**: 유연한 데이터 저장 (context, reasons, meta, content, rule, action 등)
7. **인덱스 최적화**: 자주 조회되는 컬럼에 인덱스 설정
8. **ENUM 타입**: 상태, 종류 등 제한된 값은 ENUM으로 관리
