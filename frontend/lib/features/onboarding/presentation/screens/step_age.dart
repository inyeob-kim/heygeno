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
import '../widgets/birth_mode_card.dart';

/// Step 4: 나이
class StepAgeScreen extends ConsumerStatefulWidget {
  const StepAgeScreen({super.key});

  @override
  ConsumerState<StepAgeScreen> createState() => _StepAgeScreenState();
}

class _StepAgeScreenState extends ConsumerState<StepAgeScreen> {
  String? _ageMode; // 'APPROX' | 'BIRTHDATE', 기본: 'APPROX'
  int? _approxAgeMonths; // 기본: 12 (1살)
  DateTime? _birthdate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(onboardingControllerProvider);
      final profile = state.profile;
      
      _ageMode = profile.birthMode ?? 'APPROX';
      _approxAgeMonths = profile.approxAgeMonths ?? 12;
      _birthdate = profile.birthdate;
      
      // 기본값이 설정되었고 프로필에 저장되지 않았다면 저장
      if (profile.birthMode == null) {
        ref.read(onboardingControllerProvider.notifier).saveProfile(
              profile.copyWith(
                birthMode: 'APPROX',
                approxAgeMonths: 12,
              ),
            );
      } else if (profile.birthMode == 'APPROX' && profile.approxAgeMonths == null) {
        ref.read(onboardingControllerProvider.notifier).saveProfile(
              profile.copyWith(approxAgeMonths: 12),
            );
      }
      
      setState(() {});
    });
  }

  void _onAgeModeSelected(String mode) {
    HapticFeedback.lightImpact();
    setState(() {
      _ageMode = mode;
    });
    
    final profile = ref.read(onboardingControllerProvider).profile;
    ref.read(onboardingControllerProvider.notifier).saveProfile(
          profile.copyWith(birthMode: mode),
        );
  }

  void _onAgeChanged(int months) {
    HapticFeedback.lightImpact();
    setState(() {
      _approxAgeMonths = months;
    });
    
    final profile = ref.read(onboardingControllerProvider).profile;
    ref.read(onboardingControllerProvider.notifier).saveProfile(
          profile.copyWith(approxAgeMonths: months),
        );
  }

  void _onDateSelected(DateTime date) {
    HapticFeedback.lightImpact();
    setState(() {
      _birthdate = date;
    });
    
    final profile = ref.read(onboardingControllerProvider).profile;
    ref.read(onboardingControllerProvider.notifier).saveProfile(
          profile.copyWith(birthdate: date),
        );
  }

  Future<void> _onNext() async {
    if (_ageMode == null) return;
    if (_ageMode == 'APPROX' && _approxAgeMonths == null) return;
    if (_ageMode == 'BIRTHDATE' && _birthdate == null) return;

    HapticFeedback.lightImpact();
    
    // 명시적으로 저장 (안전을 위해)
    final profile = ref.read(onboardingControllerProvider).profile;
    if (_ageMode == 'APPROX') {
      await ref.read(onboardingControllerProvider.notifier).saveProfile(
            profile.copyWith(
              birthMode: 'APPROX',
              approxAgeMonths: _approxAgeMonths,
              birthdate: null, // APPROX 모드에서는 birthdate 제거
            ),
          );
    } else {
      await ref.read(onboardingControllerProvider.notifier).saveProfile(
            profile.copyWith(
              birthMode: 'BIRTHDATE',
              birthdate: _birthdate,
              approxAgeMonths: null, // BIRTHDATE 모드에서는 approxAgeMonths 제거
            ),
          );
    }
    
    await ref.read(onboardingControllerProvider.notifier).nextStep();
  }

  void _onBack() {
    HapticFeedback.lightImpact();
    ref.read(onboardingControllerProvider.notifier).previousStep();
  }

  bool get _isValid {
    if (_ageMode == null) return false;
    if (_ageMode == 'APPROX' && _approxAgeMonths == null) return false;
    if (_ageMode == 'BIRTHDATE' && _birthdate == null) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            OnboardingHeader(
              currentStep: OnboardingStep.age,
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
                    const EmojiIcon(emoji: '🎂', size: 80),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      '나이는 어떻게 알려주실래요? 🎂',
                      style: AppTypography.h2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    // 모드 선택 (기본: APPROX)
                    BirthModeCard(
                      emoji: '🎈',
                      label: '대략적인 나이만',
                      isSelected: _ageMode == 'APPROX',
                      onTap: () => _onAgeModeSelected('APPROX'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    BirthModeCard(
                      emoji: '📅',
                      label: '생년월일 알아요',
                      isSelected: _ageMode == 'BIRTHDATE',
                      onTap: () => _onAgeModeSelected('BIRTHDATE'),
                    ),
                    // 조건부 컨텐츠
                    if (_ageMode == 'APPROX') ...[
                      const SizedBox(height: AppSpacing.xxl),
                      _buildAgeStepper(),
                    ] else if (_ageMode == 'BIRTHDATE') ...[
                      const SizedBox(height: AppSpacing.xxl),
                      _buildDatePicker(),
                    ],
                  ],
                ),
              ),
            ),
            OnboardingFooter(
              buttonText: '다음',
              onPressed: _isValid ? _onNext : null,
              isEnabled: _isValid,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeStepper() {
    final years = (_approxAgeMonths ?? 12) ~/ 12;
    final months = (_approxAgeMonths ?? 12) % 12;
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () {
                  final newMonths = ((_approxAgeMonths ?? 12) - 1).clamp(0, 240);
                  _onAgeChanged(newMonths);
                },
              ),
              Text(
                '${years}살 ${months}개월',
                style: AppTypography.h3,
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  final newMonths = ((_approxAgeMonths ?? 12) + 1).clamp(0, 240);
                  _onAgeChanged(newMonths);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: SizedBox(
        height: 200,
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          initialDateTime: _birthdate ?? DateTime.now().subtract(const Duration(days: 365)),
          maximumDate: DateTime.now(),
          minimumDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
          onDateTimeChanged: _onDateSelected,
        ),
      ),
    );
  }
}
