import 'package:flutter/material.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/utils/price_formatter.dart';

/// 상품 카드 데이터 모델
class ProductCardData {
  final String id;
  final String brandName;
  final String productName;
  final String? imageUrl;
  final int price;
  final int? originalPrice;
  final double? discountRate;

  ProductCardData({
    required this.id,
    required this.brandName,
    required this.productName,
    this.imageUrl,
    required this.price,
    this.originalPrice,
    this.discountRate,
  });
}

/// 상품 카드 위젯 (가로/그리드 공통)
class ProductCard extends StatelessWidget {
  final ProductCardData data;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.data,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상품 이미지 (이미지 중심 타일)
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return SizedBox(
                width: width,
                height: width, // 1:1 비율
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: data.imageUrl != null
                      ? Image.network(
                          data.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholder();
                          },
                        )
                      : _buildPlaceholder(),
                ),
              );
            },
          ),
          // 텍스트 영역 (Padding top 10)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 브랜드명
                Text(
                  data.brandName,
                  style: AppTypography.caption.copyWith(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                // 제품명
                Text(
                  data.productName,
                  style: AppTypography.body2.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 1.2, // line height 줄임
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // 가격 (검정 bold, 파란색 금지)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                      Text(
                        PriceFormatter.formatWithCurrency(data.price),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                    if (data.discountRate != null && data.discountRate! > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '-${data.discountRate!.toInt()}%',
                        style: TextStyle(
                          color: AppColors.dangerRed,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.image_outlined,
        size: 40,
        color: Colors.grey.shade400,
      ),
    );
  }

}
