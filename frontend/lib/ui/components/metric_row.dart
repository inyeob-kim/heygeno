import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'package:pet_food_app/l10n/app_localizations.dart';

/// 토스식 수치 요약 UI 컴포넌트
/// 예: '평균 대비 -7.9%' 형태의 한 줄 수치 표시
class MetricRow extends StatelessWidget {
  final String label; // '평균 대비'
  final String valueText; // '-7.9%'
  final Color? valueColor; // positive/negative 색상
  final String? helperText; // '최근 14일 기준'

  const MetricRow({
    super.key,
    required this.label,
    required this.valueText,
    this.valueColor,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    // valueColor가 없으면 기본 색상 사용
    final effectiveValueColor = valueColor ?? AppColors.textMain;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            // Label: 왼쪽 (sub 스타일)
            Text(
              label,
              style: AppTypography.sub,
            ),
            // Value: 오른쪽 (body 스타일, 색상 적용)
            Text(
              valueText,
              style: AppTypography.body.copyWith(
                color: effectiveValueColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        // Helper Text: 아래 작게 (있는 경우)
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText!,
            style: AppTypography.sub.copyWith(
              fontSize: 12,
              color: AppColors.textSub,
            ),
          ),
        ],
      ],
    );
  }
}

/// MetricRow의 편의 생성자들
extension MetricRowHelpers on MetricRow {
  /// 평균 대비 퍼센트 표시용
  static MetricRow averageDelta(
    BuildContext context, {
    required double deltaPercent,
    String? helperText,
  }) {
    final isPositive = deltaPercent < 0; // 음수면 저렴 (긍정)
    final valueText = deltaPercent >= 0
        ? '+${deltaPercent.toStringAsFixed(1)}%'
        : '${deltaPercent.toStringAsFixed(1)}%';
    
    return MetricRow(
      label: AppLocalizations.of(context)!.metric_averageDelta,
      valueText: valueText,
      valueColor: isPositive ? AppColors.positive : AppColors.negative,
      helperText: helperText ?? AppLocalizations.of(context)!.metric_last14Days,
    );
  }

  /// 할인율 표시용
  static MetricRow discount(
    BuildContext context, {
    required double discountPercent,
    String? helperText,
  }) {
    return MetricRow(
      label: AppLocalizations.of(context)!.metric_discount,
      valueText: '-${discountPercent.toStringAsFixed(1)}%',
      valueColor: AppColors.positive,
      helperText: helperText,
    );
  }

  /// 가격 차이 표시용
  static MetricRow priceDiff(
    BuildContext context, {
    required int currentPrice,
    required int avgPrice,
    String? helperText,
  }) {
    final diff = avgPrice - currentPrice;
    final diffPercent = avgPrice > 0 ? ((diff / avgPrice) * 100).abs() : 0.0;
    final isCheaper = diff > 0;
    
    return MetricRow(
      label: AppLocalizations.of(context)!.metric_averageDelta,
      valueText: isCheaper
          ? '-${diffPercent.toStringAsFixed(1)}%'
          : '+${diffPercent.toStringAsFixed(1)}%',
      valueColor: isCheaper ? AppColors.positive : AppColors.negative,
      helperText: helperText ?? AppLocalizations.of(context)!.metric_last14Days,
    );
  }
}
