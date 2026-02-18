import { apiRequest, API_PATHS, ApiError } from '../config/api';
import { Product } from '../data/mockProducts';

/**
 * 상품 목록 조회 파라미터
 */
export interface GetProductsParams {
  query?: string;
  species?: 'DOG' | 'CAT' | 'ALL';
  active?: 'ACTIVE' | 'ARCHIVED' | 'ALL';
  completion?: 'COMPLETE' | 'MISSING_INGREDIENTS' | 'MISSING_NUTRITION' | 'MISSING_OFFERS' | 'ALL';
  hasImage?: 'YES' | 'NO' | 'ALL';
  hasOffers?: 'YES' | 'NO' | 'ALL';
  sort?: 'UPDATED_DESC' | 'BRAND_ASC' | 'INCOMPLETE_FIRST';
  page?: number;
  size?: number;
  includeInactive?: boolean;
}

/**
 * 상품 생성 데이터
 */
export interface CreateProductData {
  brandName: string;
  productName: string;
  sizeLabel?: string;
  category?: string;
  species?: 'DOG' | 'CAT';
  isActive?: boolean;
  adminMemo?: string;
}

/**
 * 상품 수정 데이터
 */
export interface UpdateProductData extends Partial<CreateProductData> {
  id: string;
}

/**
 * 상품 서비스
 */
export const productService = {
  /**
   * 상품 목록 조회
   */
  async getProducts(params: GetProductsParams = {}): Promise<{ products: Product[]; total: number; page: number; size: number }> {
    const queryParams = new URLSearchParams();
    
    if (params.query) queryParams.append('query', params.query);
    if (params.species && params.species !== 'ALL') queryParams.append('species', params.species);
    if (params.active && params.active !== 'ALL') queryParams.append('active', params.active);
    if (params.completion && params.completion !== 'ALL') queryParams.append('completion', params.completion);
    if (params.hasImage && params.hasImage !== 'ALL') queryParams.append('has_image', params.hasImage === 'YES' ? 'true' : 'false');
    if (params.hasOffers && params.hasOffers !== 'ALL') queryParams.append('has_offers', params.hasOffers === 'YES' ? 'true' : 'false');
    if (params.sort) queryParams.append('sort', params.sort);
    if (params.page) queryParams.append('page', params.page.toString());
    if (params.size) queryParams.append('size', params.size.toString());
    if (params.includeInactive) queryParams.append('include_inactive', 'true');

    const queryString = queryParams.toString();
    const url = queryString ? `${API_PATHS.PRODUCTS}?${queryString}` : API_PATHS.PRODUCTS;
    
    const response = await apiRequest<{ items: any[]; total: number; page: number; size: number }>(url);
    
    // 백엔드 응답(snake_case)을 프론트엔드 형식(camelCase)으로 변환
    const products: Product[] = response.items.map((item: any) => ({
      id: item.id,
      name: item.product_name,
      brand: item.brand_name,
      species: item.species || 'DOG',
      status: item.is_active ? 'ACTIVE' : 'ARCHIVED',
      sizeLabel: item.size_label || undefined,
      category: item.category || undefined,
      thumbnail: item.thumbnail_url || item.primary_image_url || 'https://images.unsplash.com/photo-1589924691995-400dc9ecc119?w=200&h=200&fit=crop',
      createdAt: item.created_at || new Date().toISOString(),
      updatedAt: item.updated_at || new Date().toISOString(),
      offerSource: 'COUPANG', // 기본값
      ingredients: [],
      nutrition: {},
      allergens: [],
      claims: [],
      offers: [],
      images: item.primary_image_url ? [item.primary_image_url] : [],
    }));
    
    return {
      products,
      total: response.total,
      page: response.page,
      size: response.size,
    };
  },

  /**
   * 상품 상세 조회
   */
  async getProduct(id: string): Promise<Product> {
    const data = await apiRequest<any>(API_PATHS.PRODUCT(id));
    // 백엔드 응답(snake_case)을 프론트엔드 형식(camelCase)으로 변환
    return {
      id: data.id,
      name: data.product_name || data.name,
      brand: data.brand_name || data.brand,
      species: data.species || 'DOG',
      status: data.is_active ? 'ACTIVE' : 'ARCHIVED',
      sizeLabel: data.size_label || undefined,
      category: data.category || undefined,
      thumbnail: data.thumbnail_url || data.primary_image_url || 'https://images.unsplash.com/photo-1589924691995-400dc9ecc119?w=200&h=200&fit=crop',
      createdAt: data.created_at || new Date().toISOString(),
      updatedAt: data.updated_at || new Date().toISOString(),
      offerSource: 'COUPANG',
      ingredients: [],
      nutrition: {},
      allergens: [],
      claims: [],
      offers: [],
      images: data.primary_image_url ? [data.primary_image_url] : [],
    };
  },

  /**
   * 상품 생성
   */
  async createProduct(data: CreateProductData): Promise<Product> {
    // 백엔드가 기대하는 필드명으로 변환 (snake_case)
    const requestData = {
      brand_name: data.brandName,
      product_name: data.productName,
      size_label: data.sizeLabel,
      category: data.category || 'FOOD',
      species: data.species,
      is_active: data.isActive !== undefined ? data.isActive : true,
    };
    
    const response = await apiRequest<any>(API_PATHS.PRODUCTS, {
      method: 'POST',
      body: JSON.stringify(requestData),
    });
    
    // 백엔드 응답(snake_case)을 프론트엔드 형식(camelCase)으로 변환
    return {
      id: response.id,
      name: response.product_name || response.name,
      brand: response.brand_name || response.brand,
      species: response.species || 'DOG',
      status: response.is_active ? 'ACTIVE' : 'ARCHIVED',
      sizeLabel: response.size_label || undefined,
      category: response.category || undefined,
      thumbnail: response.thumbnail_url || response.primary_image_url || 'https://images.unsplash.com/photo-1589924691995-400dc9ecc119?w=200&h=200&fit=crop',
      createdAt: response.created_at || new Date().toISOString(),
      updatedAt: response.updated_at || new Date().toISOString(),
      offerSource: 'COUPANG',
      ingredients: [],
      nutrition: {},
      allergens: [],
      claims: [],
      offers: [],
      images: response.primary_image_url ? [response.primary_image_url] : [],
    };
  },

  /**
   * 상품 수정
   */
  async updateProduct(data: UpdateProductData): Promise<Product> {
    // 백엔드가 기대하는 필드명으로 변환 (snake_case)
    const requestData: any = {};
    if (data.brandName !== undefined) requestData.brand_name = data.brandName;
    if (data.productName !== undefined) requestData.product_name = data.productName;
    if (data.sizeLabel !== undefined) requestData.size_label = data.sizeLabel;
    if (data.category !== undefined) requestData.category = data.category;
    if (data.species !== undefined) requestData.species = data.species;
    if (data.isActive !== undefined) requestData.is_active = data.isActive;
    
    const response = await apiRequest<any>(API_PATHS.PRODUCT(data.id), {
      method: 'PUT',
      body: JSON.stringify(requestData),
    });
    
    // 백엔드 응답(snake_case)을 프론트엔드 형식(camelCase)으로 변환
    return {
      id: response.id,
      name: response.product_name || response.name,
      brand: response.brand_name || response.brand,
      species: response.species || 'DOG',
      status: response.is_active ? 'ACTIVE' : 'ARCHIVED',
      sizeLabel: response.size_label || undefined,
      category: response.category || undefined,
      thumbnail: response.thumbnail_url || response.primary_image_url || 'https://images.unsplash.com/photo-1589924691995-400dc9ecc119?w=200&h=200&fit=crop',
      createdAt: response.created_at || new Date().toISOString(),
      updatedAt: response.updated_at || new Date().toISOString(),
      offerSource: 'COUPANG',
      ingredients: [],
      nutrition: {},
      allergens: [],
      claims: [],
      offers: [],
      images: response.primary_image_url ? [response.primary_image_url] : [],
    };
  },

  /**
   * 상품 비활성화 (소프트 삭제)
   */
  async archiveProduct(id: string): Promise<void> {
    return apiRequest(API_PATHS.PRODUCT_ARCHIVE(id), {
      method: 'POST',
    });
  },

  /**
   * 상품 활성화
   */
  async unarchiveProduct(id: string): Promise<void> {
    return apiRequest(API_PATHS.PRODUCT_UNARCHIVE(id), {
      method: 'POST',
    });
  },

  /**
   * 성분 정보 조회
   */
  async getIngredient(productId: string): Promise<any> {
    return apiRequest(API_PATHS.PRODUCT_INGREDIENT(productId));
  },

  /**
   * 성분 정보 수정
   */
  async updateIngredient(productId: string, data: any): Promise<any> {
    return apiRequest(API_PATHS.PRODUCT_INGREDIENT(productId), {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  },

  /**
   * 성분 분석 및 저장 (기존 - 하위 호환성 유지)
   */
  async analyzeAndSaveIngredient(productId: string): Promise<any> {
    return apiRequest(API_PATHS.PRODUCT_INGREDIENT_ANALYZE(productId), {
      method: 'POST',
    });
  },

  /**
   * 성분 분석만 수행 (저장하지 않음)
   */
  async analyzeIngredients(data: { ingredients_text: string; additives_text?: string; species?: string }): Promise<{ parsed: any }> {
    return apiRequest(API_PATHS.ANALYZE_INGREDIENTS, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  },

  /**
   * 분석된 parsed 데이터 저장
   */
  async saveParsed(productId: string, parsed: any): Promise<any> {
    return apiRequest(API_PATHS.PRODUCT_INGREDIENT_PARSED(productId), {
      method: 'PUT',
      body: JSON.stringify({ parsed }),
    });
  },

  /**
   * 영양 정보 조회
   */
  async getNutrition(productId: string): Promise<any> {
    return apiRequest(API_PATHS.PRODUCT_NUTRITION(productId));
  },

  /**
   * 영양 정보 수정
   */
  async updateNutrition(productId: string, data: any): Promise<any> {
    return apiRequest(API_PATHS.PRODUCT_NUTRITION(productId), {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  },

  /**
   * 알레르겐 코드 목록 조회
   */
  async getAllergenCodes(): Promise<any[]> {
    return apiRequest(API_PATHS.ALLERGEN_CODES);
  },

  /**
   * 상품 알레르겐 조회
   */
  async getProductAllergens(productId: string): Promise<any[]> {
    return apiRequest(API_PATHS.PRODUCT_ALLERGENS(productId));
  },

  /**
   * 알레르겐 추가
   */
  async addAllergen(productId: string, allergenCode: string): Promise<any> {
    return apiRequest(API_PATHS.PRODUCT_ALLERGENS(productId), {
      method: 'POST',
      body: JSON.stringify({ allergen_code: allergenCode }),
    });
  },

  /**
   * 알레르겐 삭제
   */
  async deleteAllergen(productId: string, allergenCode: string): Promise<void> {
    return apiRequest(API_PATHS.PRODUCT_ALLERGEN(productId, allergenCode), {
      method: 'DELETE',
    });
  },

  /**
   * 클레임 코드 목록 조회
   */
  async getClaimCodes(): Promise<any[]> {
    return apiRequest(API_PATHS.CLAIM_CODES);
  },

  /**
   * 상품 클레임 조회
   */
  async getProductClaims(productId: string): Promise<any[]> {
    return apiRequest(API_PATHS.PRODUCT_CLAIMS(productId));
  },

  /**
   * 클레임 추가
   */
  async addClaim(productId: string, claimCode: string): Promise<any> {
    return apiRequest(API_PATHS.PRODUCT_CLAIMS(productId), {
      method: 'POST',
      body: JSON.stringify({ claim_code: claimCode }),
    });
  },

  /**
   * 클레임 삭제
   */
  async deleteClaim(productId: string, claimCode: string): Promise<void> {
    return apiRequest(API_PATHS.PRODUCT_CLAIM(productId, claimCode), {
      method: 'DELETE',
    });
  },

  /**
   * 판매처 목록 조회
   */
  async getOffers(productId: string): Promise<any[]> {
    return apiRequest(API_PATHS.PRODUCT_OFFERS(productId));
  },

  /**
   * 판매처 추가
   */
  async addOffer(productId: string, data: any): Promise<any> {
    const requestData = buildOfferRequestData(data);
    return apiRequest(API_PATHS.PRODUCT_OFFERS(productId), {
      method: 'POST',
      body: JSON.stringify(requestData),
    });
  },

  /**
   * 판매처 수정
   */
  async updateOffer(offerId: string, data: any): Promise<any> {
    const requestData = buildOfferRequestData(data);
    return apiRequest(API_PATHS.OFFER(offerId), {
      method: 'PUT',
      body: JSON.stringify(requestData),
    });
  },

  /**
   * 판매처 삭제
   */
  async deleteOffer(offerId: string): Promise<void> {
    return apiRequest(API_PATHS.OFFER(offerId), {
      method: 'DELETE',
    });
  },

  /**
   * 이미지 목록 조회
   */
  async getImages(productId: string): Promise<string[]> {
    return apiRequest(API_PATHS.PRODUCT_IMAGES(productId));
  },
};

function buildOfferRequestData(data: any) {
  // 백엔드가 기대하는 필드명으로 변환
  // 프론트엔드: { platform: "쿠팡", url: "...", price: 1000 }
  // 백엔드: { merchant: "COUPANG", merchant_product_id: "...", url: "...", current_price: 1000, ... }
  const platformToMerchant: Record<string, string> = {
    '쿠팡': 'COUPANG',
    '네이버쇼핑': 'NAVER',
    '11번가': 'NAVER',
    'G마켓': 'NAVER',
    '옥션': 'NAVER',
    '기타': 'BRAND',
  };

  const merchant = platformToMerchant[data.platform] || data.merchant || 'BRAND';

  // URL에서 merchant_product_id 추출 시도
  let merchantProductId = data.merchant_product_id || '';
  if (!merchantProductId && data.url) {
    try {
      const urlObj = new URL(data.url);
      if (merchant === 'COUPANG' && urlObj.pathname) {
        // 쿠팡 URL 형식: /products/12345678 또는 /dp/12345678
        const match = urlObj.pathname.match(/\/(?:products|dp)\/(\d+)/);
        if (match) {
          merchantProductId = match[1];
        } else {
          // 경로의 마지막 숫자 부분 추출
          const parts = urlObj.pathname.split('/').filter((p) => p);
          const lastPart = parts[parts.length - 1];
          merchantProductId = lastPart.match(/\d+/)?.[0] || lastPart || urlObj.href;
        }
      } else {
        // 다른 플랫폼의 경우 URL의 마지막 부분 사용
        const parts = urlObj.pathname.split('/').filter((p) => p);
        merchantProductId = parts[parts.length - 1] || urlObj.href;
      }
    } catch (e) {
      // URL 파싱 실패 시 전체 URL을 ID로 사용
      merchantProductId = data.url.substring(0, 255); // 최대 길이 제한
    }
  }

  // merchant_product_id가 비어있으면 fallback
  if (!merchantProductId || merchantProductId === 'unknown') {
    merchantProductId = data.url ? data.url.substring(0, 255) : `offer_${Date.now()}`;
  }

  return {
      merchant: merchant,
      merchant_product_id: merchantProductId,
      url: data.url,
      current_price: data.price || data.current_price || null,
      currency: 'KRW',
      is_active: true,
      is_primary: false,
      display_priority: 10,
  };
}
