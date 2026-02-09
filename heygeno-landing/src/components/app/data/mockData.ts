export const mockProducts = [
  {
    id: '1',
    name: 'Premium Grain-Free Dog Food',
    brand: 'Royal Canin',
    price: 45000,
    comparePrice: 55000,
    avgPrice: 51000,
    matchScore: 92,
    image: 'https://images.unsplash.com/photo-1747577672787-56218a6cbc87?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxkb2clMjBmb29kJTIwa2liYmxlJTIwcHJvZHVjdHxlbnwxfHx8fDE3NzAxODc4Mzl8MA&ixlib=rb-4.1.0&q=80&w=1080',
    isWatched: true,
    badge: '로켓배송',
    protein: '28%',
    fat: '15%',
    fiber: '3.5%',
    matchReasons: [
      'BCS 5 유지에 최적화',
      '알레르기 성분 없음',
      '체중 관리 적합',
      '활동량 맞춤'
    ]
  },
  {
    id: '2',
    name: 'Natural Cat Wet Food Variety Pack',
    brand: 'Hill\'s Science',
    price: 32000,
    comparePrice: 38000,
    avgPrice: 35000,
    matchScore: 88,
    image: 'https://images.unsplash.com/photo-1766852217075-0e48f46a0767?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjYXQlMjBmb29kJTIwd2V0JTIwZm9vZHxlbnwxfHx8fDE3NzAxODc4NDB8MA&ixlib=rb-4.1.0&q=80&w=1080',
    isWatched: false,
    badge: '로켓배송',
    protein: '10%',
    fat: '5%',
    fiber: '1.5%',
    matchReasons: [
      '나이에 적합한 영양소',
      '소화가 잘 되는 성분',
      '수분 공급 우수'
    ]
  },
  {
    id: '3',
    name: 'Organic Training Treats',
    brand: 'Blue Buffalo',
    price: 18000,
    avgPrice: 18000,
    matchScore: 76,
    image: 'https://images.unsplash.com/photo-1741942732076-da82c73d3334?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxwZXQlMjB0cmVhdHMlMjBuYXR1cmFsfGVufDF8fHx8MTc3MDE4Nzg0MHww&ixlib=rb-4.1.0&q=80&w=1080',
    isWatched: true,
    protein: '22%',
    fat: '8%',
    fiber: '4%',
    matchReasons: [
      '트레이닝 보상용',
      '저칼로리'
    ]
  },
  {
    id: '4',
    name: 'Puppy Growth Formula',
    brand: 'Purina Pro',
    price: 52000,
    comparePrice: 60000,
    avgPrice: 58000,
    matchScore: 85,
    image: 'https://images.unsplash.com/photo-1747577672787-56218a6cbc87?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxkb2clMjBmb29kJTIwa2liYmxlJTIwcHJvZHVjdHxlbnwxfHx8fDE3NzAxODc4Mzl8MA&ixlib=rb-4.1.0&q=80&w=1080',
    isWatched: false,
    badge: '로켓배송',
    protein: '30%',
    fat: '18%',
    fiber: '3%',
    matchReasons: [
      '성장기 영양',
      '고단백 고지방',
      '뼈 발달 지원'
    ]
  },
  {
    id: '5',
    name: 'Senior Dog Food Formula',
    brand: 'Nutro',
    price: 42000,
    avgPrice: 45000,
    matchScore: 89,
    image: 'https://images.unsplash.com/photo-1747577672787-56218a6cbc87?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxkb2clMjBmb29kJTIwa2liYmxlJTIwcHJvZHVjdHxlbnwxfHx8fDE3NzAxODc4Mzl8MA&ixlib=rb-4.1.0&q=80&w=1080',
    isWatched: true,
    matchScore: 94,
    protein: '26%',
    fat: '12%',
    fiber: '4%',
    matchReasons: [
      '나이에 맞는 영양',
      '관절 케어',
      '소화 개선'
    ]
  },
  {
    id: '6',
    name: 'Indoor Cat Complete Nutrition',
    brand: 'Royal Canin',
    price: 38000,
    comparePrice: 45000,
    avgPrice: 42000,
    matchScore: 81,
    image: 'https://images.unsplash.com/photo-1766852217075-0e48f46a0767?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjYXQlMjBmb29kJTIwd2V0JTIwZm9vZHxlbnwxfHx8fDE3NzAxODc4NDB8MA&ixlib=rb-4.1.0&q=80&w=1080',
    isWatched: false,
    badge: '로켓배송',
    protein: '27%',
    fat: '11%',
    fiber: '5%',
    matchReasons: [
      '실내 생활 최적화',
      '헤어볼 관리',
      '체중 유지'
    ]
  },
];

export const petData = {
  name: 'Max',
  age: 3,
  weight: 15.2,
  breed: 'Golden Retriever',
  bcs: 5,
  dailyKcal: 285,
  dailyGrams: 180,
};

export const recentRecommendations = [
  { productId: '1', date: '2024-02-04', matchScore: 92, price: 45000 },
  { productId: '5', date: '2024-02-03', matchScore: 89, price: 42000 },
  { productId: '4', date: '2024-02-02', matchScore: 85, price: 52000 },
];