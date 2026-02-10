/// Spacing 토큰 시스템
/// 
/// 이 프로젝트의 모든 간격은 다음 규칙을 따릅니다:
/// 
/// - xs(4): 미세 간격 (거의 사용 안 함)
/// - sm(8): 아이콘-텍스트, 작은 요소 간 간격
/// - md(12): 섹션 내부 그룹 간격
/// - lg(16): 카드 내부 주요 구분, 페이지 horizontal padding
/// - xl(24): 카드 간, 페이지 섹션 간 간격
/// 
/// 사용 예시:
/// ```dart
/// SizedBox(height: AppSpacing.md)  // 섹션 내부 그룹
/// SizedBox(width: AppSpacing.sm)   // 아이콘-텍스트 간격
/// EdgeInsets.symmetric(horizontal: AppSpacing.lg)  // 페이지 padding
/// ```
class AppSpacing {
  AppSpacing._(); // 인스턴스 생성 방지

  // micro
  static const double xs = 4;

  // element gap (icon-text, label-value)
  static const double sm = 8;

  // group gap (section 내부)
  static const double md = 12;

  // section gap (card 내부 주요 구분)
  static const double lg = 16;

  // page gap (카드 간)
  static const double xl = 24;
}
