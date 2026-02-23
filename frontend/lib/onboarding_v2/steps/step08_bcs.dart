import 'package:flutter/material.dart';
import '../onboarding_shell.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_radius.dart';
import 'package:pet_food_app/l10n/app_localizations.dart';

/// Step 8: BCS - DESIGN_GUIDE v1.0 준수
class Step08BCS extends StatelessWidget {
  final int value;
  final ValueChanged<int> onUpdate;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final int currentStep;
  final int totalSteps;

  const Step08BCS({
    super.key,
    required this.value,
    required this.onUpdate,
    required this.onNext,
    required this.onBack,
    required this.currentStep,
    required this.totalSteps,
  });

  String getBCSLabel(BuildContext context, int score) {
    if (score <= 3) return AppLocalizations.of(context)!.onboarding_step8_bcsThin;
    if (score <= 6) return AppLocalizations.of(context)!.onboarding_step8_bcsGood;
    return AppLocalizations.of(context)!.onboarding_step8_bcsOverweight;
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingShell(
      currentStep: currentStep,
      totalSteps: totalSteps,
      onBack: onBack,
      emoji: '🧡',
      title: AppLocalizations.of(context)!.onboarding_step8_title,
      ctaText: AppLocalizations.of(context)!.common_next,
      onCTAClick: onNext,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BCS Score Display (design.mdc: Hero Section 스타일)
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BCS',
                      style: AppTypography.small.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '$value',
                      style: AppTypography.h2.copyWith(
                        fontSize: 32,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLighter,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    getBCSLabel(context, value),
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          // Slider (design.mdc: 더 세련된 스타일)
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primaryLight,
              thumbColor: AppColors.primary,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              trackHeight: 6,
              valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
              valueIndicatorColor: AppColors.primary,
              valueIndicatorTextStyle: AppTypography.small.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Slider(
              value: value.toDouble(),
              min: 1,
              max: 9,
              divisions: 8,
              label: '$value',
              onChanged: (val) => onUpdate(val.toInt()),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.onboarding_step8_sliderThin,
                style: AppTypography.small.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                AppLocalizations.of(context)!.onboarding_step8_sliderOverweight,
                style: AppTypography.small.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
