# 미국 시장 확장 마이그레이션 가이드

> **주의**: 이 마이그레이션은 기존 한국 시장 데이터에 영향을 줄 수 있습니다. 프로덕션 환경에서는 반드시 백업 후 진행하세요.

## 마이그레이션 개요

미국 시장 확장을 위한 데이터베이스 스키마 변경사항을 적용합니다.

## 주요 변경사항

### 1. users 테이블
- `timezone` 기본값: `'Asia/Seoul'` → `'America/New_York'`
- **주의**: 기존 사용자는 기본값이 변경되어도 기존 값은 유지됩니다.

### 2. pets 테이블
- `weight_kg` → `weight_numeric` + `weight_unit` 분리
- `species` ENUM 확장: `'DOG', 'CAT'` → `'DOG', 'CAT', 'BIRD', 'SMALL_MAMMAL', 'REPTILE', 'FISH'`
- **데이터 변환 필요**: 기존 `weight_kg` 값을 `weight_numeric`으로 복사하고 `weight_unit`을 `'KG'`로 설정

### 3. products 테이블
- `size_label` → `size_value` + `size_unit` + `size_label` (표시용)
- `species` ENUM 확장 (동일)
- Unique constraint 변경: `(brand_name, product_name, size_label)` → `(brand_name, product_name, size_value, size_unit)`
- **데이터 변환 필요**: 기존 `size_label`에서 숫자와 단위를 파싱하여 `size_value`와 `size_unit`로 분리

### 4. 코드 테이블
- `health_concern_codes`: `display_name_en` 컬럼 추가
- `allergen_codes`: `display_name_en` 컬럼 추가
- `claim_codes`: `display_name_en` + `substantiation_required` 컬럼 추가
- **데이터 입력 필요**: 기존 코드에 대한 영어 표시명 추가

### 5. product_offers 테이블
- `merchant` ENUM 확장: `'COUPANG', 'NAVER', 'BRAND'` → US 판매처 추가
- **주의**: 기존 데이터는 영향 없음

### 6. product_ingredient_profiles 테이블
- `order_by_weight` JSONB 컬럼 추가 (AAFCO 준수)

### 7. product_nutrition_facts 테이블
- AAFCO 필드 추가:
  - `total_dietary_fiber_pct`
  - `kcal_per_cup`
  - `serving_size_cup`
  - `aafco_nutritional_adequacy`
  - `life_stage` ENUM

### 8. product_claims 테이블
- `substantiation_note` 컬럼 추가

### 9. price_snapshots 테이블
- `currency` 기본값: `'KRW'` → `'USD'`
- `captured_source` 기본값: `'COUPANG_API'` → `'AMAZON_API'`
- **주의**: 기존 데이터는 영향 없음

### 10. 신규 테이블
- `product_reviews`: 상품 리뷰 통합
- `product_availability`: 재고·지역 제한

## 마이그레이션 실행 순서

### 1단계: 백업
```bash
# 프로덕션 데이터베이스 백업
pg_dump -h localhost -U postgres -d pet_food_app > backup_$(date +%Y%m%d_%H%M%S).sql
```

### 2단계: 마이그레이션 생성
```bash
cd backend
alembic revision --autogenerate -m "us_market_expansion"
```

### 3단계: 마이그레이션 파일 수정
생성된 마이그레이션 파일에서 다음을 확인/수정:

1. **pets 테이블 데이터 변환**:
   ```python
   # weight_kg → weight_numeric + weight_unit 변환
   op.execute("""
       UPDATE pets 
       SET weight_numeric = weight_kg, 
           weight_unit = 'KG'
       WHERE weight_numeric IS NULL;
   """)
   ```

2. **products 테이블 데이터 변환**:
   ```python
   # size_label 파싱 (예: "3kg" → size_value=3, size_unit='KG')
   # 이 부분은 복잡하므로 별도 스크립트로 처리하는 것을 권장
   ```

3. **코드 테이블 영어 표시명 추가**:
   ```python
   # 기존 코드에 대한 영어 표시명 입력
   # seed_code_tables.py 스크립트 수정 필요
   ```

### 4단계: 마이그레이션 적용
```bash
# 마이그레이션 미리보기 (dry-run)
alembic upgrade head --sql

# 마이그레이션 적용
alembic upgrade head
```

### 5단계: 데이터 검증
```sql
-- pets 테이블 확인
SELECT COUNT(*) FROM pets WHERE weight_numeric IS NULL;
SELECT COUNT(*) FROM pets WHERE weight_unit IS NULL;

-- products 테이블 확인
SELECT COUNT(*) FROM products WHERE size_value IS NULL AND size_label IS NOT NULL;

-- 코드 테이블 확인
SELECT COUNT(*) FROM health_concern_codes WHERE display_name_en IS NULL;
SELECT COUNT(*) FROM allergen_codes WHERE display_name_en IS NULL;
SELECT COUNT(*) FROM claim_codes WHERE display_name_en IS NULL;
```

## 데이터 변환 스크립트

### pets.weight_kg → weight_numeric + weight_unit
```python
# scripts/migrate_pet_weight.py
from app.db.session import SessionLocal
from app.models.pet import Pet, WeightUnit

db = SessionLocal()
pets = db.query(Pet).all()

for pet in pets:
    if hasattr(pet, 'weight_kg') and pet.weight_kg:
        pet.weight_numeric = pet.weight_kg
        pet.weight_unit = WeightUnit.KG

db.commit()
```

### products.size_label 파싱
```python
# scripts/migrate_product_size.py
import re
from app.db.session import SessionLocal
from app.models.product import Product, SizeUnit

db = SessionLocal()
products = db.query(Product).filter(Product.size_label.isnot(None)).all()

for product in products:
    if product.size_label:
        # "3kg", "5 lb", "10oz" 등 파싱
        match = re.match(r'(\d+\.?\d*)\s*(kg|lb|oz|g)', product.size_label.lower())
        if match:
            value, unit = match.groups()
            product.size_value = float(value)
            unit_map = {'kg': SizeUnit.KG, 'lb': SizeUnit.LB, 'oz': SizeUnit.OZ, 'g': SizeUnit.G}
            product.size_unit = unit_map.get(unit, SizeUnit.KG)

db.commit()
```

## 롤백 계획

마이그레이션 실패 시 롤백:

```bash
# 마이그레이션 되돌리기
alembic downgrade -1

# 또는 특정 버전으로
alembic downgrade <revision_id>
```

## 주의사항

1. **기존 데이터 보존**: `weight_kg`와 `size_label` 컬럼은 마이그레이션 후에도 일시적으로 유지하는 것을 권장 (데이터 검증 후 삭제)

2. **ENUM 확장**: PostgreSQL ENUM 타입은 ALTER TYPE으로 확장 가능하지만, 기존 값과 충돌하지 않도록 주의

3. **Unique Constraint 변경**: `products` 테이블의 unique constraint 변경 시 기존 중복 데이터 확인 필요

4. **기본값 변경**: `users.timezone`, `price_snapshots.currency` 등 기본값 변경은 새로 생성되는 레코드에만 적용됨

## 검증 체크리스트

- [ ] 모든 기존 pets 레코드에 `weight_numeric`과 `weight_unit` 값이 있는가?
- [ ] 모든 기존 products 레코드에 `size_value`와 `size_unit` 값이 있는가? (또는 NULL 허용)
- [ ] 모든 코드 테이블에 `display_name_en` 값이 있는가?
- [ ] 신규 테이블 (`product_reviews`, `product_availability`)이 정상 생성되었는가?
- [ ] 모든 인덱스가 정상 생성되었는가?
- [ ] 애플리케이션이 정상 작동하는가?
