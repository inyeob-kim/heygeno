import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/onboarding/data/models/onboarding_step.dart';
import '../../features/onboarding/data/models/pet_profile_draft.dart';
import '../../features/onboarding/data/repositories/onboarding_repository.dart';

/// 온보딩 관련 비즈니스 로직 서비스
/// 단일 책임: 온보딩 완료 여부 확인 및 중간 저장
class OnboardingService {
  final OnboardingRepository _repository;

  OnboardingService(this._repository);

  /// 온보딩 완료 여부 확인
  Future<bool> isOnboardingCompleted() async {
    return await _repository.isOnboardingCompleted();
  }

  /// 온보딩 완료 여부 설정
  Future<void> setOnboardingCompleted(bool completed) async {
    await _repository.setOnboardingCompleted(completed);
  }

  /// 마지막 단계 조회
  Future<OnboardingStep?> getLastStep() async {
    return _repository.getLastStep();
  }

  /// 마지막 단계 저장
  Future<void> saveLastStep(OnboardingStep step) async {
    await _repository.saveLastStep(step);
  }

  /// 닉네임 초안 조회
  Future<String?> getDraftNickname() async {
    return _repository.getDraftNickname();
  }

  /// 닉네임 초안 저장
  Future<void> saveDraftNickname(String nickname) async {
    await _repository.saveDraftNickname(nickname);
  }

  /// 프로필 초안 조회
  Future<PetProfileDraft?> getDraftProfile() async {
    return _repository.getDraftProfile();
  }

  /// 프로필 초안 저장
  Future<void> saveDraftProfile(PetProfileDraft profile) async {
    await _repository.saveDraftProfile(profile);
  }

  /// 온보딩 초기화 (다시 회원가입 시 사용)
  Future<void> resetOnboarding() async {
    await _repository.clearAll();
  }
}

/// OnboardingService Provider
final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  final repository = OnboardingRepositoryImpl();
  return OnboardingService(repository);
});
