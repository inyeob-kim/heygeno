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
import '../widgets/sex_card.dart';
import '../widgets/neutered_card.dart';

/// Step C: 성별 + 중성화
class StepCSexNeuteredScreen extends ConsumerStatefulWidget {
  const StepCSexNeuteredScreen({super.key});

  @override
  ConsumerState<StepCSexNeuteredScreen> createState() =>
      _StepCSexNeuteredScreenState();
}

class _StepCSexNeuteredScreenState
    extends ConsumerState<StepCSexNeuteredScreen> {
  String? _selectedSex; // 'MALE' | 'FEMALE'
  bool? _isNeutered; // true | false | null (null = 모름, 기본)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(onboardingControllerProvider);
      final profile = state.profile;
      
      if (profile.sex != null) {
        setState(() {
          _selectedSex = profile.sex;
        });
      }
      if (profile.isNeutered != null) {
        setState(() {
          _isNeutered = profile.isNeutered;
        });
      }
    });
  }

  void _onSexSelected(String sex) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedSex = sex;
    });
    
    final profile = ref.read(onboardingControllerProvider).profile;
    ref.read(onboardingControllerProvider.notifier).saveProfile(
          profile.copyWith(sex: sex),
        );
  }

  void _onNeuteredSelected(bool? value) {
    HapticFeedback.lightImpact();
    setState(() {
      _isNeutered = value;
    });
    
    final profile = ref.read(onboardingControllerProvider).profile;
    ref.read(onboardingControllerProvider.notifier).saveProfile(
          profile.copyWith(isNeutered: value),
        );
  }

  Future<void> _onNext() async {
    if (_selectedSex == null) return;

    HapticFeedback.lightImpact();
    
    // 명시적으로 저장 (안전을 위해)
    final profile = ref.read(onboardingControllerProvider).profile;
    await ref.read(onboardingControllerProvider.notifier).saveProfile(
          profile.copyWith(
            sex: _selectedSex,
            isNeutered: _isNeutered,
          ),
        );
    
    await ref.read(onboardingControllerProvider.notifier).nextStep();
  }

  void _onBack() {
    HapticFeedback.lightImpact();
    ref.read(onboardingControllerProvider.notifier).previousStep();
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _selectedSex != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            OnboardingHeader(
              currentStep: OnboardingStep.sexNeutered,
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
                    const EmojiIcon(emoji: '✨', size: 80),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      '성별과 중성화 정보를 알려주세요 ✨',
                      style: AppTypography.h2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    // 성별 섹션
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '성별',
                        style: AppTypography.h3,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: SexCard(
                            emoji: '♂️',
                            label: '남아',
                            isSelected: _selectedSex == 'MALE',
                            onTap: () => _onSexSelected('MALE'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: SexCard(
                            emoji: '♀️',
                            label: '여아',
                            isSelected: _selectedSex == 'FEMALE',
                            onTap: () => _onSexSelected('FEMALE'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // 중성화 섹션
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '중성화',
                        style: AppTypography.h3,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: NeuteredCard(
                            label: '했어요',
                            isSelected: _isNeutered == true,
                            onTap: () => _onNeuteredSelected(true),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: NeuteredCard(
                            label: '안 했어요',
                            isSelected: _isNeutered == false,
                            onTap: () => _onNeuteredSelected(false),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: NeuteredCard(
                            label: '잘 모르겠어요',
                            isSelected: _isNeutered == null,
                            onTap: () => _onNeuteredSelected(null),
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
