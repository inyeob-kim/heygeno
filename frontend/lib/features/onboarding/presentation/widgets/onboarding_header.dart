import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../data/models/onboarding_step.dart';
import 'progress_bar.dart';

/// 온보딩 헤더 (진행률 + 뒤로가기)
class OnboardingHeader extends StatelessWidget {
  final OnboardingStep currentStep;
  final VoidCallback? onBack;
  final bool showBackButton;

  const OnboardingHeader({
    super.key,
    required this.currentStep,
    this.onBack,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.md,
        ),
        child: Column(
          children: [
            // 진행률 바
            ProgressBar(progress: currentStep.progress),
            const SizedBox(height: AppSpacing.md),
            // 뒤로가기 버튼 (첫 화면 제외)
            if (showBackButton && currentStep.stepNumber > 1)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onBack?.call();
                    },
                    color: AppColors.textPrimary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
