import { apiRequest, API_PATHS, ApiError } from '../config/api';
import { Campaign, Reward, Impression } from '../data/mockCampaigns';

/**
 * 캠페인 생성 데이터
 */
export interface CreateCampaignData {
  key: string;
  kind: 'EVENT' | 'NOTICE' | 'AD' | 'MISSION';
  placement: 'HOME_MODAL' | 'HOME_BANNER' | 'NOTICE_CENTER' | 'BENEFITS_PAGE';
  template: string;
  priority: number;
  is_enabled: boolean;
  start_at: string;
  end_at: string;
  content: {
    title: string;
    description?: string;
    image_url?: string;
    cta?: {
      text: string;
      deeplink: string;
    };
  };
  rules?: any[];
  actions?: any[];
}

/**
 * 캠페인 조회 파라미터
 */
export interface GetCampaignsParams {
  key?: string;
  kind?: 'EVENT' | 'NOTICE' | 'AD' | 'MISSION';
  placement?: 'HOME_MODAL' | 'HOME_BANNER' | 'NOTICE_CENTER';
  template?: string;
  enabled?: boolean;
}

/**
 * 리워드 조회 파라미터
 */
export interface GetRewardsParams {
  user_id?: string;
  campaign_id?: string;
}

/**
 * 노출 조회 파라미터
 */
export interface GetImpressionsParams {
  user_id?: string;
  campaign_id?: string;
}

/**
 * 시뮬레이션 파라미터
 */
export interface SimulateParams {
  user_id: string;
  trigger: 'FIRST_TRACKING_CREATED' | 'SIGNUP_COMPLETE' | 'ALERT_CLICKED' | 'REFERRAL_CONFIRMED';
  context?: Record<string, any>;
}

/**
 * 캠페인 서비스
 */
export const campaignService = {
  /**
   * 캠페인 목록 조회
   */
  async getCampaigns(params: GetCampaignsParams = {}): Promise<Campaign[]> {
    const queryParams = new URLSearchParams();
    
    if (params.key) queryParams.append('key', params.key);
    if (params.kind) queryParams.append('kind', params.kind);
    if (params.placement) queryParams.append('placement', params.placement);
    if (params.template) queryParams.append('template', params.template);
    if (params.enabled !== undefined) queryParams.append('enabled', params.enabled.toString());

    const queryString = queryParams.toString();
    const url = queryString ? `${API_PATHS.CAMPAIGNS}?${queryString}` : API_PATHS.CAMPAIGNS;
    
    const data = await apiRequest<any[]>(url);
    // 백엔드 응답(snake_case)을 프론트엔드 형식(camelCase)으로 변환
    return data.map(campaign => ({
      id: campaign.id,
      key: campaign.key,
      kind: campaign.kind,
      placement: campaign.placement,
      template: campaign.template,
      priority: campaign.priority,
      isEnabled: campaign.is_enabled,
      startAt: campaign.start_at,
      endAt: campaign.end_at,
      status: campaign.status,
      content: campaign.content,
    }));
  },

  /**
   * 캠페인 상세 조회
   */
  async getCampaign(id: string): Promise<Campaign> {
    const data = await apiRequest<any>(API_PATHS.CAMPAIGN(id));
    // 백엔드 응답(snake_case)을 프론트엔드 형식(camelCase)으로 변환
    return {
      id: data.id,
      key: data.key,
      kind: data.kind,
      placement: data.placement,
      template: data.template,
      priority: data.priority,
      isEnabled: data.is_enabled,
      startAt: data.start_at,
      endAt: data.end_at,
      status: data.status,
      content: data.content,
    };
  },

  /**
   * 캠페인 생성
   */
  async createCampaign(data: CreateCampaignData): Promise<Campaign> {
    const response = await apiRequest<any>(API_PATHS.CAMPAIGNS, {
      method: 'POST',
      body: JSON.stringify(data),
    });
    // 백엔드 응답(snake_case)을 프론트엔드 형식(camelCase)으로 변환
    return {
      id: response.id,
      key: response.key,
      kind: response.kind,
      placement: response.placement,
      template: response.template,
      priority: response.priority,
      isEnabled: response.is_enabled,
      startAt: response.start_at,
      endAt: response.end_at,
      status: response.status,
      content: response.content,
    };
  },

  /**
   * 캠페인 수정
   */
  async updateCampaign(id: string, data: Partial<CreateCampaignData>): Promise<Campaign> {
    const response = await apiRequest<any>(API_PATHS.CAMPAIGN(id), {
      method: 'PUT',
      body: JSON.stringify(data),
    });
    // 백엔드 응답(snake_case)을 프론트엔드 형식(camelCase)으로 변환
    return {
      id: response.id,
      key: response.key,
      kind: response.kind,
      placement: response.placement,
      template: response.template,
      priority: response.priority,
      isEnabled: response.is_enabled,
      startAt: response.start_at,
      endAt: response.end_at,
      status: response.status,
      content: response.content,
    };
  },

  /**
   * 캠페인 활성화/비활성화
   */
  async toggleCampaign(id: string, isEnabled: boolean): Promise<Campaign> {
    const response = await apiRequest<any>(API_PATHS.CAMPAIGN_TOGGLE(id), {
      method: 'POST',
      body: JSON.stringify({ is_enabled: isEnabled }),
    });
    // 백엔드 응답(snake_case)을 프론트엔드 형식(camelCase)으로 변환
    return {
      id: response.id,
      key: response.key,
      kind: response.kind,
      placement: response.placement,
      template: response.template,
      priority: response.priority,
      isEnabled: response.is_enabled,
      startAt: response.start_at,
      endAt: response.end_at,
      status: response.status,
      content: response.content,
    };
  },

  /**
   * 리워드 조회
   */
  async getRewards(params: GetRewardsParams = {}): Promise<Reward[]> {
    const queryParams = new URLSearchParams();
    
    if (params.user_id) queryParams.append('user_id', params.user_id);
    if (params.campaign_id) queryParams.append('campaign_id', params.campaign_id);

    const queryString = queryParams.toString();
    const url = queryString ? `${API_PATHS.REWARDS}?${queryString}` : API_PATHS.REWARDS;
    
    return apiRequest(url);
  },

  /**
   * 노출 조회
   */
  async getImpressions(params: GetImpressionsParams = {}): Promise<Impression[]> {
    const queryParams = new URLSearchParams();
    
    if (params.user_id) queryParams.append('user_id', params.user_id);
    if (params.campaign_id) queryParams.append('campaign_id', params.campaign_id);

    const queryString = queryParams.toString();
    const url = queryString ? `${API_PATHS.IMPRESSIONS}?${queryString}` : API_PATHS.IMPRESSIONS;
    
    return apiRequest(url);
  },

  /**
   * 시뮬레이션 실행
   */
  async simulate(params: SimulateParams): Promise<any> {
    return apiRequest(API_PATHS.CAMPAIGN_SIMULATE, {
      method: 'POST',
      body: JSON.stringify(params),
    });
  },
};
