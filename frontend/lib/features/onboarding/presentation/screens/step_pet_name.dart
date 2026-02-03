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

/// Step 2: 아이 이름
class StepPetNameScreen extends ConsumerStatefulWidget {
  const StepPetNameScreen({super.key});

  @override
  ConsumerState<StepPetNameScreen> createState() =>
      _StepPetNameScreenState();
}

class _StepPetNameScreenState extends ConsumerState<StepPetNameScreen> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(onboardingControllerProvider);
      if (state.profile.name != null && state.profile.name!.isNotEmpty) {
        _nameController.text = state.profile.name!;
        setState(() {});
      }
    });
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onNext() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    HapticFeedback.lightImpact();
    final profile = ref.read(onboardingControllerProvider).profile;
    await ref.read(onboardingControllerProvider.notifier).saveProfile(
          profile.copyWith(name: name),
        );
    await ref.read(onboardingControllerProvider.notifier).nextStep();
  }

  void _onBack() {
    HapticFeedback.lightImpact();
    ref.read(onboardingControllerProvider.notifier).previousStep();
  }

  @override
  Widget build(BuildContext context) {
    final name = _nameController.text.trim();
    final isValid = name.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            OnboardingHeader(
              currentStep: OnboardingStep.petName,
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
                    const EmojiIcon(emoji: '🐾', size: 80),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      '우리 아이 이름은요? 🐾',
                      style: AppTypography.h2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    TextField(
                      controller: _nameController,
                      maxLength: 20,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: '이름을 입력해주세요',
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
