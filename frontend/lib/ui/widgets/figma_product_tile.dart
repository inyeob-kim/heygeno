import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/theme/app_typography.dart';
import '../../core/utils/price_formatter.dart';

/// Figma 디자인 기반 Product Tile 위젯
class FigmaProductTile extends StatelessWidget {
  final ProductTileData product;
  final VoidCallback onTap;
  final ProductTileLayout layout;

  const FigmaProductTile({
    super.key,
    required this.product,
    required this.onTap,
    this.layout = ProductTileLayout.grid,
  });

  int _calculateDiscount() {
    if (product.comparePrice == null) return 0;
    return ((product.comparePrice! - product.price) / product.comparePrice! * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final discount = _calculateDiscount();

    if (layout == ProductTileLayout.horizontal) {
      return GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 140,
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: CachedNetworkImage(
                          imageUrl: product.image,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFFF7F8FA),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFFF7F8FA),
                            child: const Icon(Icons.error),
                          ),
                        ),
                      ),
                      if (product.isWatched)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.favorite,
                              size: 16,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Brand
              Text(
                product.brand,
                style: AppTypography.small.copyWith(
                  color: const Color(0xFF6B7280),
                  fontSize: 10,
                  height: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              // Name
              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111827),
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              // Price
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (discount > 0) ...[
                    Text(
                      '$discount%',
                      style: AppTypography.small.copyWith(
                        color: const Color(0xFFEF4444),
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      '${PriceFormatter.format(product.price)}원',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                        height: 1.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Grid layout
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: CachedNetworkImage(
                      imageUrl: product.image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context, url) => Container(
                        color: const Color(0xFFF7F8FA),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFFF7F8FA),
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
                  if (product.isWatched)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          size: 16,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Brand
          Text(
            product.brand,
            style: AppTypography.small.copyWith(
              color: const Color(0xFF6B7280),
              fontSize: 10,
              height: 1.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          // Name
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111827),
              height: 1.1,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // Price
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (discount > 0) ...[
                Text(
                  '$discount%',
                  style: AppTypography.small.copyWith(
                    color: const Color(0xFFEF4444),
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  '${PriceFormatter.format(product.price)}원',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum ProductTileLayout {
  grid,
  horizontal,
}

class ProductTileData {
  final String id;
  final String name;
  final String brand;
  final int price;
  final int? comparePrice;
  final int? avgPrice;
  final int? matchScore;
  final String? badge;
  final List<String>? matchReasons;
  final String image;
  final bool isWatched;
  final String? protein;
  final String? fat;
  final String? fiber;

  ProductTileData({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    this.comparePrice,
    this.avgPrice,
    this.matchScore,
    this.badge,
    this.matchReasons,
    required this.image,
    this.isWatched = false,
    this.protein,
    this.fat,
    this.fiber,
  });
}
