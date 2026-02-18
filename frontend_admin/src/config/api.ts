/**
 * API 설정 및 기본 URL
 */

// 환경 변수에서 API Base URL 가져오기 (없으면 기본값 사용)
export const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000';

// API 엔드포인트 경로
export const API_PATHS = {
  // 상품 관리
  PRODUCTS: '/api/v1/admin/products',
  PRODUCT: (id: string) => `/api/v1/admin/products/${id}`,
  PRODUCT_ARCHIVE: (id: string) => `/api/v1/admin/products/${id}/archive`,
  PRODUCT_UNARCHIVE: (id: string) => `/api/v1/admin/products/${id}/unarchive`,
  PRODUCT_IMAGES: (id: string) => `/api/v1/admin/products/${id}/images`,
  
  // 성분 정보
  PRODUCT_INGREDIENT: (id: string) => `/api/v1/admin/products/${id}/ingredient`,
  PRODUCT_INGREDIENT_ANALYZE: (id: string) => `/api/v1/admin/products/${id}/ingredient/analyze-and-save`,
  PRODUCT_INGREDIENT_PARSED: (id: string) => `/api/v1/admin/products/${id}/ingredient/parsed`,
  ANALYZE_INGREDIENTS: '/api/v1/admin/analyze-ingredients',
  
  // 영양 정보
  PRODUCT_NUTRITION: (id: string) => `/api/v1/admin/products/${id}/nutrition`,
  
  // 알레르겐
  ALLERGEN_CODES: '/api/v1/admin/allergen-codes',
  PRODUCT_ALLERGENS: (id: string) => `/api/v1/admin/products/${id}/allergens`,
  PRODUCT_ALLERGEN: (id: string, code: string) => `/api/v1/admin/products/${id}/allergens/${code}`,
  
  // 기능성 클레임
  CLAIM_CODES: '/api/v1/admin/claim-codes',
  PRODUCT_CLAIMS: (id: string) => `/api/v1/admin/products/${id}/claims`,
  PRODUCT_CLAIM: (id: string, code: string) => `/api/v1/admin/products/${id}/claims/${code}`,
  
  // 판매처
  PRODUCT_OFFERS: (id: string) => `/api/v1/admin/products/${id}/offers`,
  OFFER: (id: string) => `/api/v1/admin/offers/${id}`,
  
  // 이벤트 관리
  CAMPAIGNS: '/api/v1/admin/campaigns',
  CAMPAIGN: (id: string) => `/api/v1/admin/campaigns/${id}`,
  CAMPAIGN_TOGGLE: (id: string) => `/api/v1/admin/campaigns/${id}/toggle`,
  CAMPAIGN_SIMULATE: '/api/v1/admin/campaigns/simulate',
  REWARDS: '/api/v1/admin/rewards',
  IMPRESSIONS: '/api/v1/admin/impressions',
} as const;

/**
 * API 요청 헤더
 */
export function getHeaders(): HeadersInit {
  return {
    'Content-Type': 'application/json',
    // 필요시 인증 토큰 추가
    // 'Authorization': `Bearer ${getAuthToken()}`,
  };
}

/**
 * API 응답 타입
 */
export interface ApiResponse<T> {
  data?: T;
  error?: string;
  message?: string;
}

/**
 * API 에러 처리
 */
export class ApiError extends Error {
  constructor(
    public status: number,
    public statusText: string,
    public data?: any
  ) {
    super(`API Error: ${status} ${statusText}`);
    this.name = 'ApiError';
  }
}

/**
 * 기본 fetch 래퍼
 */
export async function apiRequest<T>(
  url: string,
  options: RequestInit = {}
): Promise<T> {
  const fullUrl = url.startsWith('http') ? url : `${API_BASE_URL}${url}`;
  
  try {
    const response = await fetch(fullUrl, {
      ...options,
      headers: {
        ...getHeaders(),
        ...options.headers,
      },
    });

    if (!response.ok) {
      let errorData;
      try {
        errorData = await response.json();
      } catch {
        errorData = await response.text();
      }
      throw new ApiError(response.status, response.statusText, errorData);
    }

    // 응답이 비어있는 경우 (204 No Content 등)
    if (response.status === 204 || response.headers.get('content-length') === '0') {
      return {} as T;
    }

    return await response.json();
  } catch (error) {
    if (error instanceof ApiError) {
      throw error;
    }
    throw new Error(`Network error: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }
}
