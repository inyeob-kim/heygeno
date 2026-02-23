import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../../../ui/theme/app_colors.dart';
import '../../../../../ui/theme/app_typography.dart';
import '../../../../../ui/components/metric_row.dart';
import '../../../../data/models/recommendation_dto.dart';
import 'package:pet_food_app/l10n/app_localizations.dart';

/// 추천 사료 섹션 (토스 스타일 - 카드 없음)
/// 텍스트 기반 섹션으로 구성
class RecommendationCard extends StatelessWidget {
  final RecommendationItemDto? topRecommendation;
  final bool isLoading;
  final String? petName;
  final VoidCallback? onWhyRecommended;

  const RecommendationCard({
    super.key,
    this.topRecommendation,
    this.isLoading = false,
    this.petName,
    this.onWhyRecommended,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      final l10n = AppLocalizations.of(context)!;
      final loadingText = petName != null
          ? l10n.home_findingPerfectFood(petName!)
          : l10n.common_analyzing;
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/paw_loading.json',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
            repeat: true,
            animate: true,
          ),
          const SizedBox(height: 16),
          Text(
            loadingText,
            style: AppTypography.body,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (topRecommendation == null) {
      final l10n = AppLocalizations.of(context)!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.recommendation_preparing,
            style: AppTypography.body,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.recommendation_comingSoon,
            style: AppTypography.sub,
          ),
        ],
      );
    }

    final product = topRecommendation!.product;
    final deltaPercent = topRecommendation!.deltaPercent;
    final currentPrice = topRecommendation!.currentPrice;
    final avgPrice = topRecommendation!.avgPrice;

    // 가격 차이 계산 (평균 대비)
    final priceDiff = avgPrice - currentPrice;
    final priceDiffPercent = avgPrice > 0 
        ? ((priceDiff / avgPrice) * 100).abs()
        : 0.0;
    final isCheaper = priceDiff > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상품명
        Text(
          '${product.brandName} ${product.productName}',
          style: AppTypography.body,
        ),
        const SizedBox(height: 12),
        
        // 가격 (강조)
        Text(
          '${_formatPrice(currentPrice)}원',
          style: AppTypography.priceNumeric.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // MetricRow: 평균 대비
        if (deltaPercent != null && avgPrice > 0)
          MetricRow(
            label: AppLocalizations.of(context)!.metric_averageDelta,
            valueText: isCheaper
                ? '-${priceDiffPercent.toStringAsFixed(1)}%'
                : '+${priceDiffPercent.toStringAsFixed(1)}%',
            valueColor: isCheaper ? AppColors.positive : AppColors.negative,
            helperText: AppLocalizations.of(context)!.metric_last14Days,
          ),
        
        // '왜 추천?' 링크
        if (onWhyRecommended != null) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onWhyRecommended,
            child: Text(
              AppLocalizations.of(context)!.action_whyRecommended,
              style: AppTypography.sub.copyWith(
                color: AppColors.textSecondary, // 중성 회색 텍스트
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
