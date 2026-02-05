# 관리자 대시보드

상품 및 성분 정보를 관리할 수 있는 웹 대시보드입니다.

## 사용 방법

1. 백엔드 서버가 실행 중인지 확인하세요 (기본: `http://localhost:8000`)
2. `index.html` 파일을 브라우저에서 열거나, 간단한 웹 서버로 실행하세요:

```bash
# Python 3
python -m http.server 8080

# 또는 Node.js (http-server 설치 필요)
npx http-server -p 8080
```

3. 브라우저에서 `http://localhost:8080/index.html` 접속

## 기능

### 현재 구현된 기능
- ✅ 상품 목록 조회 (활성/비활성 포함 옵션)
- ✅ 상품 생성
- ✅ 상품 수정
- ✅ 상품 삭제 (소프트 삭제)
- ✅ 상품 상세 정보 보기

### 향후 구현 예정
- ⏳ 성분 정보 (ProductIngredientProfile) 관리
- ⏳ 영양 정보 (ProductNutritionFacts) 관리
- ⏳ 알레르겐 (ProductAllergen) 관리
- ⏳ 기능성 클레임 (ProductClaim) 관리

## API 엔드포인트

현재 사용 중인 API:
- `GET /api/v1/admin/products` - 상품 목록 조회
- `GET /api/v1/admin/products/{product_id}` - 상품 상세 조회
- `POST /api/v1/admin/products` - 상품 생성
- `PUT /api/v1/admin/products/{product_id}` - 상품 수정
- `DELETE /api/v1/admin/products/{product_id}` - 상품 삭제

## 설정

`index.html` 파일의 `API_BASE` 변수를 수정하여 백엔드 API 주소를 변경할 수 있습니다:

```javascript
const API_BASE = 'http://localhost:8000/api/v1';
```

## 주의사항

- CORS 설정이 필요할 수 있습니다. 백엔드의 `main.py`에서 CORS 미들웨어가 활성화되어 있는지 확인하세요.
- 성분 정보, 영양 정보, 알레르겐, 클레임 관리 기능은 백엔드 API가 추가로 구현되어야 합니다.
