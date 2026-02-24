import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/onboarding/data/models/onboarding_step.dart';
import '../../features/onboarding/data/models/pet_profile_draft.dart';
import '../../features/onboarding/data/repositories/onboarding_repository.dart';
import 'pet_service.dart';

/// 온보딩 관련 비즈니스 로직 서비스
/// 단일 책임: 온보딩 완료 여부 확인 및 중간 저장
class OnboardingService {
  final OnboardingRepository _repository;
  final PetService _petService;

  OnboardingService(this._repository, this._petService);

  /// 로그인 직후: 서버에 펫 보유 여부를 조회해 로컬 온보딩 완료 상태를 동기화하고,
  /// 홈으로 갈지(true) 온보딩으로 갈지(false) 반환.
  /// API 실패 시 기존 온보딩 완료 상태를 유지해, 네트워크 오류로 인해 이미 완료한 사용자가 온보딩으로 돌아가는 것을 방지.
  Future<bool> shouldGoToHomeAfterLogin() async {
    try {
      final pets = await _petService.getAllPetSummaries();
      final hasPets = pets.isNotEmpty;
      await _repository.setOnboardingCompleted(hasPets);
      return hasPets;
    } catch (_) {
      // API/네트워크 실패 시: 기존 완료 여부를 유지. 이미 완료된 사용자는 홈으로, 미완료는 온보딩으로.
      final wasCompleted = await _repository.isOnboardingCompleted();
      return wasCompleted;
    }
  }

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
  final petService = ref.read(petServiceProvider);
  return OnboardingService(repository, petService);
});
