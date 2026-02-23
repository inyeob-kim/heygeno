import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import 'package:pet_food_app/l10n/app_localizations.dart';

/// 토스 스타일 Bottom Tab Bar (가볍고 안정적)
class AppBottomTabBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.line, // #E5E7EB
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 0: Home
              _TabItem(
                icon: Icon(
                  currentIndex == 0 ? Icons.home_rounded : Icons.home_outlined,
                  size: 26,
                  color: currentIndex == 0 
                      ? AppColors.textPrimary 
                      : AppColors.textSecondary,
                ),
                label: AppLocalizations.of(context)!.tab_home,
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              // 1: Match (추천 엔진 + 성분 분석)
              _TabItem(
                icon: Icon(
                  currentIndex == 1 ? Icons.auto_awesome_rounded : Icons.auto_awesome_outlined,
                  size: 26,
                  color: currentIndex == 1 
                      ? AppColors.textPrimary 
                      : AppColors.textSecondary,
                ),
                label: 'Match', // TODO: Add to l10n
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              // 2: Market (멀티플랫폼 가격 비교)
              _TabItem(
                icon: Icon(
                  currentIndex == 2 ? Icons.shopping_bag_rounded : Icons.shopping_bag_outlined,
                  size: 26,
                  color: currentIndex == 2 
                      ? AppColors.textPrimary 
                      : AppColors.textSecondary,
                ),
                label: 'Market', // TODO: Add to l10n
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              // 3: Alerts (알림)
              _TabItem(
                icon: Icon(
                  currentIndex == 3 ? Icons.notifications_rounded : Icons.notifications_outlined,
                  size: 26,
                  color: currentIndex == 3 
                      ? AppColors.textPrimary 
                      : AppColors.textSecondary,
                ),
                label: AppLocalizations.of(context)!.tab_alerts,
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 탭 아이템 (토스 스타일 - 배경/버블 효과 없음)
class _TabItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 아이콘 색상 강제 적용 (테마 색상 무시)
    final iconWithColor = icon is Icon
        ? Icon(
            (icon as Icon).icon,
            size: (icon as Icon).size,
            color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
          )
        : icon;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWithColor,
            const SizedBox(height: 1),
            Text(
              label,
              style: AppTypography.small.copyWith(
                fontSize: 11,
                color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

