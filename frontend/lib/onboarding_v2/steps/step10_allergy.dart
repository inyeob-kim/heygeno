import 'package:flutter/material.dart';
import '../onboarding_shell.dart';
import '../widgets/pill_chip.dart';
import '../widgets/toss_text_input.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/app_spacing.dart';

/// Step 10: Food Allergies - DESIGN_GUIDE v1.0 준수
class Step10Allergy extends StatelessWidget {
  final List<String> value;
  final String otherAllergy;
  final ValueChanged<Map<String, dynamic>> onUpdate;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final int currentStep;
  final int totalSteps;

  const Step10Allergy({
    super.key,
    required this.value,
    required this.otherAllergy,
    required this.onUpdate,
    required this.onNext,
    required this.onBack,
    required this.currentStep,
    required this.totalSteps,
  });

  static const List<String> allergyOptions = [
    '없어요',
    '소고기',
    '닭고기',
    '돼지고기',
    '오리고기',
    '양고기',
    '생선',
    '계란',
    '유제품',
    '밀/글루텐',
    '옥수수',
    '콩',
    '기타',
  ];

  void handleToggle(String allergy) {
    if (allergy == '없어요') {
      // "없어요" is exclusive
      onUpdate({
        'foodAllergies': value.contains('없어요') ? [] : ['없어요'],
        'otherAllergy': '',
      });
    } else {
      // Remove "없어요" if selecting anything else
      final filtered = value.where((v) => v != '없어요').toList();
      if (filtered.contains(allergy)) {
        final newValue = filtered.where((v) => v != allergy).toList();
        onUpdate({
          'foodAllergies': newValue,
          'otherAllergy': allergy == '기타' ? '' : otherAllergy,
        });
      } else {
        onUpdate({'foodAllergies': [...filtered, allergy]});
      }
    }
  }

  bool get isValid {
    // "없어요"가 선택되어 있거나, 다른 항목이 하나라도 선택되어 있으면 유효
    // "기타"를 선택했을 때는 otherAllergy 텍스트도 확인
    if (value.isEmpty) return false;
    if (value.contains('기타') && (otherAllergy.trim().isEmpty)) {
      return false; // "기타" 선택했는데 텍스트가 없으면 유효하지 않음
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingShell(
      currentStep: currentStep,
      totalSteps: totalSteps,
      onBack: onBack,
      emoji: '🍗',
      title: '피해야 하는 재료가 있나요?',
      ctaText: '다음',
      ctaDisabled: !isValid,
      onCTAClick: onNext,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: allergyOptions.asMap().entries.map((entry) {
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
          if (value.contains('기타')) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              '기타 재료를 입력해주세요',
              style: AppTypography.small.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TossTextInput(
              value: otherAllergy,
              onChanged: (val) => onUpdate({'otherAllergy': val}),
              placeholder: '기타 알레르기 재료를 입력해주세요',
            ),
          ],
        ],
      ),
    );
  }
}
