# 데이터베이스 스키마 변경사항 적용 가이드

## 적용된 변경사항

### ✅ 즉시 적용 (MVP용) - 마이그레이션: `8464df52ccf5`

#### 1. product_offers 테이블 - 쿠팡 vendorItemId 매핑
```sql
ALTER TABLE product_offers
ADD COLUMN vendor_item_id BIGINT UNIQUE,
ADD COLUMN normalized_key VARCHAR(255);
```

**목적**: 쿠팡 API의 vendorItemId를 안정적으로 매핑하기 위한 필드 추가
- `vendor_item_id`: 쿠팡의 vendorItemId를 저장 (BIGINT, UNIQUE)
- `normalized_key`: 안정적인 매핑을 위한 정규화된 키

**모델 변경**: `backend/app/models/offer.py`
- `vendor_item_id: Column(BigInteger, nullable=True, unique=True)`
- `normalized_key: Column(String(255), nullable=True)`

#### 2. products 테이블 - 중복 방지 제약
```sql
ALTER TABLE products
ADD CONSTRAINT unique_brand_name_size 
UNIQUE (brand_name, product_name, size_label);
```

**목적**: 동일한 브랜드명, 제품명, 용량의 상품 중복 생성 방지
- 같은 상품의 다른 용량은 별도 레코드로 허용
- 완전히 동일한 상품은 중복 방지

**모델 변경**: `backend/app/models/product.py`
- `__table_args__`에 `UniqueConstraint('brand_name', 'product_name', 'size_label')` 추가

#### 3. product_ingredient_profiles 테이블 - 버전 관리
```sql
ALTER TABLE product_ingredient_profiles 
ADD COLUMN version INTEGER DEFAULT 1;
```

**목적**: 포뮬러 변경 추적을 위한 버전 관리
- 제조사가 포뮬러를 변경할 때 버전을 증가시켜 추적 가능

**모델 변경**: `backend/app/models/product.py`
- `version: Column(Integer, nullable=False, server_default='1')`

#### 4. product_nutrition_facts 테이블 - 버전 관리
```sql
ALTER TABLE product_nutrition_facts 
ADD COLUMN version INTEGER DEFAULT 1;
```

**목적**: 영양 정보 변경 추적을 위한 버전 관리
- 영양 성분이 변경될 때 버전을 증가시켜 추적 가능

**모델 변경**: `backend/app/models/product.py`
- `version: Column(Integer, nullable=False, server_default='1')`

#### 5. price_snapshots 테이블 - 출처 기록
```sql
ALTER TABLE price_snapshots 
ADD COLUMN captured_source VARCHAR(50) DEFAULT 'COUPANG_API';
```

**목적**: 가격 스냅샷의 출처 기록 (쿠팡 외 플랫폼 대비)
- 나중에 네이버, 11번가 등 다른 플랫폼 추가 시 출처 구분 가능

**모델 변경**: `backend/app/models/price.py`
- `captured_source: Column(String(50), nullable=False, server_default='COUPANG_API')`

---

### 📅 중기 적용 (1~3개월 후) - 마이그레이션: `2d390ff1ada4`

이 변경사항들은 모델에는 추가되었지만, 마이그레이션은 나중에 적용할 수 있도록 준비되어 있습니다.

#### 6. outbound_clicks 테이블 - 어필리에이트 수익 분석
```sql
ALTER TABLE outbound_clicks
ADD COLUMN estimated_commission NUMERIC(10,2),
ADD COLUMN actual_commission NUMERIC(10,2);
```

**목적**: 어필리에이트 수익 분석을 위한 예상/실제 커미션 추적
- `estimated_commission`: 예상 커미션
- `actual_commission`: 실제 지급된 커미션

**모델 변경**: `backend/app/models/outbound_click.py`
- 이미 추가됨 (nullable=True)

#### 7. trackings 테이블 - 가격 추적 주기 관리
```sql
ALTER TABLE trackings
ADD COLUMN last_checked_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN next_check_at TIMESTAMP WITH TIME ZONE;
```

**목적**: 가격 추적 주기 관리 및 최적화
- `last_checked_at`: 마지막 가격 확인 시간
- `next_check_at`: 다음 가격 확인 예정 시간

**모델 변경**: `backend/app/models/tracking.py`
- 이미 추가됨 (nullable=True)

#### 8. alerts 테이블 - 알림 중복 발송 방지
```sql
ALTER TABLE alerts 
ADD COLUMN last_sent_price INTEGER;
```

**목적**: 알림 중복 발송 방지
- 같은 가격으로 알림이 여러 번 발송되는 것을 방지

**모델 변경**: `backend/app/models/alert.py`
- 이미 추가됨 (nullable=True)

#### 9. recommendation_items 테이블 - 추천 점수 세부 분해
```sql
ALTER TABLE recommendation_items 
ADD COLUMN score_components JSONB;
```

**목적**: 추천 이유 디버깅 및 설명용 세부 점수 분해
- 각 점수 요소를 JSONB로 저장하여 추천 알고리즘 개선에 활용

**모델 변경**: `backend/app/models/recommendation.py`
- 이미 추가됨 (nullable=True)

---

## 마이그레이션 적용 방법

### 즉시 적용 (MVP용)

```bash
cd backend
.venv\Scripts\activate
alembic upgrade head
```

이 명령어는 다음 마이그레이션을 적용합니다:
- `8464df52ccf5_add_mvp_schema_improvements` (즉시 적용)

### 중기 적용 (1~3개월 후)

나중에 적용할 때는:

```bash
cd backend
.venv\Scripts\activate
alembic upgrade head
```

이 명령어는 다음 마이그레이션도 함께 적용합니다:
- `2d390ff1ada4_add_mid_term_schema_improvements` (중기 적용)

### 마이그레이션 되돌리기

```bash
# 한 단계 되돌리기
alembic downgrade -1

# 특정 버전으로 되돌리기
alembic downgrade <revision_id>
```

---

## 변경사항 요약

### 즉시 적용 (5개 변경사항)
1. ✅ `product_offers.vendor_item_id` (BIGINT, UNIQUE)
2. ✅ `product_offers.normalized_key` (VARCHAR(255))
3. ✅ `products` UNIQUE 제약 (brand_name, product_name, size_label)
4. ✅ `product_ingredient_profiles.version` (INTEGER, DEFAULT 1)
5. ✅ `product_nutrition_facts.version` (INTEGER, DEFAULT 1)
6. ✅ `price_snapshots.captured_source` (VARCHAR(50), DEFAULT 'COUPANG_API')

### 중기 적용 (4개 변경사항) - 모델만 추가, 마이그레이션은 나중에
7. ⏳ `outbound_clicks.estimated_commission` (NUMERIC(10,2))
8. ⏳ `outbound_clicks.actual_commission` (NUMERIC(10,2))
9. ⏳ `trackings.last_checked_at` (TIMESTAMP)
10. ⏳ `trackings.next_check_at` (TIMESTAMP)
11. ⏳ `alerts.last_sent_price` (INTEGER)
12. ⏳ `recommendation_items.score_components` (JSONB)

---

## 주의사항

1. **즉시 적용 마이그레이션**: MVP 론칭 전에 반드시 적용해야 합니다.
2. **중기 적용 마이그레이션**: 운영 중 필요에 따라 적용하세요. 모델은 이미 준비되어 있으므로 코드에서 사용 가능합니다.
3. **데이터 마이그레이션**: 기존 데이터가 있는 경우, 새로 추가된 컬럼의 기본값이 적용됩니다.
4. **Unique 제약**: `products` 테이블의 unique 제약은 기존 중복 데이터가 있으면 마이그레이션이 실패할 수 있습니다. 먼저 중복 데이터를 정리하세요.
