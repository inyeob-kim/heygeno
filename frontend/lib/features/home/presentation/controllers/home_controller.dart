import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/product_repository.dart';
import '../../../../data/models/recommendation_dto.dart';
import '../../../../data/models/pet_summary_dto.dart';
import '../../../../domain/services/pet_service.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/providers/pet_id_provider.dart';

/// 홈 화면 상태 타입 (A/B/C 분기)
enum HomeStateType {
  loading, // 로딩 중
  hasPet, // B: primary pet 존재 → 정상 홈
  noPet, // C: pet 없음 → Empty State
  error, // 에러 상태
}

class HomeState {
  final HomeStateType stateType;
  final PetSummaryDto? petSummary;
  final RecommendationResponseDto? recommendations;
  final bool isLoadingRecommendations;
  final String? error;

  HomeState({
    HomeStateType? stateType,
    this.petSummary,
    this.recommendations,
    this.isLoadingRecommendations = false,
    this.error,
  }) : stateType = stateType ?? HomeStateType.loading;

  bool get hasPet => stateType == HomeStateType.hasPet && petSummary != null;
  bool get isNoPet => stateType == HomeStateType.noPet;
  bool get isError => stateType == HomeStateType.error;
  bool get isLoading => stateType == HomeStateType.loading;

  HomeState copyWith({
    HomeStateType? stateType,
    PetSummaryDto? petSummary,
    RecommendationResponseDto? recommendations,
    bool? isLoadingRecommendations,
    String? error,
  }) {
    return HomeState(
      stateType: stateType ?? this.stateType,
      petSummary: petSummary ?? this.petSummary,
      recommendations: recommendations ?? this.recommendations,
      isLoadingRecommendations: isLoadingRecommendations ?? this.isLoadingRecommendations,
      error: error ?? this.error,
    );
  }
}

class HomeController extends StateNotifier<HomeState> {
  final ProductRepository _productRepository;
  final PetService _petService;
  final Ref _ref;

  HomeController(this._productRepository, this._petService, this._ref)
      : super(HomeState(stateType: HomeStateType.loading));

  /// 홈 화면 초기화 (primary pet 조회 + 추천 로드)
  Future<void> initialize() async {
    state = state.copyWith(stateType: HomeStateType.loading);
    print('[HomeController] initialize() 시작');

    try {
      // 1. Primary Pet 조회
      print('[HomeController] Primary Pet 조회 시작');
      final petSummary = await _petService.getPrimaryPetSummary();
      print('[HomeController] Primary Pet 조회 결과: ${petSummary != null ? "있음 (${petSummary.name})" : "없음"}');

      if (petSummary == null) {
        // C 상태: pet 없음
        state = state.copyWith(
          stateType: HomeStateType.noPet,
          petSummary: null,
        );
        return;
      }

      // 2. Pet ID를 provider에 저장
      _ref.read(currentPetIdProvider.notifier).state = petSummary.petId;

      // 3. B 상태: pet 존재 → 추천 로드
      state = state.copyWith(
        stateType: HomeStateType.hasPet,
        petSummary: petSummary,
        isLoadingRecommendations: true,
      );

      // 4. 추천 로드
      await _loadRecommendations(petSummary.petId);
    } catch (e) {
      final failure = e is Exception
          ? handleException(e)
          : ServerFailure('알 수 없는 오류가 발생했습니다: ${e.toString()}');
      state = state.copyWith(
        stateType: HomeStateType.error,
        error: failure.message,
      );
    }
  }

  /// 추천 데이터 로드
  Future<void> _loadRecommendations(String petId) async {
    try {
      final recommendations = await _productRepository.getRecommendations(petId);
      state = state.copyWith(
        recommendations: recommendations,
        isLoadingRecommendations: false,
      );
    } catch (e) {
      final failure = e is Exception
          ? handleException(e)
          : ServerFailure('추천 데이터를 불러오는데 실패했습니다.');
      state = state.copyWith(
        isLoadingRecommendations: false,
        error: failure.message,
        // 추천 실패해도 홈은 표시 (pet은 있으므로)
      );
    }
  }

  /// 추천 새로고침
  Future<void> refreshRecommendations() async {
    final petSummary = state.petSummary;
    if (petSummary != null) {
      await _loadRecommendations(petSummary.petId);
    }
  }
}

final homeControllerProvider =
    StateNotifierProvider<HomeController, HomeState>((ref) {
  final productRepository = ref.watch(productRepositoryProvider);
  final petService = ref.watch(petServiceProvider);
  return HomeController(productRepository, petService, ref);
});
