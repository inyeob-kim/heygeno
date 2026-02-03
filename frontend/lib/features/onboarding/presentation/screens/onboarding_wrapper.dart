import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/onboarding_step.dart';
import '../controllers/onboarding_controller.dart';
import 'step_nickname.dart';
import 'step_pet_name.dart';
import 'step_species.dart';
import 'step_age.dart';
import 'step_b_age_breed.dart';
import 'step_c_sex_neutered.dart';
import 'step_d_weight_bcs.dart';
import 'step_body_condition.dart';
import 'step_e_health_allergies.dart';
import 'step_f_photo.dart';

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
    // 초기 데이터 로드 (생성자에서 자동으로 호출되지만 명시적으로 호출)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Controller가 생성되면서 자동으로 _loadSavedData()가 호출됩니다
      // 여기서는 단순히 watch만 하면 됩니다
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final step = state.currentStep;
    
    print('[OnboardingWrapper] build() called, current step: $step, isLoading: ${state.isLoading}');


    // 로딩 중일 때
    if (state.isLoading && step == OnboardingStep.nickname) {
      print('[OnboardingWrapper] Showing loading screen');
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FB),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 현재 단계에 맞는 화면 표시
    Widget screen;
    switch (step) {
      case OnboardingStep.nickname:
        print('[OnboardingWrapper] Showing StepNicknameScreen');
        screen = const StepNicknameScreen();
        break;
      case OnboardingStep.petName:
        print('[OnboardingWrapper] Showing StepPetNameScreen');
        screen = const StepPetNameScreen();
        break;
      case OnboardingStep.species:
        print('[OnboardingWrapper] Showing StepSpeciesScreen');
        screen = const StepSpeciesScreen();
        break;
      case OnboardingStep.age:
        print('[OnboardingWrapper] Showing StepAgeScreen');
        screen = const StepAgeScreen();
        break;
      case OnboardingStep.breed:
        print('[OnboardingWrapper] Showing StepBreedScreen');
        screen = const StepBreedScreen();
        break;
      case OnboardingStep.sexNeutered:
        print('[OnboardingWrapper] Showing StepCSexNeuteredScreen');
        screen = const StepCSexNeuteredScreen();
        break;
      case OnboardingStep.weight:
        print('[OnboardingWrapper] Showing StepWeightScreen');
        screen = const StepWeightScreen();
        break;
      case OnboardingStep.bodyCondition:
        print('[OnboardingWrapper] Showing StepBodyConditionScreen');
        screen = const StepBodyConditionScreen();
        break;
      case OnboardingStep.healthAllergies:
        print('[OnboardingWrapper] Showing StepEHealthAllergiesScreen');
        screen = const StepEHealthAllergiesScreen();
        break;
      case OnboardingStep.photo:
        print('[OnboardingWrapper] Showing StepFPhotoScreen');
        screen = const StepFPhotoScreen();
        break;
    }

    return screen;
  }
}

