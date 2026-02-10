/// 앱 Border Radius 정의 (DESIGN_GUIDE.md 기반)
class AppRadius {
  AppRadius._(); // 인스턴스 생성 방지
  
  // DESIGN_GUIDE v1.0 규칙
  static const double sm = 8;   // 배지 / Chip
  static const double md = 12;  // 카드 / 버튼 (기본)
  static const double lg = 16;  // 바텀시트
  static const double xl = 20;  // 큰 바텀시트
  
  // Legacy (호환성)
  static const double small = sm;
  static const double medium = md;
  static const double large = lg;
  static const double xlarge = xl;
  
  // Bottom Sheet
  static const double bottomSheet = lg;
  
  // Button
  static const double button = md;
  static const double buttonModal = md;
  static const double buttonPill = 999.0; // 완전한 둥근 모서리
  
  // Card
  static const double card = md;
  
  // Chip/Badge
  static const double chip = sm;
  static const double badge = sm;
  
  // FAB
  static const double fab = 28.0;
  
  // Panel
  static const double panel = lg;
  
  // Callout
  static const double callout = lg;
  
  // Media
  static const double media = 14.0;
  
  // Step Num
  static const double stepNum = 10.0;
  
  // Code
  static const double code = 8.0;
}
