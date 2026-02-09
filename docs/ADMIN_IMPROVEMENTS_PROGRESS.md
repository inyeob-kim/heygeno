# 관리자 페이지 개선 작업 진행 상황

> **작업 시작**: 2026-02-09
> **상태**: 진행 중

## 완료된 작업

### 백엔드
1. ✅ **스키마 확장** (`backend/app/schemas/admin.py`)
   - `ProductListRead`: computed 필드 포함 (offers_count, ingredient_exists, nutrition_exists, has_image)
   - `ProductListResponse`: 페이지네이션 응답
   - `ProductImagesUpdate`: 이미지 업데이트 스키마
   - `OfferRead/Create/Update`: 판매처 CRUD 스키마
   - `ImportLogRead/ImportLogRowRead`: 대량 업로드 로그 스키마

2. ✅ **ProductService 확장** (`backend/app/services/product_service.py`)
   - `get_products_with_filters()`: 필터링/정렬/페이지네이션 메서드 추가
   - 필터: query, species, active, completion_status, has_image, has_offers
   - 정렬: UPDATED_DESC, BRAND_ASC, INCOMPLETE_FIRST
   - 페이지네이션: page, size

## 진행 중인 작업

### 백엔드
1. 🔄 **AdminService 확장**
   - Offers CRUD 메서드 추가 필요
   - Images 업데이트 메서드 추가 필요
   - Imports 처리 메서드 추가 필요

2. 🔄 **API 엔드포인트 추가** (`backend/app/api/v1/admin.py`)
   - GET /products (필터링/정렬/페이지네이션)
   - PATCH /products/{id}/images
   - GET/POST/PUT/DELETE /products/{id}/offers
   - POST /products/{id}/archive
   - POST /products/{id}/unarchive
   - POST /imports/{type}
   - GET /imports
   - GET /imports/{id}/rows

### 프론트엔드
1. ⏳ **구조 리팩토링** (`frontend_admin/index.html`)
   - 전역 상태 객체 도입
   - 함수 분리 (api.*, render.*, handlers.*, utils.*)
   - Dirty state 관리

2. ⏳ **좌측 목록 업그레이드**
   - 필터 바 추가
   - 배지 표시 (이미지X, 오퍼0, 성분X, 영양X)
   - 완성도 상태 표시

3. ⏳ **우측 탭 재구성**
   - BASIC, IMAGES, OFFERS, INGREDIENTS, NUTRITION, ALLERGENS, CLAIMS, LOGS

4. ⏳ **각 탭 구현**
   - BASIC: admin_memo, completion_status 표시, Archive/Unarchive
   - IMAGES: URL 입력 및 미리보기
   - OFFERS: 행 편집 테이블
   - INGREDIENTS/NUTRITION: 버전 표시
   - ALLERGENS/CLAIMS: 인라인 편집
   - CSV 업로드 기능

## 다음 단계

1. AdminService에 offers/images 메서드 추가
2. API 엔드포인트 구현
3. 프론트엔드 구조 리팩토링
4. 좌측 목록 필터/검색 구현
5. 각 탭 기능 구현

## 참고사항

- 마이그레이션 (`4e2cb404e17a_add_admin_and_marketplace_hardening.py`)이 아직 적용되지 않았을 수 있습니다.
- 새로운 컬럼(primary_image_url, completion_status 등)을 사용하는 코드는 마이그레이션 적용 후 정상 작동합니다.
- 단계별로 테스트하며 진행하는 것을 권장합니다.
