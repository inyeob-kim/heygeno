import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../data/models/onboarding_step.dart';
import '../../data/models/pet_profile_draft.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/emoji_icon.dart';
import '../widgets/onboarding_footer.dart';
import '../widgets/onboarding_header.dart';

/// Step 7: 몸무게
class StepWeightScreen extends ConsumerStatefulWidget {
  const StepWeightScreen({super.key});

  @override
  ConsumerState<StepWeightScreen> createState() =>
      _StepWeightScreenState();
}

class _StepWeightScreenState extends ConsumerState<StepWeightScreen> {
  double? _weightKg;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(onboardingControllerProvider);
      final profile = state.profile;
      
      // 기본값 설정
      final defaultWeight = _getDefaultWeight(state.profile);
      _weightKg = profile.weightKg ?? defaultWeight;
      
      // 기본값이 설정되었고 프로필에 저장되지 않았다면 저장
      if (profile.weightKg == null) {
        ref.read(onboardingControllerProvider.notifier).saveProfile(
              profile.copyWith(weightKg: defaultWeight),
            );
      }
      
      setState(() {});
    });
  }

  double _getDefaultWeight(PetProfileDraft profile) {
    // 종/나이 기반 추정값
    if (profile.species == 'DOG') {
      return 10.0; // 중형견 기본값
    } else {
      return 4.0; // 고양이 기본값
    }
  }

  void _onWeightChanged(double weight) {
    HapticFeedback.lightImpact();
    setState(() {
      _weightKg = weight;
    });
    
    final profile = ref.read(onboardingControllerProvider).profile;
    ref.read(onboardingControllerProvider.notifier).saveProfile(
          profile.copyWith(weightKg: weight),
        );
  }

  void _onQuickAdjust(double delta) {
    if (_weightKg == null) {
      _onWeightChanged(3.0 + delta);
    } else {
      final newWeight = (_weightKg! + delta).clamp(0.1, 99.9);
      _onWeightChanged(newWeight);
    }
  }

  Future<void> _onNext() async {
    if (_weightKg == null || _weightKg! <= 0) return;

    HapticFeedback.lightImpact();
    
    // 명시적으로 저장 (안전을 위해)
    final profile = ref.read(onboardingControllerProvider).profile;
    await ref.read(onboardingControllerProvider.notifier).saveProfile(
          profile.copyWith(weightKg: _weightKg),
        );
    
    await ref.read(onboardingControllerProvider.notifier).nextStep();
  }

  void _onBack() {
    HapticFeedback.lightImpact();
    ref.read(onboardingControllerProvider.notifier).previousStep();
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _weightKg != null && _weightKg! > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            OnboardingHeader(
              currentStep: OnboardingStep.weight,
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
                    const EmojiIcon(emoji: '⚖️', size: 80),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      '몸무게는 얼마인가요? ⚖️',
                      style: AppTypography.h2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '최근 측정 기준이면 좋아요',
                      style: AppTypography.lead,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    // 몸무게 표시
                    AnimatedScale(
                      scale: _weightKg != null ? 1.0 : 0.8,
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _weightKg != null ? '${_weightKg!.toStringAsFixed(1)}kg' : '0.0kg',
                        style: AppTypography.h1.copyWith(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // 빠른 조절 버튼
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          iconSize: 32,
                          onPressed: () => _onQuickAdjust(-0.1),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          iconSize: 32,
                          onPressed: () => _onQuickAdjust(0.1),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // 슬라이더
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      child: Column(
                        children: [
                          Slider(
                            value: _weightKg ?? 3.0,
                            min: 0.1,
                            max: 99.9,
                            divisions: 998,
                            onChanged: _onWeightChanged,
                            activeColor: AppColors.primaryBlue,
                          ),
                        ],
                      ),
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

