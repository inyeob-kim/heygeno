import 'package:flutter/material.dart';
import '../onboarding_shell.dart';
import '../widgets/pill_chip.dart';
import '../../app/theme/app_spacing.dart';

/// Step 9: Health Concerns - DESIGN_GUIDE v1.0 준수
class Step09Health extends StatelessWidget {
  final List<String> value;
  final ValueChanged<List<String>> onUpdate;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final int currentStep;
  final int totalSteps;

  const Step09Health({
    super.key,
    required this.value,
    required this.onUpdate,
    required this.onNext,
    required this.onBack,
    required this.currentStep,
    required this.totalSteps,
  });

  static const List<String> healthOptions = [
    '없어요',
    '알레르기',
    '장/소화',
    '치아/구강',
    '비만',
    '호흡기',
    '피부/털',
    '관절',
    '눈/눈물',
    '신장/요로',
    '심장',
    '노령',
  ];

  void handleToggle(String concern) {
    if (concern == '없어요') {
      // "없어요" is exclusive
      onUpdate(value.contains('없어요') ? [] : ['없어요']);
    } else {
      // Remove "없어요" if selecting anything else
      final filtered = value.where((v) => v != '없어요').toList();
      if (filtered.contains(concern)) {
        onUpdate(filtered.where((v) => v != concern).toList());
      } else {
        onUpdate([...filtered, concern]);
      }
    }
  }

  bool get isValid {
    // "없어요"가 선택되어 있거나, 다른 항목이 하나라도 선택되어 있으면 유효
    return value.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingShell(
      currentStep: currentStep,
      totalSteps: totalSteps,
      onBack: onBack,
      emoji: '🩺',
      title: '요즘 신경 쓰이는 건강 고민이 있나요?',
      ctaText: '다음',
      ctaDisabled: !isValid,
      onCTAClick: onNext,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: healthOptions.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 200 + (index * 30)),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.9 + (0.1 * value.clamp(0.0, 1.0)),
                  child: PillChip(
                    label: option,
                    selected: this.value.contains(option),
                    onTap: () => handleToggle(option),
                  ),
                ),
              );
            },
            child: const SizedBox.shrink(),
          );
        }).toList(),
      ),
    );
  }
}
