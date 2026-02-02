import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/onboarding_controller.dart';
import '../../data/models/onboarding_step.dart';
import 'step_01_welcome_nickname.dart';
import 'step_02_pet_name.dart';
import 'step_03_species_selection.dart';

/// 온보딩 플로우 래퍼
class OnboardingWrapper extends ConsumerStatefulWidget {
  const OnboardingWrapper({super.key});

  @override
  ConsumerState<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends ConsumerState<OnboardingWrapper> {
  @override
  void initState() {
    super.initState();
    // 초기 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingControllerProvider.notifier);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final step = state.currentStep;

    // 완료 체크
    if (state.isLoading && step == OnboardingStep.welcome) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 현재 단계에 맞는 화면 표시
    Widget screen;
    switch (step) {
      case OnboardingStep.welcome:
        screen = const Step01WelcomeNicknameScreen();
        break;
      case OnboardingStep.petName:
        screen = const Step02PetNameScreen();
        break;
      case OnboardingStep.species:
        screen = const Step03SpeciesSelectionScreen();
        break;
      // TODO: 나머지 화면 추가
      default:
        screen = const Step01WelcomeNicknameScreen();
    }

    return screen;
  }
}
