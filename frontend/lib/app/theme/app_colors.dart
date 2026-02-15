import 'package:flutter/material.dart';

/// 앱 색상 정의 (DESIGN_GUIDE.md v4.1 - Data-Driven Premium Platform Edition)
/// 
/// 컬러 철학:
/// - Blue = 브랜드 & 결정
/// - Green = 상태 & 정상
/// - Red = 가격 상승/위험
/// - Neutral = 데이터 기반 구조
class AppColors {
  // ============================================
  // 🔵 Brand Primary (Core Identity) - HeyGeno Landing Style
  // ============================================
  static const Color primary = Color(0xFF2563EB); // Blue 600 (HeyGeno Landing)
  static const Color primaryHover = Color(0xFF1E40AF);
  static const Color primaryLight = Color(0xFFEFF6FF); // Blue 50 (HeyGeno Landing)
  static const Color primaryLighter = Color(0xFFDBEAFE); // Blue 100 (HeyGeno Landing)

  // ============================================
  // 🟢 Status Color (상태 전용)
  // ============================================
  static const Color status = Color(0xFF16A34A); // 상태 & 정상
  static const Color statusLight = Color(0xFFECFDF5); // 연한 그린 배경

  // ============================================
  // 🔴 Alert / Drop (가격 상승/위험 전용)
  // ============================================
  static const Color drop = Color(0xFFDC2626); // 가격 상승/위험 알림
  static const Color dropLight = Color(0xFFFEE2E2); // 연한 레드 배경

  // ============================================
  // ⚪ Premium Neutral - 펫 분석 프로필 스타일
  // ============================================
  static const Color background = Color(0xFFF8FAFC); // 분석 프로필 배경
  static const Color surface = Color(0xFFFFFFFF); // White (카드 배경)
  static const Color surfaceLight = Color(0xFFEFF6FF); // Light Blue (HeyGeno Landing - 섹션 배경)
  
  // 텍스트 - 펫 분석 프로필 스타일
  static const Color textPrimary = Color(0xFF111827); // 분석 프로필 텍스트
  static const Color textSecondary = Color(0xFF6B7280); // 분석 프로필 보조 텍스트
  static const Color textMuted = Color(0xFF717182); // HeyGeno Landing
  
  // 경계선
  static const Color border = Color(0xFFE5E7EB); // Gray 200
  static const Color divider = Color(0xFFF1F5F9); // Slate 100
  
  // Legacy 별칭 (호환성)
  static const Color line = border;
  static const Color borderSoft = border;

  // ============================================
  // Legacy 호환성 (점진적 제거 예정)
  // ============================================
  @deprecated // v4.1에서 제거 - primary 사용
  static const Color primaryDark = primaryHover;
  
  @deprecated // v4.1에서 제거 - status 사용
  static const Color petGreen = status;
  
  @deprecated // v4.1에서 제거 - statusLight 사용
  static const Color petGreenLight = statusLight;
  
  @deprecated // v4.1에서 제거 - primaryHover 사용
  static const Color petGreenDark = primaryHover;
  
  @deprecated // v4.1에서 제거 - status 사용
  static const Color positive = status;
  
  @deprecated // v4.1에서 제거 - drop 사용
  static const Color danger = drop;
  
  @deprecated // v4.1에서 제거 - drop 사용
  static const Color error = drop;
  
  @deprecated // v4.1에서 제거 - status 사용
  static const Color success = status;
  
  @deprecated // v4.1에서 제거 - statusLight 사용
  static const Color accentGreen = statusLight;
  
  @deprecated // v4.1에서 제거
  static const Color caution = Color(0xFFF59E0B);
  
  @deprecated // v4.1에서 제거 - primary 사용
  static const Color primaryCoral = primary;
  
  @deprecated // v4.1에서 제거 - surfaceLight 사용
  static const Color surfaceWarm = surfaceLight;
  
  @deprecated // v4.1에서 제거
  static const Color primary2 = primaryHover;
  
  @deprecated // v4.1에서 제거
  static const Color primarySoft = surfaceLight;
  
  @deprecated // v4.1에서 제거
  static const Color primaryBlue = primary;
  
  @deprecated // v4.1에서 제거
  static const Color primaryBlueSoft = primaryLight;
  
  @deprecated // v4.1에서 제거
  static const Color positiveGreen = status;
  
  @deprecated // v4.1에서 제거
  static const Color dangerRed = drop;
  
  // Icon
  static const Color iconMuted = textSecondary;
  static const Color iconPrimary = textPrimary;

  // BottomNav
  static const Color bottomNavInactive = textSecondary;
  static const Color bottomNavActive = primary; // Blue

  // FAB
  static const Color fabBackground = primary; // Blue

  // Card
  static const Color cardBackground = surface; // White

  // Chip/Badge
  static const Color chipBackground = surfaceLight; // Legacy 호환성
  static const Color chipText = textPrimary;

  // AI Colors (유지)
  static const Color ai = Color(0xFF7C3AED); // Violet 600
  static const Color ai2 = Color(0xFF6D28D9); // Violet 700
  static const Color aiChip = Color(0xFFF3E8FF); // Violet 100
  static const Color aiChipText = Color(0xFF4C1D95); // Violet 900

  // Border with opacity
  static Color primaryBorder = primary.withOpacity(0.18); // Blue with opacity
  static Color aiBorder = const Color(0xFF7C3AED).withOpacity(0.18);
  static Color aiBorderStrong = const Color(0xFF7C3AED).withOpacity(0.22);
}
