export interface Campaign {
  id: string;
  key: string;
  kind: 'EVENT' | 'NOTICE' | 'AD' | 'MISSION';
  placement: 'HOME_MODAL' | 'HOME_BANNER' | 'NOTICE_CENTER' | 'BENEFITS_PAGE';
  template: string;
  priority: number;
  isEnabled: boolean;
  startAt: string;
  endAt: string;
  status: 'ACTIVE_NOW' | 'SCHEDULED' | 'EXPIRED' | 'DISABLED';
  content: Record<string, any>;
}

export const mockCampaigns: Campaign[] = [
  {
    id: 'camp_001',
    key: 'spring_event_2026',
    kind: 'EVENT',
    placement: 'HOME_MODAL',
    template: 'full_screen_modal',
    priority: 1,
    isEnabled: true,
    startAt: '2026-02-10T00:00:00Z',
    endAt: '2026-03-10T23:59:59Z',
    status: 'ACTIVE_NOW',
    content: {
      title: '봄맞이 특별 이벤트',
      description: '반려동물과 함께하는 봄, 최대 50% 할인',
      imageUrl: 'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=800',
    },
  },
  {
    id: 'camp_002',
    key: 'new_product_notice',
    kind: 'NOTICE',
    placement: 'NOTICE_CENTER',
    template: 'simple_notice',
    priority: 5,
    isEnabled: true,
    startAt: '2026-02-01T00:00:00Z',
    endAt: '2026-02-28T23:59:59Z',
    status: 'ACTIVE_NOW',
    content: {
      title: '신제품 출시 안내',
      description: '프리미엄 자연식 사료 라인업이 출시되었습니다.',
    },
  },
  {
    id: 'camp_003',
    key: 'summer_promo_2026',
    kind: 'EVENT',
    placement: 'HOME_BANNER',
    template: 'banner_carousel',
    priority: 2,
    isEnabled: false,
    startAt: '2026-06-01T00:00:00Z',
    endAt: '2026-08-31T23:59:59Z',
    status: 'SCHEDULED',
    content: {
      title: '여름 프로모션',
      description: '더운 여름, 시원한 할인',
      imageUrl: 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=800',
    },
  },
  {
    id: 'camp_004',
    key: 'winter_sale_2025',
    kind: 'AD',
    placement: 'HOME_BANNER',
    template: 'banner_simple',
    priority: 10,
    isEnabled: false,
    startAt: '2025-12-01T00:00:00Z',
    endAt: '2026-01-31T23:59:59Z',
    status: 'EXPIRED',
    content: {
      title: '겨울 세일',
      description: '연말 특가',
    },
  },
];

export interface Reward {
  id: string;
  userId: string;
  campaignId: string;
  rewardType: string;
  amount: number;
  status: 'GRANTED' | 'FAILED' | 'PENDING';
  createdAt: string;
}

export const mockRewards: Reward[] = [
  {
    id: 'rew_001',
    userId: 'user_12345',
    campaignId: 'camp_001',
    rewardType: 'COUPON',
    amount: 5000,
    status: 'GRANTED',
    createdAt: '2026-02-11T10:30:00Z',
  },
  {
    id: 'rew_002',
    userId: 'user_67890',
    campaignId: 'camp_001',
    rewardType: 'POINT',
    amount: 1000,
    status: 'GRANTED',
    createdAt: '2026-02-11T11:45:00Z',
  },
  {
    id: 'rew_003',
    userId: 'user_11111',
    campaignId: 'camp_001',
    rewardType: 'COUPON',
    amount: 5000,
    status: 'PENDING',
    createdAt: '2026-02-11T12:00:00Z',
  },
];

export interface Impression {
  id: string;
  userId: string;
  campaignId: string;
  seenCount: number;
  lastSeenAt: string;
  suppressUntil: string | null;
}

export const mockImpressions: Impression[] = [
  {
    id: 'imp_001',
    userId: 'user_12345',
    campaignId: 'camp_001',
    seenCount: 3,
    lastSeenAt: '2026-02-11T14:30:00Z',
    suppressUntil: '2026-02-12T14:30:00Z',
  },
  {
    id: 'imp_002',
    userId: 'user_67890',
    campaignId: 'camp_001',
    seenCount: 1,
    lastSeenAt: '2026-02-11T09:15:00Z',
    suppressUntil: null,
  },
];
