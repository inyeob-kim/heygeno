import 'package:flutter/material.dart';
import '../onboarding_shell.dart';
import '../widgets/toss_text_input.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/app_spacing.dart';
import 'package:pet_food_app/l10n/app_localizations.dart';

/// Step 7: Weight - DESIGN_GUIDE v1.0 준수
class Step07Weight extends StatelessWidget {
  final String value;
  final ValueChanged<String> onUpdate;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final int currentStep;
  final int totalSteps;

  const Step07Weight({
    super.key,
    required this.value,
    required this.onUpdate,
    required this.onNext,
    required this.onBack,
    required this.currentStep,
    required this.totalSteps,
  });

  bool get isValid {
    final weight = double.tryParse(value.trim());
    return weight != null && weight >= 0.1 && weight <= 99.9;
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingShell(
      currentStep: currentStep,
      totalSteps: totalSteps,
      onBack: onBack,
      emoji: '⚖️',
      title: AppLocalizations.of(context)!.onboarding_step7_title,
      subtitle: AppLocalizations.of(context)!.onboarding_step7_subtitle,
      ctaText: AppLocalizations.of(context)!.common_next,
      ctaDisabled: !isValid,
      onCTAClick: onNext,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.onboarding_step7_label,
            style: AppTypography.small.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TossTextInput(
            value: value,
            onChanged: onUpdate,
            placeholder: '0.0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppLocalizations.of(context)!.onboarding_step7_hint,
            style: AppTypography.small,
          ),
        ],
      ),
    );
  }
}
