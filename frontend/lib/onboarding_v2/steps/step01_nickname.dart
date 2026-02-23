import 'package:flutter/material.dart';
import '../onboarding_shell.dart';
import '../widgets/toss_text_input.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/app_spacing.dart';
import 'package:pet_food_app/l10n/app_localizations.dart';

/// Step 1: Nickname - matches React Step1Nickname
class Step01Nickname extends StatelessWidget {
  final String value;
  final ValueChanged<String> onUpdate;
  final VoidCallback onNext;
  final int currentStep;
  final int totalSteps;

  const Step01Nickname({
    super.key,
    required this.value,
    required this.onUpdate,
    required this.onNext,
    required this.currentStep,
    required this.totalSteps,
  });

  bool get isValid => value.length >= 2 && value.length <= 12;

  @override
  Widget build(BuildContext context) {
    return OnboardingShell(
      currentStep: currentStep,
      totalSteps: totalSteps,
      emoji: '', // 이모지 제거
      title: AppLocalizations.of(context)!.onboarding_step1_title,
      subtitle: AppLocalizations.of(context)!.onboarding_step1_subtitle,
      ctaText: AppLocalizations.of(context)!.common_next,
      ctaDisabled: !isValid,
      onCTAClick: onNext,
      leadingWidget: Image.asset(
        'assets/images/logo/heygeno-logo.png',
        height: 80,
        fit: BoxFit.contain,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.onboarding_step1_label,
            style: AppTypography.small.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TossTextInput(
            value: value,
            onChanged: onUpdate,
            placeholder: AppLocalizations.of(context)!.onboarding_step1_placeholder,
            maxLength: 12,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppLocalizations.of(context)!.onboarding_step1_hint,
            style: AppTypography.small,
          ),
        ],
      ),
    );
  }
}
