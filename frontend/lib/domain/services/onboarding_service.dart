import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/onboarding/data/repositories/onboarding_repository.dart';

/// 온보딩 관련 비즈니스 로직 서비스
/// 단일 책임: 온보딩 완료 여부 확인
class OnboardingService {
  final OnboardingRepository _repository;

  OnboardingService(this._repository);

  /// 온보딩 완료 여부 확인
  Future<bool> isOnboardingCompleted() async {
    return await _repository.isOnboardingCompleted();
  }
}

/// OnboardingService Provider
final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  final repository = OnboardingRepositoryImpl();
  return OnboardingService(repository);
});
