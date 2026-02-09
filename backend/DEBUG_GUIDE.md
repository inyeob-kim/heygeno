# 백엔드 디버깅 가이드

## 500 에러 해결

### 1. 백엔드 서버 재시작 및 로그 확인

```bash
cd backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

서버를 실행하면 콘솔에 에러 메시지와 스택 트레이스가 표시됩니다.

### 2. 로깅 활성화

`backend/app/main.py`에 로깅 설정 추가:

```python
import logging

logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
```

### 3. 데이터베이스 연결 확인

```bash
# PostgreSQL이 실행 중인지 확인
docker-compose ps

# 데이터베이스 연결 테스트
python -c "from app.db.session import engine; import asyncio; asyncio.run(engine.connect())"
```

### 4. 마이그레이션 확인

```bash
cd backend
alembic current  # 현재 버전 확인
alembic upgrade head  # 최신 마이그레이션 적용
```

### 5. API 직접 테스트

```bash
# Health Check
curl http://localhost:8000/health

# 상품 목록 조회 (에러 발생 시 상세 메시지 확인)
curl -v http://localhost:8000/api/v1/admin/products
```

### 6. 일반적인 에러 원인

1. **데이터베이스 연결 실패**
   - `.env` 파일의 `DATABASE_URL` 확인
   - PostgreSQL이 실행 중인지 확인

2. **마이그레이션 미적용**
   - `alembic upgrade head` 실행

3. **관계 로딩 문제**
   - `selectinload`가 제대로 작동하는지 확인
   - 관계 이름이 올바른지 확인

4. **필드 접근 문제**
   - 존재하지 않는 필드에 접근 시도
   - `getattr`를 사용하여 안전하게 접근

### 7. 에러 로그 예시

백엔드 콘솔에서 다음과 같은 에러를 확인할 수 있습니다:

```
ERROR: Error in get_all_products: ...
Traceback (most recent call last):
  ...
```

이 로그를 확인하여 정확한 원인을 파악하세요.
