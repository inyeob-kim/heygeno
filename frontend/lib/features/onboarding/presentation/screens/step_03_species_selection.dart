import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/onboarding_header.dart';
import '../widgets/onboarding_footer.dart';
import '../widgets/emoji_icon.dart';
import '../widgets/species_card.dart';
import '../../data/models/onboarding_step.dart';

/// Step 3: 종 선택
class Step03SpeciesSelectionScreen extends ConsumerWidget {
  const Step03SpeciesSelectionScreen({super.key});

  void _onNext(WidgetRef ref, String species) {
    HapticFeedback.lightImpact();
    final profile = ref.read(onboardingControllerProvider).profile;
    ref.read(onboardingControllerProvider.notifier).saveProfile(
          profile.copyWith(species: species),
        );
    ref.read(onboardingControllerProvider.notifier).nextStep();
  }

  void _onBack(WidgetRef ref) {
    HapticFeedback.lightImpact();
    ref.read(onboardingControllerProvider.notifier).previousStep();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final selectedSpecies = state.profile.species;
    final isValid = selectedSpecies != null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            OnboardingHeader(
              currentStep: OnboardingStep.species,
              onBack: () => _onBack(ref),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.xxl),
                    const EmojiIcon(emoji: '🐶🐱', size: 80),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      '어떤 친구인가요? 🐶🐱',
                      style: AppTypography.title,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    // 종 선택 카드
                    Row(
                      children: [
                        Expanded(
                          child: SpeciesCard(
                            emoji: '🐶',
                            label: '강아지',
                            isSelected: selectedSpecies == 'dog',
                            onTap: () => _onNext(ref, 'dog'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: SpeciesCard(
                            emoji: '🐱',
                            label: '고양이',
                            isSelected: selectedSpecies == 'cat',
                            onTap: () => _onNext(ref, 'cat'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            OnboardingFooter(
              buttonText: '다음',
              onPressed: isValid ? () => _onNext(ref, selectedSpecies) : null,
              isEnabled: isValid,
            ),
          ],
        ),
      ),
    );
  }
}
