import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 앱 타이포그래피 정의 (DESIGN_GUIDE.md 기반)
class AppTypography {
  // H1: 42px (모바일: 34px), letter-spacing: -1px
  static const TextStyle h1 = TextStyle(
    fontSize: 42,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.0,
    color: AppColors.textPrimary,
    height: 1.2,
  );
  
  static const TextStyle h1Mobile = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.0,
    color: AppColors.textPrimary,
    height: 1.2,
  );
  
  // H2: 26px, letter-spacing: -0.5px
  static const TextStyle h2 = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
    height: 1.3,
  );
  
  // H3: 18px, letter-spacing: -0.2px
  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  // Lead: 17px, color: muted
  static const TextStyle lead = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.6,
  );
  
  // Body: 16px
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.6,
  );
  
  static const TextStyle body1 = body;
  
  static const TextStyle body2 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.6,
  );
  
  // Small: 14px
  static const TextStyle small = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );
  
  // Caption: 13px (Badge/Chip)
  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
    height: 1.4,
  );
  
  // Button: font-weight: 800
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: 0.1,
  );
  
  // Badge/Chip: 13px, font-weight: 700 or 800
  static const TextStyle badge = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.chipText,
    height: 1.2,
  );
  
  static const TextStyle aiBadge = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    color: AppColors.aiChipText,
    height: 1.2,
  );
  
  // Legacy (호환성)
  static const TextStyle title = h2;
  static const TextStyle titleLarge = h1;
  static const TextStyle titleMedium = h3;
}
