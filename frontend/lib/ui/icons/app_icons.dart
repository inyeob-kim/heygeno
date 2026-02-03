import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// iOS 스타일 아이콘 (SF Symbols 기반 느낌)
class AppIcons {
  // 홈
  static Widget home({bool isActive = false, double size = 24}) {
    return Icon(
      Icons.home,
      size: size,
      color: isActive ? AppColors.primary : AppColors.textSecondary,
    );
  }

  // 관심
  static Widget favorite({bool isActive = false, double size = 24}) {
    return Icon(
      Icons.favorite,
      size: size,
      color: isActive ? AppColors.primary : AppColors.textSecondary,
    );
  }

  // 추가 (FAB)
  static Widget add({double size = 24, Color? color}) {
    return Icon(
      Icons.add_circle,
      size: size,
      color: color ?? Colors.white,
    );
  }

  // 혜택
  static Widget gift({bool isActive = false, double size = 24}) {
    return Icon(
      Icons.card_giftcard,
      size: size,
      color: isActive ? AppColors.primary : AppColors.textSecondary,
    );
  }

  // 마이
  static Widget person({bool isActive = false, double size = 24}) {
    return Icon(
      Icons.person,
      size: size,
      color: isActive ? AppColors.primary : AppColors.textSecondary,
    );
  }

  // 알림
  static Widget bell({bool isActive = false, double size = 22}) {
    return Icon(
      isActive ? Icons.notifications_rounded : Icons.notifications_outlined,
      size: size,
      color: isActive ? AppColors.primaryBlue : AppColors.textPrimary,
    );
  }

  // 설정
  static Widget settings({double size = 22}) {
    return Icon(
      Icons.settings_rounded,
      size: size,
      color: AppColors.textPrimary,
    );
  }

  // AddCard용
  static Widget addCircle({double size = 48}) {
    return Icon(
      Icons.add_circle_outline_rounded,
      size: size,
      color: AppColors.iconMuted,
    );
  }
  
  // 토스 스타일: 더 큰 아이콘 크기
  static const double iconSizeLarge = 28;
  static const double iconSizeMedium = 24;
  static const double iconSizeSmall = 20;
}
