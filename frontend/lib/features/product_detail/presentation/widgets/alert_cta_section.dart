import 'package:flutter/material.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../design_system/components/button.dart';
import 'package:pet_food_app/l10n/app_localizations.dart';

/// 알림 받기 CTA 섹션
class AlertCtaSection extends StatelessWidget {
  final bool isTrackingCreated;
  final bool isTrackingLoading;
  final VoidCallback? onAlertTap;

  const AlertCtaSection({
    super.key,
    this.isTrackingCreated = false,
    this.isTrackingLoading = false,
    this.onAlertTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isTrackingCreated) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.positiveGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.positiveGreen,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.productDetailWidget_alertSet,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_down,
                color: AppColors.positiveGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.productDetailWidget_cheaperThanAverage,
                style: AppTypography.body1.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.productDetailWidget_dontMissPrice,
            style: AppTypography.body2.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: AppLocalizations.of(context)!.productDetailWidget_priceAlertGet,
            onPressed: isTrackingLoading ? null : onAlertTap,
          ),
        ],
      ),
    );
  }
}
