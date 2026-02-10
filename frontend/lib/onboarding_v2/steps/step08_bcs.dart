import 'package:flutter/material.dart';
import '../onboarding_shell.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/app_spacing.dart';

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

  String getBCSLabel(int score) {
    if (score <= 3) return '조금 마른 편이에요';
    if (score <= 6) return '딱 좋아요!';
    return '조금 관리해볼까요?';
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingShell(
      currentStep: currentStep,
      totalSteps: totalSteps,
      onBack: onBack,
      emoji: '🧡',
      title: '체형은 어느 쪽에 가까울까요?',
      ctaText: '다음',
      onCTAClick: onNext,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$value',
                style: AppTypography.h1Mobile.copyWith(
                  color: AppColors.primaryBlue,
                ),
              ),
              Text(
                getBCSLabel(value),
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primaryBlue,
              inactiveTrackColor: AppColors.divider,
              thumbColor: AppColors.primaryBlue,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              trackHeight: 4,
            ),
            child: Slider(
              value: value.toDouble(),
              min: 1,
              max: 9,
              divisions: 8,
              onChanged: (val) => onUpdate(val.toInt()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '마른 편',
                style: AppTypography.small.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '통통한 편',
                style: AppTypography.small.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
