import 'package:flutter/material.dart';
import '../onboarding_shell.dart';
import '../widgets/pill_chip.dart';
import '../widgets/toss_text_input.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/constants/pet_constants.dart';
import 'package:pet_food_app/l10n/app_localizations.dart';

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

  List<String> getAllergyOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.onboarding_step9_none,
      PetConstants.getAllergenName(context, 'beef'),
      PetConstants.getAllergenName(context, 'chicken'),
      PetConstants.getAllergenName(context, 'pork'),
      PetConstants.getAllergenName(context, 'duck'),
      PetConstants.getAllergenName(context, 'lamb'),
      PetConstants.getAllergenName(context, 'fish'),
      PetConstants.getAllergenName(context, 'egg'),
      PetConstants.getAllergenName(context, 'dairy'),
      PetConstants.getAllergenName(context, 'wheat'),
      PetConstants.getAllergenName(context, 'corn'),
      PetConstants.getAllergenName(context, 'soy'),
      l10n.common_other,
    ];
  }

  void handleToggle(BuildContext context, String allergy) {
    final l10n = AppLocalizations.of(context)!;
    final noneOption = l10n.onboarding_step9_none;
    final otherOption = l10n.common_other;
    
    if (allergy == noneOption) {
      // "None" is exclusive
      onUpdate({
        'foodAllergies': value.contains(noneOption) ? [] : [noneOption],
        'otherAllergy': '',
      });
    } else {
      // Remove "None" if selecting anything else
      final filtered = value.where((v) => v != noneOption).toList();
      if (filtered.contains(allergy)) {
        final newValue = filtered.where((v) => v != allergy).toList();
        onUpdate({
          'foodAllergies': newValue,
          'otherAllergy': allergy == otherOption ? '' : otherAllergy,
        });
      } else {
        onUpdate({'foodAllergies': [...filtered, allergy]});
      }
    }
  }

  bool isValid(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final otherOption = l10n.common_other;
    // "None"이 선택되어 있거나, 다른 항목이 하나라도 선택되어 있으면 유효
    // "Other"를 선택했을 때는 otherAllergy 텍스트도 확인
    if (value.isEmpty) return false;
    if (value.contains(otherOption) && (otherAllergy.trim().isEmpty)) {
      return false; // "Other" 선택했는데 텍스트가 없으면 유효하지 않음
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
      title: AppLocalizations.of(context)!.onboarding_step10_title,
      ctaText: AppLocalizations.of(context)!.common_next,
      ctaDisabled: !isValid(context),
      onCTAClick: onNext,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: getAllergyOptions(context).asMap().entries.map((entry) {
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
                        onTap: () => handleToggle(context, option),
                      ),
                    ),
                  );
                },
                child: const SizedBox.shrink(),
              );
            }).toList(),
          ),
          if (value.contains(AppLocalizations.of(context)!.common_other)) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppLocalizations.of(context)!.onboarding_step10_otherLabel,
              style: AppTypography.small.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TossTextInput(
              value: otherAllergy,
              onChanged: (val) => onUpdate({'otherAllergy': val}),
              placeholder: AppLocalizations.of(context)!.onboarding_step10_otherPlaceholder,
            ),
          ],
        ],
      ),
    );
  }
}
