import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/services/pet_service.dart';
import '../../../../domain/services/recommendation_service.dart';
import '../../../../data/models/pet_summary_dto.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/error_handler.dart';

/// 최근 추천 아이템 데이터
class RecentRecommendationData {
  final String productId;
  final String productName;
  final String brandName;
  final int? matchScore;
  final int? price;
  final DateTime? recommendedAt;

  RecentRecommendationData({
    required this.productId,
    required this.productName,
    required this.brandName,
    this.matchScore,
    this.price,
    this.recommendedAt,
  });
}

/// 마이 화면 상태
class MyState {
  final bool isLoading;
  final String? error;
  final PetSummaryDto? petSummary;
  final List<PetSummaryDto> pets; // 모든 펫 목록
  final List<RecentRecommendationData> recentRecommendations;
  final int totalPoints; // TODO: 포인트 API 추가 시 사용

  const MyState({
    this.isLoading = false,
    this.error,
    this.petSummary,
    this.pets = const [],
    this.recentRecommendations = const [],
    this.totalPoints = 0,
  });

  MyState copyWith({
    bool? isLoading,
    String? error,
    PetSummaryDto? petSummary,
    List<PetSummaryDto>? pets,
    List<RecentRecommendationData>? recentRecommendations,
    int? totalPoints,
  }) {
    return MyState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      petSummary: petSummary ?? this.petSummary,
      pets: pets ?? this.pets,
      recentRecommendations: recentRecommendations ?? this.recentRecommendations,
      totalPoints: totalPoints ?? this.totalPoints,
    );
  }
}

/// 마이 화면 컨트롤러
/// 단일 책임: 사용자 프로필 및 최근 추천 데이터 관리
class MyController extends StateNotifier<MyState> {
  final PetService _petService;
  final RecommendationService _recommendationService;

  MyController(this._petService, this._recommendationService)
      : super(MyState()) {
    _initialize();
  }

  /// 초기화
  Future<void> _initialize() async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      pets: const [], // 초기화 시 빈 리스트로 명시적으로 설정
    );

    try {
      // 1. 모든 펫 목록 조회
      print('[MyController] 모든 펫 목록 조회 시작');
      final petsList = await _petService.getAllPetSummaries();
      print('[MyController] 펫 목록 조회 완료: ${petsList.length}개');
      
      // 2. Primary Pet을 첫 번째로 정렬
      final sortedPetsList = List<PetSummaryDto>.from(petsList)
        ..sort((a, b) {
          final aIsPrimary = a.isPrimary ?? false;
          final bIsPrimary = b.isPrimary ?? false;
          if (aIsPrimary && !bIsPrimary) return -1;
          if (!aIsPrimary && bIsPrimary) return 1;
          return 0;
        });
      
      // 3. Primary Pet 찾기 (isPrimary 필드 사용)
      PetSummaryDto? petSummary;
      try {
        petSummary = sortedPetsList.firstWhere((pet) => pet.isPrimary ?? false);
      } catch (e) {
        // isPrimary가 true인 펫이 없으면 첫 번째 펫 사용
        petSummary = sortedPetsList.isNotEmpty ? sortedPetsList.first : null;
      }
      print('[MyController] Primary Pet: ${petSummary?.name ?? "없음"}');

      // 3. 최근 추천 조회 (Pet이 있는 경우) - 병렬 처리로 성능 개선
      if (petSummary != null) {
        try {
          // 추천 API 호출을 별도로 실행하여 펫 정보 로딩 후 바로 화면 표시 가능하도록
          _loadRecommendations(petSummary.petId);
        } catch (e) {
          // 추천 실패해도 계속 진행
          print('[MyController] 추천 조회 실패: $e');
        }
      }

      // 펫 정보만 먼저 표시하여 로딩 시간 단축
      state = state.copyWith(
        isLoading: false,
        petSummary: petSummary,
        pets: sortedPetsList,
        recentRecommendations: const [],
      );
    } catch (e) {
      final failure = e is Exception
          ? handleException(e)
          : ServerFailure('프로필을 불러오는데 실패했습니다: ${e.toString()}');
      state = state.copyWith(
        isLoading: false,
        error: failure.message,
        pets: const [], // 에러 시에도 빈 리스트로 명시적으로 설정
      );
    }
  }

  /// 추천 데이터를 비동기로 로드 (히스토리에서 조회)
  Future<void> _loadRecommendations(String petId) async {
    try {
      // 히스토리에서 최근 추천 조회 (빠름)
      final recommendations = await _recommendationService.getRecommendationHistory(
        petId: petId,
        limit: 3,
      );
      final recentRecommendations = recommendations.items
          .take(3)
          .map((item) => RecentRecommendationData(
                productId: item.product.id,
                productName: item.product.productName,
                brandName: item.product.brandName,
                price: item.currentPrice,
                matchScore: item.matchScore.toInt(),
                recommendedAt: null, // 히스토리에서는 시간 정보 없음
              ))
          .toList();

      // 추천 데이터가 로드되면 상태 업데이트
      state = state.copyWith(
        recentRecommendations: recentRecommendations,
      );
    } catch (e) {
      // 추천 실패해도 화면은 계속 표시
      print('[MyController] 추천 히스토리 조회 실패: $e');
    }
  }

  /// 새로고침
  Future<void> refresh() async {
    await _initialize();
  }
}

final myControllerProvider =
    StateNotifierProvider<MyController, MyState>((ref) {
  final petService = ref.watch(petServiceProvider);
  final recommendationService = ref.watch(recommendationServiceProvider);
  return MyController(petService, recommendationService);
});
