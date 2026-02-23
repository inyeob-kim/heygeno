import 'package:flutter/material.dart';
import '../onboarding_shell.dart';
import '../widgets/pill_chip.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/constants/pet_constants.dart';
import 'package:pet_food_app/l10n/app_localizations.dart';

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

  List<String> getHealthOptions(BuildContext context) {
    return [
      AppLocalizations.of(context)!.onboarding_step9_none,
      PetConstants.getHealthConcernName(context, 'allergy'),
      PetConstants.getHealthConcernName(context, 'digestive'),
      PetConstants.getHealthConcernName(context, 'dental'),
      PetConstants.getHealthConcernName(context, 'obesity'),
      PetConstants.getHealthConcernName(context, 'respiratory'),
      PetConstants.getHealthConcernName(context, 'skin'),
      PetConstants.getHealthConcernName(context, 'joint'),
      PetConstants.getHealthConcernName(context, 'eye'),
      PetConstants.getHealthConcernName(context, 'kidney'),
      PetConstants.getHealthConcernName(context, 'heart'),
      PetConstants.getHealthConcernName(context, 'senior'),
    ];
  }

  void handleToggle(BuildContext context, String concern) {
    final noneOption = AppLocalizations.of(context)!.onboarding_step9_none;
    if (concern == noneOption) {
      // "None" is exclusive
      onUpdate(value.contains(noneOption) ? [] : [noneOption]);
    } else {
      // Remove "None" if selecting anything else
      final filtered = value.where((v) => v != noneOption).toList();
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
      title: AppLocalizations.of(context)!.onboarding_step9_title,
      ctaText: AppLocalizations.of(context)!.common_next,
      ctaDisabled: !isValid,
      onCTAClick: onNext,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: getHealthOptions(context).asMap().entries.map((entry) {
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
    );
  }
}
