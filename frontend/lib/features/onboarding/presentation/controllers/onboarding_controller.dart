import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/onboarding_step.dart';
import '../../data/models/pet_profile_draft.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../domain/services/device_uid_service.dart';
import 'onboarding_state.dart';

/// 온보딩 Controller Provider
final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>((ref) {
  return OnboardingController(
    OnboardingRepositoryImpl(),
  );
});

/// 온보딩 Controller
class OnboardingController extends StateNotifier<OnboardingState> {
  final OnboardingRepository _repository;

  OnboardingController(this._repository)
      : super(OnboardingState(currentStep: OnboardingStep.welcome)) {
    _loadSavedData();
  }

  /// 저장된 데이터 로드
  Future<void> _loadSavedData() async {
    state = state.copyWith(isLoading: true);

    try {
      // 마지막 단계 로드
      final lastStep = await _repository.getLastStep();
      final step = lastStep ?? OnboardingStep.welcome;

      // 닉네임 로드
      final nickname = await _repository.getDraftNickname();

      // 프로필 초안 로드
      final profile = await _repository.getDraftProfile();

      state = state.copyWith(
        currentStep: step,
        nickname: nickname,
        profile: profile,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 닉네임 저장
  Future<void> saveNickname(String nickname) async {
    state = state.copyWith(nickname: nickname);
    await _repository.saveDraftNickname(nickname);
  }

  /// 프로필 초안 저장
  Future<void> saveProfile(PetProfileDraft profile) async {
    state = state.copyWith(profile: profile);
    await _repository.saveDraftProfile(profile);
  }

  /// 다음 단계로 이동
  Future<void> nextStep() async {
    final next = state.currentStep.next;
    if (next != null) {
      state = state.copyWith(currentStep: next);
      await _repository.saveLastStep(next);
    }
  }

  /// 이전 단계로 이동
  Future<void> previousStep() async {
    final previous = state.currentStep.previous;
    if (previous != null) {
      state = state.copyWith(currentStep: previous);
      await _repository.saveLastStep(previous);
    }
  }

  /// 특정 단계로 이동
  Future<void> goToStep(OnboardingStep step) async {
    state = state.copyWith(currentStep: step);
    await _repository.saveLastStep(step);
  }

  /// 온보딩 완료
  Future<void> completeOnboarding() async {
    state = state.copyWith(isLoading: true);

    try {
      // Device UID 생성/확인
      await DeviceUidService.getOrCreateDeviceUid();

      // 온보딩 완료 표시
      await _repository.setOnboardingCompleted(true);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 프로필 검증
  bool validateProfile() {
    final p = state.profile;
    final n = state.nickname;

    // 닉네임 검증
    if (n == null || n.trim().length < 2 || n.trim().length > 12) {
      return false;
    }

    // 필수 필드 검증
    if (p.name == null || p.name!.trim().isEmpty) return false;
    if (p.species == null) return false;
    if (p.birthMode == null) return false;
    if (p.sex == null) return false;
    if (p.neutered == null) return false;
    if (p.weightKg == null || p.weightKg! <= 0) return false;
    if (p.bodyConditionScore == null) return false;
    if (p.healthConcerns.isEmpty) return false;
    if (p.foodAllergies.isEmpty) return false;

    // 조건부 필드 검증
    if (p.birthMode == 'exactBirthdate' && p.birthdate == null) return false;
    if (p.birthMode == 'approxAge' && p.ageYears == null) return false;
    if (p.species == 'dog' && (p.breed == null || p.breed!.isEmpty)) {
      return false;
    }

    return true;
  }
}
