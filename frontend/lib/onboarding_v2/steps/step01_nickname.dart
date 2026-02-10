import 'package:flutter/material.dart';
import '../onboarding_shell.dart';
import '../widgets/toss_text_input.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/app_spacing.dart';

/// Step 1: Nickname - matches React Step1Nickname
class Step01Nickname extends StatelessWidget {
  final String value;
  final ValueChanged<String> onUpdate;
  final VoidCallback onNext;
  final int currentStep;
  final int totalSteps;

  const Step01Nickname({
    super.key,
    required this.value,
    required this.onUpdate,
    required this.onNext,
    required this.currentStep,
    required this.totalSteps,
  });

  bool get isValid => value.length >= 2 && value.length <= 12;

  @override
  Widget build(BuildContext context) {
    return OnboardingShell(
      currentStep: currentStep,
      totalSteps: totalSteps,
      emoji: '', // 이모지 제거
      title: '안녕하세요',
      subtitle: '헤이제노에서 쓸 닉네임만 먼저 정해볼까요?',
      ctaText: '다음',
      ctaDisabled: !isValid,
      onCTAClick: onNext,
      leadingWidget: Image.asset(
        'assets/images/logo/heygeno-logo.png',
        height: 80,
        fit: BoxFit.contain,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '닉네임',
            style: AppTypography.small.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TossTextInput(
            value: value,
            onChanged: onUpdate,
            placeholder: '닉네임을 입력해주세요',
            maxLength: 12,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '2~12자',
            style: AppTypography.small,
          ),
        ],
      ),
    );
  }
}
