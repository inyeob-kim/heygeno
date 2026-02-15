import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

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
              _TabItem(
                icon: Icon(
                  currentIndex == 0 ? Icons.home_rounded : Icons.home_outlined,
                  size: 26,
                  color: currentIndex == 0 
                      ? AppColors.textPrimary 
                      : AppColors.textSecondary,
                ),
                label: '홈',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _TabItem(
                icon: Icon(
                  currentIndex == 1 ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 26,
                  color: currentIndex == 1 
                      ? AppColors.textPrimary 
                      : AppColors.textSecondary,
                ),
                label: '관심',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _TabItem(
                icon: Icon(
                  currentIndex == 2 ? Icons.shopping_bag_rounded : Icons.shopping_bag_outlined,
                  size: 26,
                  color: currentIndex == 2 
                      ? AppColors.textPrimary 
                      : AppColors.textSecondary,
                ),
                label: '마켓',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _TabItem(
                icon: Icon(
                  currentIndex == 3 ? Icons.local_offer_rounded : Icons.local_offer_outlined,
                  size: 26,
                  color: currentIndex == 3 
                      ? AppColors.textPrimary 
                      : AppColors.textSecondary,
                ),
                label: '혜택',
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
              _TabItem(
                icon: Icon(
                  currentIndex == 4 ? Icons.more_horiz_rounded : Icons.more_horiz_outlined,
                  size: 26,
                  color: currentIndex == 4 
                      ? AppColors.textPrimary 
                      : AppColors.textSecondary,
                ),
                label: '더보기',
                isActive: currentIndex == 4,
                onTap: () => onTap(4),
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
            const SizedBox(height: 2),
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

