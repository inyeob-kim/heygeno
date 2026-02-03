import 'package:flutter/material.dart';
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

/// Step 8: 체형 (BCS)
class StepBodyConditionScreen extends ConsumerStatefulWidget {
  const StepBodyConditionScreen({super.key});

  @override
  ConsumerState<StepBodyConditionScreen> createState() =>
      _StepBodyConditionScreenState();
}

class _StepBodyConditionScreenState
    extends ConsumerState<StepBodyConditionScreen> {
  int? _bcs;
  bool _showHeartPop = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(onboardingControllerProvider);
      if (state.profile.bodyConditionScore != null) {
        setState(() {
          _bcs = state.profile.bodyConditionScore;
        });
      } else {
        // 기본값: 5
        setState(() {
          _bcs = 5;
        });
        final profile = ref.read(onboardingControllerProvider).profile;
        ref.read(onboardingControllerProvider.notifier).saveProfile(
              profile.copyWith(bodyConditionScore: 5),
            );
      }
    });
  }

  void _onBcsChanged(double value) {
    final newBcs = value.round();
    if (_bcs == null) {
      setState(() {
        _showHeartPop = true;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _showHeartPop = false;
          });
        }
      });
    }
    
    HapticFeedback.lightImpact();
    setState(() {
      _bcs = newBcs;
    });
    
    final profile = ref.read(onboardingControllerProvider).profile;
    ref.read(onboardingControllerProvider.notifier).saveProfile(
          profile.copyWith(bodyConditionScore: newBcs),
        );
  }

  Future<void> _onNext() async {
    if (_bcs == null) return;

    HapticFeedback.lightImpact();
    await ref.read(onboardingControllerProvider.notifier).nextStep();
  }

  void _onBack() {
    HapticFeedback.lightImpact();
    ref.read(onboardingControllerProvider.notifier).previousStep();
  }

  String _getFeedbackText() {
    if (_bcs == null) return '';
    if (_bcs! <= 3) return '조금 마른 편이에요';
    if (_bcs! <= 6) return '딱 좋아요! 💚';
    return '조금 관리해볼까요?';
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _bcs != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            OnboardingHeader(
              currentStep: OnboardingStep.bodyCondition,
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
                    const EmojiIcon(emoji: '🧡', size: 80),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      '체형은 어느 쪽에 가까울까요? 🧡',
                      style: AppTypography.h2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    // 캐릭터 애니메이션 영역
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                          ),
                          child: Center(
                            child: _buildCharacterSilhouette(),
                          ),
                        ),
                        if (_showHeartPop)
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 600),
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Opacity(
                                  opacity: 1 - value,
                                  child: const Icon(
                                    Icons.favorite,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // 슬라이더
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Column(
                        children: [
                          Slider(
                            value: _bcs?.toDouble() ?? 5.0,
                            min: 1,
                            max: 9,
                            divisions: 8,
                            label: '$_bcs',
                            onChanged: _onBcsChanged,
                            activeColor: AppColors.primaryBlue,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '마른 편',
                                style: AppTypography.small,
                              ),
                              Text(
                                '통통한 편',
                                style: AppTypography.small,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // 피드백 텍스트
                    if (_bcs != null)
                      Text(
                        _getFeedbackText(),
                        style: AppTypography.body.copyWith(
                          color: _bcs! <= 3
                              ? AppColors.dangerRed
                              : _bcs! <= 6
                                  ? AppColors.positiveGreen
                                  : AppColors.dangerRed,
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

  Widget _buildCharacterSilhouette() {
    // 간단한 실루엣 표현 (BCS에 따라 크기 변화)
    final scale = _bcs != null ? (1.0 + (_bcs! - 5) * 0.1) : 1.0;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: 100 * scale,
      height: 100 * scale,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.pets,
          size: 60 * scale,
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }
}
