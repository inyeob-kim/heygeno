import 'package:flutter/material.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_radius.dart';
import '../../../../../core/utils/price_formatter.dart';
import 'package:pet_food_app/l10n/app_localizations.dart';

/// 상품 Hero 영역 (카드 없이 깔끔하게)
class ProductHeroSection extends StatelessWidget {
  final String productName;
  final String brandName;
  final String? sizeLabel;
  final String? imageUrl;
  final int? currentPrice;
  final int? averagePrice;
  final bool isGoodPrice; // "우리 아이에게 좋은 가격이에요" 표시 여부

  const ProductHeroSection({
    super.key,
    required this.productName,
    required this.brandName,
    this.sizeLabel,
    this.imageUrl,
    this.currentPrice,
    this.averagePrice,
    this.isGoodPrice = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상품 이미지 (크게)
        Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(AppRadius.media),
          ),
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.media),
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                  ),
                )
              : _buildPlaceholder(),
        ),
        const SizedBox(height: 24),
        
        // 제품명
        Text(
          productName,
          style: AppTypography.h2.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 8),
        
        // 브랜드 · 사이즈
        Row(
          children: [
            Text(
              brandName,
              style: AppTypography.body1.copyWith(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            if (sizeLabel != null) ...[
              Text(
                ' · ',
                style: AppTypography.body1.copyWith(
                  color: Colors.grey.shade400,
                ),
              ),
              Text(
                sizeLabel!,
                style: AppTypography.body1.copyWith(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),
        
        // 가격 + 상태 문장
        if (currentPrice != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                PriceFormatter.formatWithCurrency(currentPrice!),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              if (averagePrice != null && averagePrice! > currentPrice!)
                Text(
                  AppLocalizations.of(context)!.productDetailWidget_averageLast14Days(PriceFormatter.formatWithCurrency(averagePrice!)),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
          if (averagePrice != null && averagePrice! > currentPrice!) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.arrow_downward,
                  size: 16,
                  color: AppColors.positiveGreen,
                ),
                const SizedBox(width: 4),
                Text(
                  AppLocalizations.of(context)!.productDetailWidget_cheaperBy(PriceFormatter.formatWithCurrency(averagePrice! - currentPrice!)),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.positiveGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          if (isGoodPrice) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.positiveGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppColors.positiveGreen,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context)!.productDetailWidget_goodPriceForPet,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.positiveGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.image_outlined,
        size: 80,
        color: Colors.grey.shade400,
      ),
    );
  }

}
