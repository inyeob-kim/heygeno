import 'package:flutter/material.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../app/theme/app_colors.dart';
import '../controllers/watch_controller.dart';

/// 추적 상품 카드 위젯
class TrackingProductCard extends StatelessWidget {
  final TrackingProductData data;
  final VoidCallback? onTap;

  const TrackingProductCard({
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
        children: [
          // 상품 이미지
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: const Color(0xFFF7F8FA),
                child: const Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 40,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          ),
          // 텍스트 영역
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
                  data.title,
                  style: AppTypography.body2.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // 가격
                Text(
                  data.price,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                // 알림 상태
                if (data.isAlertOn)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_active,
                          size: 12,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '알림 켜짐',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primaryBlue,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
