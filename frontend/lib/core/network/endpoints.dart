class Endpoints {
  // Health
  static const String health = '/health';
  
  // Pets
  static const String pets = '/pets';
  static String pet(String id) => '$pets/$id';
  static const String primaryPet = '$pets/primary';
  
  // Products
  static const String products = '/products';
  static String product(String id) => '$products/$id';
  static const String productRecommendations = '$products/recommendations';
  static const String productRecommendationHistory = '$products/recommendations/history';
  static String productOffers(String id) => '$products/$id/offers';
  
  // Trackings
  static const String trackings = '/trackings';
  static String tracking(String id) => '$trackings/$id';
  
  // Alerts
  static const String alerts = '/alerts';
  static String alert(String id) => '$alerts/$id';
  
  // Clicks
  static const String clicks = '/clicks';
  
  // Onboarding
  static const String onboardingComplete = '/onboarding/complete';
}
