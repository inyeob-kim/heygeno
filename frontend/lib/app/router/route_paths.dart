/// 라우트 경로 상수 관리
class RoutePaths {
  // 스플래시
  static const String initialSplash = '/';

  // 시작 화면 (게스트 우선)
  static const String start = '/start';

  // Quick recommendation flow (anonymous)
  static const String quickProfileWizard = '/quick-profile';
  static const String quickRecommendationList = '/quick-recommendations';

  // 인증
  static const String signIn = '/signin';
  static const String signUp = '/signup';
  
  // 온보딩
  static const String onboarding = '/onboarding';
  static const String onboardingV2 = '/onboarding_v2'; // Add pet (chat onboarding)
  static const String welcome = '/welcome'; // Post-onboarding welcome
  static const String petProfile = '/pet-profile';
  static String petUpdate(String petId) => '/pet-update/$petId';
  
  // 메인 탭 (4탭 구조: Home, Match, Market, Alerts)
  static const String home = '/home';
  static const String match = '/match'; // 추천 엔진 + 성분 분석 (기존 find/recommendation)
  static const String market = '/market'; // 멀티플랫폼 가격 비교 (기존 deals)
  static const String alerts = '/alerts'; // 알림 (기존 watch)
  
  // Legacy 경로 (리다이렉트용)
  static const String watch = '/watch'; // → /alerts로 리다이렉트
  static const String find = '/find'; // → /match로 리다이렉트
  static const String deals = '/deals'; // → /market로 리다이렉트
  static const String benefits = '/benefits'; // Home에 통합 또는 제거
  static const String me = '/me'; // Home 우상단으로 이동
  
  // 상세 화면
  static const String productDetail = '/products/:id';
  static const String petProfileDetail = '/pet-profile-detail';
  static const String recommendation = '/recommendation';
  static const String recommendationAnimation = '/recommendation/animation';
  static const String recommendationDetail = '/recommendation/detail';
  
  // 설정 화면 (중첩 라우트 - /me 하위)
  static const String notificationSettings = '/settings/notifications';
  static const String privacySettings = 'me.privacy'; // 고유한 라우트 이름
  static const String help = 'me.help'; // 고유한 라우트 이름
  static const String contact = 'me.contact'; // 고유한 라우트 이름
  static const String appInfo = 'me.app-info'; // 고유한 라우트 이름
  
  /// 경로에서 productId 추출
  static String productDetailPath(String productId) => '/products/$productId';
}

