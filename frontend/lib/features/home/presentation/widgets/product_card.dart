import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../data/models/recommendation_dto.dart';
import '../../../../../core/utils/price_formatter.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../app/theme/app_radius.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../ui/widgets/card_container.dart';

/// 상품 카드 (DESIGN_GUIDE.md 스타일)
class ProductCard extends StatelessWidget {
  final RecommendationItemDto item;

  const ProductCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final priceText = PriceFormatter.formatWithCurrency(item.currentPrice);
    final discountText = PriceFormatter.formatDiscountPercent(item.deltaPercent);
    final isNewLow = item.isNewLow;

    return CardContainer(
      padding: const EdgeInsets.all(AppSpacing.itemPadding),
      onTap: () {
        context.go('/products/${product.id}');
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상품 이미지 (placeholder)
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(AppRadius.media),
            ),
            child: const Icon(Icons.pets, size: 40, color: AppColors.textSecondary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상품명 (H3: 18px)
                Text(
                  product.productName,
                  style: AppTypography.h3,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // 브랜드명 (Body2: muted)
                Text(
                  product.brandName,
                  style: AppTypography.body2,
                ),
                if (product.sizeLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    product.sizeLabel!,
                    style: AppTypography.body2,
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    // 가격 (Body: bold)
                    Text(
                      priceText,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isNewLow ? AppColors.dangerRed : AppColors.textPrimary,
                      ),
                    ),
                    if (isNewLow || discountText.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.sm),
                      // 배지 (Badge: 13px, font-weight: 700)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.badgePaddingHorizontal,
                          vertical: AppSpacing.badgePaddingVertical,
                        ),
                        decoration: BoxDecoration(
                          color: isNewLow 
                              ? AppColors.dangerRed.withOpacity(0.1)
                              : AppColors.chipBackground,
                          borderRadius: BorderRadius.circular(AppRadius.badge),
                          border: Border.all(
                            color: isNewLow
                                ? AppColors.dangerRed.withOpacity(0.3)
                                : AppColors.primaryBorder,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          isNewLow ? '최저가!' : discountText,
                          style: AppTypography.badge.copyWith(
                            color: isNewLow ? AppColors.dangerRed : AppColors.chipText,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
