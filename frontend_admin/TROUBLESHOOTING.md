# 문제 해결 가이드

## CORS 에러 해결

### 증상
```
Access to fetch at 'http://localhost:8000/...' from origin 'http://localhost:8001' 
has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present
```

### 해결 방법

1. **백엔드 서버가 실행 중인지 확인**
   ```bash
   # 백엔드 폴더에서
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

2. **백엔드 CORS 설정 확인**
   `backend/app/main.py` 파일에 다음 설정이 있어야 합니다:
   ```python
   app.add_middleware(
       CORSMiddleware,
       allow_origins=["*"],  # 개발용 - 모든 origin 허용
       allow_credentials=True,
       allow_methods=["*"],
       allow_headers=["*"],
   )
   ```

3. **백엔드 서버 재시작**
   - 서버를 중지하고 다시 시작
   - 변경사항이 적용되었는지 확인

4. **Health Check 확인**
   브라우저에서 직접 접속:
   ```
   http://localhost:8000/health
   ```
   응답: `{"status": "ok", "message": "Service is running"}`

## 500 Internal Server Error 해결

### 증상
```
GET http://localhost:8000/api/v1/admin/products?... net::ERR_FAILED 500 (Internal Server Error)
```

### 해결 방법

1. **백엔드 로그 확인**
   백엔드 서버 콘솔에서 에러 메시지 확인

2. **데이터베이스 연결 확인**
   ```bash
   # PostgreSQL이 실행 중인지 확인
   docker-compose ps
   # 또는
   docker ps | grep postgres
   ```

3. **데이터베이스 마이그레이션 확인**
   ```bash
   cd backend
   alembic current  # 현재 마이그레이션 버전 확인
   alembic upgrade head  # 최신 마이그레이션 적용
   ```

4. **환경 변수 확인**
   `.env` 파일에 `DATABASE_URL`이 올바르게 설정되어 있는지 확인

5. **백엔드 코드 확인**
   - `backend/app/services/product_service.py`의 `get_products_with_filters` 함수
   - 관계 로딩이 제대로 설정되어 있는지 확인:
     ```python
     base_query = select(Product).options(
         selectinload(Product.offers),
         selectinload(Product.ingredient_profile),
         selectinload(Product.nutrition_facts)
     )
     ```

## 숫자 입력 필드 경고 해결

### 증상
```
The specified value "${data?.protein_pct != null ? data.protein_pct : ''}" 
cannot be parsed, or is out of range.
```

### 해결 방법
✅ **이미 수정됨**: 모달 생성 후 JavaScript로 값을 설정하도록 변경했습니다.

## 일반적인 문제 해결 순서

1. **백엔드 서버 재시작**
   ```bash
   # Ctrl+C로 중지 후
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

2. **프론트엔드 서버 재시작**
   ```bash
   # Ctrl+C로 중지 후
   python -m http.server 8001
   ```

3. **브라우저 캐시 클리어**
   - 개발자 도구 (F12) → Network 탭 → "Disable cache" 체크
   - 또는 하드 리프레시 (Ctrl+Shift+R)

4. **백엔드 로그 확인**
   - 콘솔에서 에러 메시지 확인
   - 스택 트레이스 확인

5. **API 직접 테스트**
   ```bash
   # Health Check
   curl http://localhost:8000/health
   
   # 상품 목록 조회
   curl http://localhost:8000/api/v1/admin/products
   ```

## 디버깅 팁

### 브라우저 개발자 도구
1. **Network 탭**: 요청/응답 확인
2. **Console 탭**: JavaScript 에러 확인
3. **Application 탭**: 로컬 스토리지 확인

### 백엔드 디버깅
1. **로깅 활성화**
   ```python
   import logging
   logging.basicConfig(level=logging.DEBUG)
   ```

2. **에러 핸들러 추가**
   FastAPI의 예외 핸들러를 통해 상세한 에러 정보 확인

3. **데이터베이스 쿼리 확인**
   SQLAlchemy의 echo 옵션 활성화:
   ```python
   engine = create_async_engine(url, echo=True)
   ```
