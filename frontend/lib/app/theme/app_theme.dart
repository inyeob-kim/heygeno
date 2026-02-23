import 'package:flutter/material.dart';
import 'app_colors.dart';
import '../../design_system/tokens/index.dart' as DesignTokens;
import '../../design_system/typography/index.dart' as DesignTypography;

/// 앱 테마 정의 (Rover/Chewy 스타일 - 미국 시장 올인)
/// 
/// 핵심 원칙:
/// - 색상 팔레트는 기존 값 유지 (절대 변경 금지)
/// - Rover 스타일: 여백 + 카드 중심 + 신뢰 톤 + 단순한 계층
/// - 영어 기본, 미국 시장 최적화
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      // 영어 기본 폰트 (미국 시장)
      fontFamily: 'Roboto', // 시스템 기본 폰트
      fontFamilyFallback: const ['SF Pro Display', 'Helvetica Neue', 'Arial'],
      
      colorScheme: ColorScheme.light(
        primary: AppColors.primary, // Blue (#2563EB) - 기존 값 유지
        surface: AppColors.surface, // White
        background: AppColors.background, // Premium Neutral (#F8FAFC) - 기존 값 유지
        error: AppColors.drop, // Red - 기존 값 유지
      ),
      scaffoldBackgroundColor: AppColors.background, // Premium Neutral (#F8FAFC)
      
      // TextTheme (Design System Typography 사용)
      textTheme: TextTheme(
        // H1: 32px (데스크톱), 28px (모바일)
        displayLarge: DesignTypography.TextStyles.h1,
        displayMedium: DesignTypography.TextStyles.h1Mobile,
        // H2: 24px
        displaySmall: DesignTypography.TextStyles.h2,
        titleLarge: DesignTypography.TextStyles.h2,
        // H3: 20px
        titleMedium: DesignTypography.TextStyles.h3,
        // Body: 16px
        bodyLarge: DesignTypography.TextStyles.body,
        bodyMedium: DesignTypography.TextStyles.body,
        titleSmall: DesignTypography.TextStyles.body,
        // Small: 14px
        bodySmall: DesignTypography.TextStyles.small,
        labelSmall: DesignTypography.TextStyles.small,
        labelMedium: DesignTypography.TextStyles.small,
        labelLarge: DesignTypography.TextStyles.small,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface, // White background
        elevation: 0, // 그림자 제거 (Rover 스타일)
        centerTitle: false,
        titleTextStyle: DesignTypography.TextStyles.h3.copyWith(
          color: AppColors.textPrimary, // #111827
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary, // #111827
        ),
        toolbarHeight: 64, // 여백 크게 (Rover 스타일)
      ),
      cardTheme: CardThemeData(
        elevation: 0, // Material elevation 제거
        color: AppColors.surface, // White
        shadowColor: Colors.transparent, // 그림자는 boxShadow로 처리
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.BorderRadiusTokens.card), // 20px (Rover 스타일)
        ),
        // 그림자는 컴포넌트에서 boxShadow로 처리
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider, // #F1F5F9
        thickness: 1,
        space: 1,
      ),
      // InputDecorationTheme 추가 (Rover 스타일)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.BorderRadiusTokens.input), // 16px
          borderSide: const BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.BorderRadiusTokens.input),
          borderSide: const BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.BorderRadiusTokens.input),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.BorderRadiusTokens.input),
          borderSide: const BorderSide(
            color: AppColors.drop,
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary, // Blue (#2563EB) - 기존 값 유지
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.Spacing.base, // 24px
            vertical: DesignTokens.Spacing.md, // 12px
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.BorderRadiusTokens.button), // pill (999)
          ),
          elevation: 0, // 그림자는 컴포넌트에서 처리
          minimumSize: Size(double.infinity, DesignTokens.Spacing.buttonHeight), // 48px (Rover 스타일)
          textStyle: DesignTypography.TextStyles.button, // Design System Typography
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary, // Blue (#2563EB) - 기존 값 유지
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.Spacing.base,
            vertical: DesignTokens.Spacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.BorderRadiusTokens.button), // pill
          ),
          elevation: 0,
          minimumSize: Size(double.infinity, DesignTokens.Spacing.buttonHeight), // 48px
          textStyle: DesignTypography.TextStyles.button, // Design System Typography
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.Spacing.base,
            vertical: DesignTokens.Spacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.BorderRadiusTokens.button), // pill
          ),
          minimumSize: Size(double.infinity, DesignTokens.Spacing.buttonHeight), // 48px
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary, // Blue
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface, // White
        selectedItemColor: AppColors.primary, // Blue
        unselectedItemColor: AppColors.iconMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      // 영어 기본 폰트 (미국 시장)
      fontFamily: 'Roboto',
      fontFamilyFallback: const ['SF Pro Display', 'Helvetica Neue', 'Arial'],
      
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary, // Blue (#2563EB) - 기존 값 유지
        surface: const Color(0xFF1E1E1E),
        background: const Color(0xFF121212),
        error: AppColors.drop, // Red - 기존 값 유지
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      
      // TextTheme (Design System Typography 사용)
      textTheme: TextTheme(
        displayLarge: DesignTypography.TextStyles.h1.copyWith(color: Colors.white),
        displayMedium: DesignTypography.TextStyles.h1Mobile.copyWith(color: Colors.white),
        displaySmall: DesignTypography.TextStyles.h2.copyWith(color: Colors.white),
        titleLarge: DesignTypography.TextStyles.h2.copyWith(color: Colors.white),
        titleMedium: DesignTypography.TextStyles.h3.copyWith(color: Colors.white),
        bodyLarge: DesignTypography.TextStyles.body.copyWith(color: Colors.white),
        bodyMedium: DesignTypography.TextStyles.body.copyWith(color: Colors.white),
        titleSmall: DesignTypography.TextStyles.body.copyWith(color: Colors.white),
        bodySmall: DesignTypography.TextStyles.small.copyWith(color: Colors.white70),
        labelSmall: DesignTypography.TextStyles.small.copyWith(color: Colors.white70),
        labelMedium: DesignTypography.TextStyles.small.copyWith(color: Colors.white70),
        labelLarge: DesignTypography.TextStyles.small.copyWith(color: Colors.white70),
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface, // White background (라이트 모드와 동일)
        elevation: 0, // 그림자 제거 (Rover 스타일)
        centerTitle: false,
        titleTextStyle: DesignTypography.TextStyles.h3.copyWith(
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
        ),
        toolbarHeight: 64, // 여백 크게 (Rover 스타일)
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1E1E1E),
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.BorderRadiusTokens.card), // 20px (Rover 스타일)
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2C2C2C),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.BorderRadiusTokens.input),
          borderSide: const BorderSide(
            color: Color(0xFF2C2C2C),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.BorderRadiusTokens.input),
          borderSide: const BorderSide(
            color: Color(0xFF2C2C2C),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.BorderRadiusTokens.input),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.BorderRadiusTokens.input),
          borderSide: const BorderSide(
            color: AppColors.drop,
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary, // Blue (#2563EB) - 기존 값 유지
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.Spacing.base,
            vertical: DesignTokens.Spacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.BorderRadiusTokens.button), // pill
          ),
          elevation: 0,
          minimumSize: Size(double.infinity, DesignTokens.Spacing.buttonHeight), // 48px
          textStyle: DesignTypography.TextStyles.button, // Design System Typography
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary, // Blue (#2563EB) - 기존 값 유지
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.Spacing.base,
            vertical: DesignTokens.Spacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.BorderRadiusTokens.button), // pill
          ),
          elevation: 0,
          minimumSize: Size(double.infinity, DesignTokens.Spacing.buttonHeight), // 48px
          textStyle: DesignTypography.TextStyles.button, // Design System Typography
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.Spacing.base,
            vertical: DesignTokens.Spacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.BorderRadiusTokens.button), // pill
          ),
          minimumSize: Size(double.infinity, DesignTokens.Spacing.buttonHeight), // 48px
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary, // Blue
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: AppColors.primary, // Blue
        unselectedItemColor: AppColors.iconMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
