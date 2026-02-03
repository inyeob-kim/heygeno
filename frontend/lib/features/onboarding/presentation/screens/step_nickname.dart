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

/// Step 1: 닉네임
class StepNicknameScreen extends ConsumerStatefulWidget {
  const StepNicknameScreen({super.key});

  @override
  ConsumerState<StepNicknameScreen> createState() =>
      _StepNicknameScreenState();
}

class _StepNicknameScreenState extends ConsumerState<StepNicknameScreen> {
  final _nicknameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(onboardingControllerProvider);
      if (state.nickname != null) {
        _nicknameController.text = state.nickname!;
        setState(() {});
      }
    });
    _nicknameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void _onRandomNickname() {
    final randomNicknames = [
      '뽀뽀맘', '멍멍이집사', '냥이사랑', '골든맘', '츄츄파파',
      '강아지천사', '고양이천사', '반려인', '펫러버', '사랑이맘'
    ];
    final random = randomNicknames[DateTime.now().millisecond % randomNicknames.length];
    _nicknameController.text = random;
    setState(() {});
    HapticFeedback.lightImpact();
  }

  Future<void> _onNext() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.length < 2 || nickname.length > 12) return;

    HapticFeedback.lightImpact();
    await ref.read(onboardingControllerProvider.notifier).saveNickname(nickname);
    await ref.read(onboardingControllerProvider.notifier).nextStep();
  }

  void _onBack() {
    HapticFeedback.lightImpact();
    ref.read(onboardingControllerProvider.notifier).previousStep();
  }

  @override
  Widget build(BuildContext context) {
    final nickname = _nicknameController.text.trim();
    final isValid = nickname.length >= 2 && nickname.length <= 12;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            OnboardingHeader(
              currentStep: OnboardingStep.nickname,
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
                    const EmojiIcon(emoji: '😊', size: 80),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      '안녕하세요! 😊',
                      style: AppTypography.h2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '헤이제노에서 쓸 닉네임만 먼저 정해볼까요?',
                      style: AppTypography.lead,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    TextField(
                      controller: _nicknameController,
                      maxLength: 12,
                      decoration: InputDecoration(
                        hintText: '닉네임을 입력해주세요',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: TextButton(
                          onPressed: _onRandomNickname,
                          child: const Text('🎲 추천받기'),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                      ),
                      style: AppTypography.body,
                    ),
                    if (nickname.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          '${nickname.length}/12',
                          style: AppTypography.small,
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
