import 'package:flutter/material.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../design_system/components/app_card.dart';
import 'package:pet_food_app/l10n/app_localizations.dart';

/// 진행 힌트 카드 (로딩 중 신뢰 구축)
class ProgressHintCard extends StatelessWidget {
  const ProgressHintCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.home_analyzing,
            style: AppTypography.h3,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildHintItem(context, '✔', AppLocalizations.of(context)!.home_allergyExcluded, true),
          const SizedBox(height: AppSpacing.sm),
          _buildHintItem(context, '✔', AppLocalizations.of(context)!.home_ageWeightReflected, true),
          const SizedBox(height: AppSpacing.sm),
          _buildHintItem(context, '⏳', AppLocalizations.of(context)!.home_priceTrackingPreparing, false),
        ],
      ),
    );
  }

  Widget _buildHintItem(BuildContext context, String icon, String text, bool isCompleted) {
    return Row(
      children: [
        Text(
          icon,
          style: AppTypography.body,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          text,
          style: AppTypography.body2.copyWith(
            color: isCompleted
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
