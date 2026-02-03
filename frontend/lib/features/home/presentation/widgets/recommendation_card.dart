import 'package:flutter/material.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../app/theme/app_radius.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../ui/widgets/card_container.dart';
import '../../../../data/models/recommendation_dto.dart';

/// 추천 Top1 카드 (로딩/데이터 상태)
class RecommendationCard extends StatelessWidget {
  final RecommendationItemDto? topRecommendation;
  final bool isLoading;
  final String? petName;

  const RecommendationCard({
    super.key,
    this.topRecommendation,
    this.isLoading = false,
    this.petName,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      final loadingText = petName != null
          ? '$petName에게 딱 맞는 사료 찾는 중...'
          : '분석 중...';
      
      return CardContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loadingText,
              style: AppTypography.h3,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildSkeleton(),
          ],
        ),
      );
    }

    if (topRecommendation == null) {
      return CardContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '추천 준비 중',
              style: AppTypography.h3,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '곧 맞춤 추천을 드릴게요!',
              style: AppTypography.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final product = topRecommendation!.product;
    final deltaPercent = topRecommendation!.deltaPercent;

    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 브랜드/상품명 + 왜 추천? 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${product.brandName} ${product.productName}',
                  style: AppTypography.h3,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: 추천 근거 상세 모달 표시
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('추천 근거: 알레르기 제외, 나이/체중 반영, 최저가'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '왜 추천?',
                  style: AppTypography.small.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          
          // 가격 정보
          Row(
            children: [
              Text(
                '${topRecommendation!.currentPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (deltaPercent != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  deltaPercent < 0 
                    ? '${deltaPercent.toStringAsFixed(1)}% ↓'
                    : '+${deltaPercent.toStringAsFixed(1)}% ↑',
                  style: AppTypography.body2.copyWith(
                    color: deltaPercent < 0 
                      ? AppColors.positiveGreen 
                      : AppColors.dangerRed,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: [
        Container(
          height: 16,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          height: 16,
          width: 200,
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
        ),
      ],
    );
  }
}
