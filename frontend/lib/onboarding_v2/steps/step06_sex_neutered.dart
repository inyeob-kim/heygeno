import 'package:flutter/material.dart';
import '../onboarding_shell.dart';
import '../widgets/selection_card.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/app_spacing.dart';
import 'package:pet_food_app/l10n/app_localizations.dart';

/// Step 6: Sex & Neutered - DESIGN_GUIDE v1.0 준수
class Step06SexNeutered extends StatelessWidget {
  final String sex; // 'male' | 'female' | ''
  final bool? neutered; // true | false | null
  final ValueChanged<Map<String, dynamic>> onUpdate;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final int currentStep;
  final int totalSteps;

  const Step06SexNeutered({
    super.key,
    required this.sex,
    required this.neutered,
    required this.onUpdate,
    required this.onNext,
    required this.onBack,
    required this.currentStep,
    required this.totalSteps,
  });

  bool get isValid => sex.isNotEmpty && neutered != null;

  @override
  Widget build(BuildContext context) {
    return OnboardingShell(
      currentStep: currentStep,
      totalSteps: totalSteps,
      onBack: onBack,
      emoji: '✨',
      title: AppLocalizations.of(context)!.onboarding_step6_title,
      ctaText: AppLocalizations.of(context)!.common_next,
      ctaDisabled: !isValid,
      onCTAClick: onNext,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sex Section
          Text(
            AppLocalizations.of(context)!.onboarding_step6_sexLabel,
            style: AppTypography.small.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SelectionCard(
            selected: sex == 'male',
            onTap: () => onUpdate({'sex': 'male'}),
            emoji: '♂️',
            child: Text(
              AppLocalizations.of(context)!.onboarding_step6_male,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SelectionCard(
            selected: sex == 'female',
            onTap: () => onUpdate({'sex': 'female'}),
            emoji: '♀️',
            child: Text(
              AppLocalizations.of(context)!.onboarding_step6_female,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Neutered Section
          Text(
            AppLocalizations.of(context)!.onboarding_step6_neuteredLabel,
            style: AppTypography.small.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SelectionCard(
            selected: neutered == true,
            onTap: () => onUpdate({'neutered': true}),
            child: Text(
              AppLocalizations.of(context)!.onboarding_step6_neuteredYes,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SelectionCard(
            selected: neutered == false,
            onTap: () => onUpdate({'neutered': false}),
            child: Text(
              AppLocalizations.of(context)!.onboarding_step6_neuteredNo,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SelectionCard(
            selected: neutered == null,
            onTap: () => onUpdate({'neutered': null}),
            child: Text(
              AppLocalizations.of(context)!.onboarding_step6_neuteredUnknown,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
