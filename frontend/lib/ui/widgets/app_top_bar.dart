import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

/// 공통 Top Bar 위젯 (쿠팡 스타일)
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSettingsTap;
  final List<Widget>? actions;
  final bool showBackButton;

  const AppTopBar({
    super.key,
    required this.title,
    this.onNotificationTap,
    this.onSettingsTap,
    this.actions,
    this.showBackButton = true, // 기본값은 true (뒤로가기 버튼 표시)
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white, // White background (DESIGN_GUIDE v2.2)
      height: kToolbarHeight,
      child: Padding(
        padding: const EdgeInsets.only(left: 15), // 왼쪽 패딩 15px
        child: Row(
          children: [
            // 뒤로가기 버튼 (조건부 표시)
            if (showBackButton)
              IconButton(
                icon: const Icon(Icons.arrow_back),
                color: AppColors.textPrimary,
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            // 타이틀
            Expanded(
        child: Text(
          title,
                style: AppTypography.body.copyWith(
            color: AppColors.textPrimary, // #0F172A
                  fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
          // 액션 버튼들
          ...(actions ??
          [
            // 알림 아이콘 (iOS 스타일 - 심플)
            IconButton(
              icon: const Icon(Icons.notifications_none),
              color: AppColors.textSecondary,
              iconSize: 26,
              onPressed: onNotificationTap ?? () {
                // TODO: 알림 화면 연결
              },
            ),
            const SizedBox(width: 8),
              ]),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
