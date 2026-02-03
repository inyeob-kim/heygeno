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
import '../widgets/health_concern_chip.dart';

/// Step E: 건강 + 알레르기
class StepEHealthAllergiesScreen extends ConsumerStatefulWidget {
  const StepEHealthAllergiesScreen({super.key});

  @override
  ConsumerState<StepEHealthAllergiesScreen> createState() =>
      _StepEHealthAllergiesScreenState();
}

class _StepEHealthAllergiesScreenState
    extends ConsumerState<StepEHealthAllergiesScreen> {
  final List<String> _healthConcerns = []; // 기본: 빈 배열 = "없어요"
  final List<String> _foodAllergies = []; // 기본: 빈 배열 = "없어요"
  final _otherAllergyController = TextEditingController();
  bool _showOtherField = false;

  static const List<String> _healthOptions = [
    'ALLERGY', 'DIGESTIVE', 'DENTAL', 'OBESITY', 'RESPIRATORY',
    'SKIN', 'JOINT', 'EYE', 'KIDNEY', 'HEART', 'SENIOR',
  ];
  
  static const Map<String, String> _healthDisplayNames = {
    'ALLERGY': '알레르기',
    'DIGESTIVE': '장/소화',
    'DENTAL': '치아/구강',
    'OBESITY': '비만',
    'RESPIRATORY': '호흡기',
    'SKIN': '피부/털',
    'JOINT': '관절',
    'EYE': '눈/눈물',
    'KIDNEY': '신장/요로',
    'HEART': '심장',
    'SENIOR': '노령',
  };

  static const List<String> _allergyOptions = [
    'BEEF', 'CHICKEN', 'PORK', 'DUCK', 'LAMB', 'FISH',
    'EGG', 'DAIRY', 'WHEAT', 'CORN', 'SOY',
  ];
  
  static const Map<String, String> _allergyDisplayNames = {
    'BEEF': '소고기',
    'CHICKEN': '닭고기',
    'PORK': '돼지고기',
    'DUCK': '오리고기',
    'LAMB': '양고기',
    'FISH': '생선',
    'EGG': '계란',
    'DAIRY': '유제품',
    'WHEAT': '밀/글루텐',
    'CORN': '옥수수',
    'SOY': '콩',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(onboardingControllerProvider);
      if (state.profile.healthConcerns.isNotEmpty) {
        _healthConcerns.addAll(state.profile.healthConcerns);
      }
      if (state.profile.foodAllergies.isNotEmpty) {
        _foodAllergies.addAll(state.profile.foodAllergies);
        _showOtherField = state.profile.otherAllergyText != null;
      }
      if (state.profile.otherAllergyText != null) {
        _otherAllergyController.text = state.profile.otherAllergyText!;
      }
      setState(() {});
    });
    _otherAllergyController.addListener(() {
      _onOtherChanged(_otherAllergyController.text);
    });
  }

  @override
  void dispose() {
    _otherAllergyController.dispose();
    super.dispose();
  }

  void _onHealthToggled(String code) {
    HapticFeedback.lightImpact();
    
    setState(() {
      if (_healthConcerns.contains(code)) {
        _healthConcerns.remove(code);
      } else {
        _healthConcerns.add(code);
      }
    });
    
    _saveHealthConcerns();
  }

  void _onAllergyToggled(String code) {
    HapticFeedback.lightImpact();
    
    setState(() {
      if (code == 'OTHER') {
        if (_showOtherField) {
          _showOtherField = false;
          _otherAllergyController.clear();
        } else {
          _showOtherField = true;
        }
      } else {
        if (_foodAllergies.contains(code)) {
          _foodAllergies.remove(code);
        } else {
          _foodAllergies.add(code);
        }
      }
    });
    
    _saveAllergies();
  }

  void _onOtherChanged(String text) {
    if (text.isNotEmpty && !_foodAllergies.contains('OTHER')) {
      setState(() {
        _foodAllergies.add('OTHER');
      });
    }
    _saveAllergies();
  }

  void _saveHealthConcerns() {
    final profile = ref.read(onboardingControllerProvider).profile;
    ref.read(onboardingControllerProvider.notifier).saveProfile(
          profile.copyWith(healthConcerns: _healthConcerns),
        );
  }

  void _saveAllergies() {
    final profile = ref.read(onboardingControllerProvider).profile;
    ref.read(onboardingControllerProvider.notifier).saveProfile(
          profile.copyWith(
            foodAllergies: _foodAllergies,
            otherAllergyText: _otherAllergyController.text.isNotEmpty
                ? _otherAllergyController.text
                : null,
          ),
        );
  }

  Future<void> _onNext() async {
    HapticFeedback.lightImpact();
    await ref.read(onboardingControllerProvider.notifier).nextStep();
  }

  void _onBack() {
    HapticFeedback.lightImpact();
    ref.read(onboardingControllerProvider.notifier).previousStep();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            OnboardingHeader(
              currentStep: OnboardingStep.healthAllergies,
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
                    const EmojiIcon(emoji: '🩺', size: 80),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      '건강 고민이나 알레르기가 있나요? 🩺',
                      style: AppTypography.h2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    // 건강 고민 섹션
                    Text(
                      '건강 고민',
                      style: AppTypography.h3,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        HealthConcernChip(
                          label: '없어요',
                          isSelected: _healthConcerns.isEmpty,
                          isExclusive: true,
                          onTap: () {
                            setState(() {
                              _healthConcerns.clear();
                            });
                            _saveHealthConcerns();
                          },
                        ),
                        ..._healthOptions.map((code) {
                          return HealthConcernChip(
                            label: _healthDisplayNames[code] ?? code,
                            isSelected: _healthConcerns.contains(code),
                            onTap: () => _onHealthToggled(code),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // 음식 알레르기 섹션
                    Text(
                      '음식 알레르기',
                      style: AppTypography.h3,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        HealthConcernChip(
                          label: '없어요',
                          isSelected: _foodAllergies.isEmpty,
                          isExclusive: true,
                          onTap: () {
                            setState(() {
                              _foodAllergies.clear();
                              _showOtherField = false;
                              _otherAllergyController.clear();
                            });
                            _saveAllergies();
                          },
                        ),
                        ..._allergyOptions.map((code) {
                          return HealthConcernChip(
                            label: _allergyDisplayNames[code] ?? code,
                            isSelected: _foodAllergies.contains(code),
                            onTap: () => _onAllergyToggled(code),
                          );
                        }),
                        HealthConcernChip(
                          label: '기타',
                          isSelected: _showOtherField,
                          onTap: () => _onAllergyToggled('OTHER'),
                        ),
                      ],
                    ),
                    if (_showOtherField) ...[
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _otherAllergyController,
                        decoration: InputDecoration(
                          hintText: '기타 알레르기 재료를 입력해주세요',
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.medium),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.md,
                          ),
                        ),
                        style: AppTypography.body,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            OnboardingFooter(
              buttonText: '다음',
              onPressed: _onNext, // 항상 활성화 (기본값으로 통과 가능)
              isEnabled: true,
            ),
          ],
        ),
      ),
    );
  }
}
