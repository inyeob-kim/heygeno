import 'package:flutter/material.dart';
import '../onboarding_shell.dart';
import '../widgets/toss_text_input.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/app_spacing.dart';
import 'package:pet_food_app/l10n/app_localizations.dart';

/// Step 2: Pet Name - matches React Step2PetName
class Step02PetName extends StatelessWidget {
  final String value;
  final ValueChanged<String> onUpdate;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final int currentStep;
  final int totalSteps;

  const Step02PetName({
    super.key,
    required this.value,
    required this.onUpdate,
    required this.onNext,
    required this.onBack,
    required this.currentStep,
    required this.totalSteps,
  });

  bool get isValid => value.length >= 1 && value.length <= 20;

  @override
  Widget build(BuildContext context) {
    return OnboardingShell(
      currentStep: currentStep,
      totalSteps: totalSteps,
      onBack: onBack,
      emoji: '🐾',
      title: AppLocalizations.of(context)!.onboarding_step2_title,
      ctaText: AppLocalizations.of(context)!.common_next,
      ctaDisabled: !isValid,
      onCTAClick: onNext,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.onboarding_step2_label,
            style: AppTypography.small.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TossTextInput(
            value: value,
            onChanged: onUpdate,
            placeholder: AppLocalizations.of(context)!.onboarding_step2_placeholder,
            maxLength: 20,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppLocalizations.of(context)!.onboarding_step2_hint,
            style: AppTypography.small,
          ),
        ],
      ),
    );
  }
}
