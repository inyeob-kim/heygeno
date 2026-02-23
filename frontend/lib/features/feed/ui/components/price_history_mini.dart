import 'package:flutter/material.dart';
import '../../../../design_system/components/app_card.dart';
import '../../../../ui/theme/app_colors.dart';
import '../../../../ui/theme/app_typography.dart';
import '../../../../ui/theme/app_spacing.dart';
import '../../../../ui/theme/app_radius.dart';

/// 가격 히스토리 미니 컴포넌트
class PriceHistoryMini extends StatelessWidget {
  final int lowest;
  final int avg;
  final int current;
  final bool chartPlaceholder;

  const PriceHistoryMini({
    super.key,
    required this.lowest,
    required this.avg,
    required this.current,
    this.chartPlaceholder = true,
  });

  String _formatPrice(int price) {
    return '${(price / 1000).toStringAsFixed(0)}원';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 차트 placeholder
          if (chartPlaceholder)
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.chipBg,
                borderRadius: BorderRadius.circular(AppRadius.cardRadius),
              ),
              child: Center(
                child: Text(
                  '차트 영역',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ),
          if (chartPlaceholder) const SizedBox(height: AppSpacing.sectionGap),
          
          // 요약 정보
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _PriceItem(label: '최저', value: _formatPrice(lowest)),
              _PriceItem(label: '평균', value: _formatPrice(avg)),
              _PriceItem(label: '현재', value: _formatPrice(current)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceItem extends StatelessWidget {
  final String label;
  final String value;

  const _PriceItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

