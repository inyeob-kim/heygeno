import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../data/models/onboarding_step.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/emoji_icon.dart';
import '../widgets/onboarding_footer.dart';
import '../widgets/onboarding_header.dart';
import '../widgets/species_card.dart';

/// Step 3: 종 선택
class StepSpeciesScreen extends ConsumerStatefulWidget {
  const StepSpeciesScreen({super.key});

  @override
  ConsumerState<StepSpeciesScreen> createState() =>
      _StepSpeciesScreenState();
}

class _StepSpeciesScreenState extends ConsumerState<StepSpeciesScreen> {
  String? _selectedSpecies;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(onboardingControllerProvider);
      if (state.profile.species != null) {
        setState(() {
          _selectedSpecies = state.profile.species == 'DOG' ? 'dog' : 'cat';
        });
      }
    });
  }

  void _onSpeciesSelected(String species) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedSpecies = species;
    });
    
    // 서버 형식으로 변환
    final serverSpecies = species == 'dog' ? 'DOG' : 'CAT';
    final profile = ref.read(onboardingControllerProvider).profile;
    ref.read(onboardingControllerProvider.notifier).saveProfile(
          profile.copyWith(species: serverSpecies),
        );
  }

  Future<void> _onNext() async {
    if (_selectedSpecies == null) return;

    HapticFeedback.lightImpact();
    await ref.read(onboardingControllerProvider.notifier).nextStep();
  }

  void _onBack() {
    HapticFeedback.lightImpact();
    ref.read(onboardingControllerProvider.notifier).previousStep();
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _selectedSpecies != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            OnboardingHeader(
              currentStep: OnboardingStep.species,
              onBack: _onBack,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePaddingHorizontal,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.xxl),
                    const EmojiIcon(emoji: '🐶🐱', size: 80),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      '어떤 친구인가요? 🐶🐱',
                      style: AppTypography.h2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Row(
                      children: [
                        Expanded(
                          child: SpeciesCard(
                            emoji: '🐶',
                            label: '강아지',
                            isSelected: _selectedSpecies == 'dog',
                            onTap: () => _onSpeciesSelected('dog'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: SpeciesCard(
                            emoji: '🐱',
                            label: '고양이',
                            isSelected: _selectedSpecies == 'cat',
                            onTap: () => _onSpeciesSelected('cat'),
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
              onPressed: isValid ? _onNext : null,
              isEnabled: isValid,
            ),
          ],
        ),
      ),
    );
  }
}
