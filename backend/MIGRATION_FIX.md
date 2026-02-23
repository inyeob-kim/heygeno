# 데이터베이스 마이그레이션 수정 완료

## 문제
- 모델은 `weight_numeric`과 `weight_unit` 컬럼을 사용
- 실제 데이터베이스에는 `weight_kg` 컬럼만 존재
- 마이그레이션이 실행되지 않아 불일치 발생

## 수정 내용
`backend/alembic/versions/8ae72374b022_us_market_expansion.py` 파일을 수정하여:

1. **upgrade() 함수**: 
   - `weight_numeric`과 `weight_unit` 컬럼을 nullable로 먼저 추가
   - 기존 `weight_kg` 값을 `weight_numeric`으로 변환 (kg → lb: `weight_kg * 2.20462`)
   - `weight_unit`을 'LB'로 설정
   - 컬럼을 NOT NULL로 변경
   - `weight_kg` 컬럼 삭제

2. **downgrade() 함수**:
   - `weight_kg` 컬럼을 nullable로 먼저 추가
   - `weight_numeric` 값을 `weight_kg`로 변환 (lb → kg: `weight_numeric / 2.20462`)
   - 컬럼을 NOT NULL로 변경
   - `weight_numeric`과 `weight_unit` 컬럼 삭제

## 실행 방법

```bash
cd backend
alembic upgrade head
```

## 주의사항
- 마이그레이션 실행 전 데이터베이스 백업 권장
- 기존 `weight_kg` 값이 모두 `weight_numeric` (lb 단위)로 변환됩니다
- 마이그레이션 실행 후 서버를 재시작하세요
