import 'package:flutter/material.dart';
import '../onboarding_shell.dart';
import '../widgets/selection_card.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/app_spacing.dart';

/// Step 3: Species - matches React Step3Species
class Step03Species extends StatelessWidget {
  final String value; // 'dog' | 'cat' | ''
  final ValueChanged<String> onUpdate;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final int currentStep;
  final int totalSteps;

  const Step03Species({
    super.key,
    required this.value,
    required this.onUpdate,
    required this.onNext,
    required this.onBack,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return OnboardingShell(
      currentStep: currentStep,
      totalSteps: totalSteps,
      onBack: onBack,
      emoji: '',
      title: '어떤 친구인가요?',
      ctaText: '다음',
      ctaDisabled: value.isEmpty,
      onCTAClick: onNext,
      child: Column(
        children: [
          SelectionCard(
            selected: value == 'dog',
            onTap: () => onUpdate('dog'),
            emoji: '🐶',
            child: Text(
              '강아지',
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SelectionCard(
            selected: value == 'cat',
            onTap: () => onUpdate('cat'),
            emoji: '🐱',
            child: Text(
              '고양이',
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
