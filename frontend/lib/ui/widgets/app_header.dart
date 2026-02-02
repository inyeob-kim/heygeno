import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/app_spacing.dart';
import '../icons/app_icons.dart';

/// iOS 스타일 헤더 (DESIGN_GUIDE.md 기반)
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onNotificationTap;
  final bool showNotification;

  const AppHeader({
    super.key,
    required this.title,
    this.onNotificationTap,
    this.showNotification = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePaddingHorizontal,
            vertical: AppSpacing.navPaddingVertical,
          ),
          child: Row(
            children: [
              // 타이틀 (H2: 26px, letter-spacing: -0.5px)
              Text(
                title,
                style: AppTypography.h2,
              ),
              const Spacer(),
              // 알림 아이콘만
              if (showNotification)
                IconButton(
                  icon: AppIcons.bell(),
                  onPressed: onNotificationTap ?? () {
                    // TODO: 알림 화면 연결
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 12);
}
