import 'package:flutter/material.dart';
import '../../../../design_system/components/app_card.dart';
import '../../../../design_system/components/button.dart';
import '../../../../ui/widgets/soft_chip.dart';
import '../../../../ui/widgets/stat_badge.dart';
import '../../../../ui/theme/app_colors.dart';
import '../../../../ui/theme/app_typography.dart';
import '../../../../ui/theme/app_spacing.dart';

/// 사료 추천 카드 컴포넌트
class FoodRecommendationCard extends StatelessWidget {
  final String brand;
  final String name;
  final int currentPrice;
  final double diffPercent; // 평균 대비
  final String verdictLabel; // "지금 사도 됨"
  final VoidCallback? onToggleAlert;
  final bool isAlertOn;

  const FoodRecommendationCard({
    super.key,
    required this.brand,
    required this.name,
    required this.currentPrice,
    required this.diffPercent,
    required this.verdictLabel,
    this.onToggleAlert,
    this.isAlertOn = false,
  });

  String _formatPrice(int price) {
    return '${(price / 1000).toStringAsFixed(0)}원';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      onTap: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 브랜드 + 배지
          Row(
            children: [
              Text(
                brand,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              StatBadge(
                value: diffPercent,
                isPositive: diffPercent < 0, // 음수면 할인
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // 상품명 (2줄 ellipsis)
          Text(
            name,
            style: AppTypography.titleMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          
          // 가격
          Text(
            _formatPrice(currentPrice),
            style: AppTypography.priceNumeric,
          ),
          const SizedBox(height: 12),
          
          // Verdict Chip
          SoftChip(label: verdictLabel),
          const SizedBox(height: 16),
          
          // CTA 버튼
          PrimaryButton(
            text: isAlertOn ? '알림 해제' : '가격 알림 받기',
            isSmall: true,
            onPressed: onToggleAlert,
          ),
        ],
      ),
    );
  }
}

