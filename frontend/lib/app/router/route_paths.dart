/// 라우트 경로 상수 관리
class RoutePaths {
  // 스플래시
  static const String initialSplash = '/';
  
  // 인증/온보딩
  static const String onboarding = '/onboarding';
  static const String onboardingV2 = '/onboarding_v2'; // Test route for new onboarding
  static const String petProfile = '/pet-profile';
  
  // 메인 탭
  static const String home = '/home';
  static const String watch = '/watch';
  static const String market = '/market';
  static const String benefits = '/benefits';
  static const String me = '/me';
  
  // 상세 화면
  static const String productDetail = '/products/:id';
  static const String petProfileDetail = '/pet-profile-detail';
  
  // 설정 화면 (중첩 라우트 - /me 하위)
  static const String notificationSettings = '/settings/notifications';
  static const String privacySettings = 'me.privacy'; // 고유한 라우트 이름
  static const String help = 'me.help'; // 고유한 라우트 이름
  static const String contact = 'me.contact'; // 고유한 라우트 이름
  static const String appInfo = 'me.app-info'; // 고유한 라우트 이름
  
  /// 경로에서 productId 추출
  static String productDetailPath(String productId) => '/products/$productId';
}

