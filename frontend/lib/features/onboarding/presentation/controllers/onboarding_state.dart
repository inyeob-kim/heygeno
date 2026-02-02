import '../../data/models/pet_profile_draft.dart';
import '../../data/models/onboarding_step.dart';

/// 온보딩 상태
class OnboardingState {
  final OnboardingStep currentStep;
  final String? nickname;
  final PetProfileDraft profile;
  final bool isLoading;
  final String? error;

  OnboardingState({
    required this.currentStep,
    this.nickname,
    PetProfileDraft? profile,
    this.isLoading = false,
    this.error,
  }) : profile = profile ?? PetProfileDraft();

  OnboardingState copyWith({
    OnboardingStep? currentStep,
    String? nickname,
    PetProfileDraft? profile,
    bool? isLoading,
    String? error,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      nickname: nickname ?? this.nickname,
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
