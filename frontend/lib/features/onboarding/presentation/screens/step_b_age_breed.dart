import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../data/models/onboarding_step.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/emoji_icon.dart';
import '../widgets/onboarding_footer.dart';
import '../widgets/onboarding_header.dart';
import '../widgets/breed_chip.dart';

/// Step 5: 품종 (강아지만)
class StepBreedScreen extends ConsumerStatefulWidget {
  const StepBreedScreen({super.key});

  @override
  ConsumerState<StepBreedScreen> createState() =>
      _StepBreedScreenState();
}

class _StepBreedScreenState extends ConsumerState<StepBreedScreen> {
  String? _breedCode;

  // 인기 품종
  static const List<String> _popularBreeds = [
    '골든리트리버', '말티즈', '푸들', '비글', '치와와',
    '포메라니안', '요크셔테리어', '시츄', '웰시코기', '보더콜리',
  ];
  static const List<String> _allBreeds = [
    ..._popularBreeds,
    '래브라도리트리버', '허스키', '불독', '도베르만', '로트와일러',
    '저먼셰퍼드', '불테리어', '잭러셀테리어', '미니어처슈나우저', '닥스훈트',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(onboardingControllerProvider);
      // 강아지가 아니면 이 화면을 건너뛰어야 함
      if (state.profile.species != 'DOG') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(onboardingControllerProvider.notifier).nextStep();
        });
        return;
      }
      
      if (state.profile.breedCode != null) {
        setState(() {
          _breedCode = state.profile.breedCode;
        });
      }
    });
  }

  void _onBreedSelected(String breed) {
    HapticFeedback.lightImpact();
    setState(() {
      _breedCode = breed;
    });
    
    final profile = ref.read(onboardingControllerProvider).profile;
    ref.read(onboardingControllerProvider.notifier).saveProfile(
          profile.copyWith(breedCode: breed),
        );
  }

  Future<void> _onNext() async {
    if (_breedCode == null) return;

    HapticFeedback.lightImpact();
    await ref.read(onboardingControllerProvider.notifier).nextStep();
  }

  void _onBack() {
    HapticFeedback.lightImpact();
    ref.read(onboardingControllerProvider.notifier).previousStep();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.read(onboardingControllerProvider);
    // 강아지가 아니면 이 화면을 건너뛰어야 함
    if (state.profile.species != 'DOG') {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            OnboardingHeader(
              currentStep: OnboardingStep.breed,
              onBack: _onBack,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePaddingHorizontal,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xxl),
                    const EmojiIcon(emoji: '🐶', size: 80),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      '어떤 품종인가요? 🐶',
                      style: AppTypography.h2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    // 검색 바
                    TextField(
                      decoration: InputDecoration(
                        hintText: '품종 검색 (예: 골든리트리버)',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.search),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                      ),
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // 인기 품종 섹션
                    Text(
                      '인기 품종',
                      style: AppTypography.h3,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _popularBreeds
                          .map((breed) => BreedChip(
                                label: breed,
                                isSelected: _breedCode == breed,
                                onTap: () => _onBreedSelected(breed),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // 전체 품종 섹션
                    Text(
                      '전체 품종',
                      style: AppTypography.h3,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _allBreeds
                          .map((breed) => BreedChip(
                                label: breed,
                                isSelected: _breedCode == breed,
                                onTap: () => _onBreedSelected(breed),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // 특수 옵션
                    BreedChip(
                      label: '믹스/잘 모르겠어요',
                      isSelected: _breedCode == 'mix',
                      onTap: () => _onBreedSelected('mix'),
                    ),
                  ],
                ),
              ),
            ),
            OnboardingFooter(
              buttonText: '다음',
              onPressed: _breedCode != null ? _onNext : null,
              isEnabled: _breedCode != null,
            ),
          ],
        ),
      ),
    );
  }
}
