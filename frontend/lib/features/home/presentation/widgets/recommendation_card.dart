import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../../../ui/theme/app_colors.dart';
import '../../../../../ui/theme/app_typography.dart';
import '../../../../../ui/components/metric_row.dart';
import '../../../../data/models/recommendation_dto.dart';

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
      final loadingText = petName != null
          ? '$petName에게 딱 맞는 사료 찾는 중...'
          : '분석 중...';
      
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '추천 준비 중',
            style: AppTypography.body,
          ),
          const SizedBox(height: 8),
          Text(
            '곧 맞춤 추천을 드릴게요!',
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
            label: '평균 대비',
            valueText: isCheaper
                ? '-${priceDiffPercent.toStringAsFixed(1)}%'
                : '+${priceDiffPercent.toStringAsFixed(1)}%',
            valueColor: isCheaper ? AppColors.positive : AppColors.negative,
            helperText: '최근 14일 기준',
          ),
        
        // '왜 추천?' 링크
        if (onWhyRecommended != null) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onWhyRecommended,
            child: Text(
              '왜 추천?',
              style: AppTypography.sub.copyWith(
                color: AppColors.primary,
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
