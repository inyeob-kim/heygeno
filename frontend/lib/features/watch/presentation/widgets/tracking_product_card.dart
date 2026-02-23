import 'package:flutter/material.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../app/theme/app_colors.dart';
import '../controllers/watch_controller.dart';
import 'package:pet_food_app/l10n/app_localizations.dart';

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
      child: ClipRect(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
            Flexible(
              fit: FlexFit.loose,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 브랜드명
                    Text(
                      data.brandName,
                      style: AppTypography.caption.copyWith(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    // 제품명
                    Flexible(
                      child: Text(
                        data.title,
                        style: AppTypography.body2.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          height: 1.15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // 가격
                    Text(
                      data.price,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // 알림 상태
                    if (data.isAlertOn)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.notifications_active,
                              size: 11,
                              color: AppColors.primaryBlue,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                AppLocalizations.of(context)!.watch_alertOn,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primaryBlue,
                                  fontSize: 9,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
