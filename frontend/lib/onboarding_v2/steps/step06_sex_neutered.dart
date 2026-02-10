import 'package:flutter/material.dart';
import '../onboarding_shell.dart';
import '../widgets/selection_card.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/app_spacing.dart';

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
      title: '성별과 중성화 정보를 알려주세요',
      ctaText: '다음',
      ctaDisabled: !isValid,
      onCTAClick: onNext,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sex Section
          Text(
            '성별',
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
              '남아',
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
              '여아',
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Neutered Section
          Text(
            '중성화',
            style: AppTypography.small.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SelectionCard(
            selected: neutered == true,
            onTap: () => onUpdate({'neutered': true}),
            child: Text(
              '했어요',
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
              '안 했어요',
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
              '잘 모르겠어요',
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
