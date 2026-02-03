import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../data/models/onboarding_step.dart';
import '../../data/models/pet_profile_draft.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../../../core/services/device_uid_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';
import 'onboarding_state.dart';

/// 온보딩 Controller Provider
final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>((ref) {
  return OnboardingController(
    OnboardingRepositoryImpl(),
    ref.watch(apiClientProvider),
  );
});

/// 온보딩 Controller
class OnboardingController extends StateNotifier<OnboardingState> {
  final OnboardingRepository _repository;
  final ApiClient _apiClient;

  OnboardingController(this._repository, this._apiClient)
      : super(OnboardingState(currentStep: OnboardingStep.nickname)) {
    _loadSavedData();
  }

  /// 저장된 데이터 로드
  Future<void> _loadSavedData() async {
    state = state.copyWith(isLoading: true);

    try {
      // 마지막 단계 로드
      final lastStep = await _repository.getLastStep();
      final step = lastStep ?? OnboardingStep.nickname;

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
    print('[OnboardingController] saveNickname() called, nickname: $nickname');
    state = state.copyWith(nickname: nickname);
    print('[OnboardingController] State updated, current step: ${state.currentStep}, nickname: ${state.nickname}');
    await _repository.saveDraftNickname(nickname);
    print('[OnboardingController] Nickname saved to repository');
  }

  /// 프로필 초안 저장
  Future<void> saveProfile(PetProfileDraft profile) async {
    state = state.copyWith(profile: profile);
    await _repository.saveDraftProfile(profile);
  }

  /// 다음 단계로 이동
  Future<void> nextStep() async {
    print('[OnboardingController] nextStep() called, current step: ${state.currentStep}');
    final next = state.currentStep.next;
    print('[OnboardingController] Next step: $next');
    if (next != null) {
      state = state.copyWith(currentStep: next);
      print('[OnboardingController] State updated to step: $next');
      await _repository.saveLastStep(next);
      print('[OnboardingController] Last step saved to repository');
    } else {
      print('[OnboardingController] No next step available');
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
      final deviceUid = await DeviceUidService.getOrCreate();

      // 프로필 검증
      if (!validateProfile()) {
        throw Exception('프로필 정보가 완전하지 않습니다.');
      }

      // 서버에 업서트
      final requestData = state.profile.toApiRequest(deviceUid, state.nickname!);
      
      print('[OnboardingController] 요청 데이터: $requestData');
      print('[OnboardingController] Profile 상태: ${state.profile.toJson()}');
      
      try {
        final response = await _apiClient.post(
          Endpoints.onboardingComplete,
          data: requestData,
        );
        
        print('[OnboardingController] 서버 응답: ${response.data}');
      } on DioException catch (e) {
        print('[OnboardingController] API 오류: ${e.message}');
        // 에러가 있어도 로컬 완료 처리 (오프라인 지원)
        if (e.response?.statusCode != null && e.response!.statusCode! >= 400) {
          throw Exception('서버 오류: ${e.response?.data?['detail'] ?? e.message}');
        }
      }

      // 온보딩 완료 표시
      await _repository.setOnboardingCompleted(true);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// 프로필 검증
  bool validateProfile() {
    final p = state.profile;
    final n = state.nickname;

    // 닉네임 검증
    if (n == null || n.trim().length < 2 || n.trim().length > 12) {
      print('[OnboardingController] Validation failed: nickname');
      return false;
    }

    // 필수 필드 검증
    if (p.name == null || p.name!.trim().isEmpty) {
      print('[OnboardingController] Validation failed: name');
      return false;
    }
    if (p.species == null) {
      print('[OnboardingController] Validation failed: species');
      return false;
    }
    if (p.birthMode == null) {
      print('[OnboardingController] Validation failed: birthMode');
      return false;
    }
    if (p.sex == null) {
      print('[OnboardingController] Validation failed: sex');
      return false;
    }
    // isNeutered는 선택 (null 허용)
    if (p.weightKg == null || p.weightKg! <= 0) {
      print('[OnboardingController] Validation failed: weightKg');
      return false;
    }
    if (p.bodyConditionScore == null) {
      print('[OnboardingController] Validation failed: bodyConditionScore');
      return false;
    }
    // healthConcerns와 foodAllergies는 빈 배열 허용 ("없어요")

    // 조건부 필드 검증
    if (p.birthMode == 'BIRTHDATE' && p.birthdate == null) {
      print('[OnboardingController] Validation failed: birthdate (BIRTHDATE mode)');
      return false;
    }
    if (p.birthMode == 'APPROX' && p.approxAgeMonths == null) {
      print('[OnboardingController] Validation failed: approxAgeMonths (APPROX mode)');
      return false;
    }
    if (p.species == 'DOG' && (p.breedCode == null || p.breedCode!.isEmpty)) {
      print('[OnboardingController] Validation failed: breedCode (DOG)');
      return false;
    }

    print('[OnboardingController] Validation passed');
    return true;
  }
}
