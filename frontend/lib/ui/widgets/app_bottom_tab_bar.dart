import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

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
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: AppColors.divider.withOpacity(0.3), // 매우 연한 divider
            width: 0.5,
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
                  Icons.home,
                  size: 24,
                  color: currentIndex == 0 
                      ? AppColors.primary 
                      : AppColors.textSub,
                ),
                label: '홈',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _TabItem(
                icon: Icon(
                  Icons.favorite,
                  size: 24,
                  color: currentIndex == 1 
                      ? AppColors.primary 
                      : AppColors.textSub,
                ),
                label: '관심',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _TabItem(
                icon: Icon(
                  Icons.shopping_bag,
                  size: 24,
                  color: currentIndex == 2 
                      ? AppColors.primary 
                      : AppColors.textSub,
                ),
                label: '마켓',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _TabItem(
                icon: Icon(
                  Icons.card_giftcard,
                  size: 24,
                  color: currentIndex == 3 
                      ? AppColors.primary 
                      : AppColors.textSub,
                ),
                label: '혜택',
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
              _TabItem(
                icon: Icon(
                  Icons.person,
                  size: 24,
                  color: currentIndex == 4 
                      ? AppColors.primary 
                      : AppColors.textSub,
                ),
                label: '마이',
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon, // AnimatedScale 제거 (배경/버블 효과 금지)
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.sub.copyWith(
                fontSize: 11,
                color: isActive ? AppColors.primary : AppColors.textSub,
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

