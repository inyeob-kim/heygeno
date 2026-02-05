import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/services/pet_service.dart';
import '../../../../data/repositories/product_repository.dart';
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
  final List<RecentRecommendationData> recentRecommendations;
  final int totalPoints; // TODO: 포인트 API 추가 시 사용

  const MyState({
    this.isLoading = false,
    this.error,
    this.petSummary,
    this.recentRecommendations = const [],
    this.totalPoints = 0,
  });

  MyState copyWith({
    bool? isLoading,
    String? error,
    PetSummaryDto? petSummary,
    List<RecentRecommendationData>? recentRecommendations,
    int? totalPoints,
  }) {
    return MyState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      petSummary: petSummary ?? this.petSummary,
      recentRecommendations: recentRecommendations ?? this.recentRecommendations,
      totalPoints: totalPoints ?? this.totalPoints,
    );
  }
}

/// 마이 화면 컨트롤러
/// 단일 책임: 사용자 프로필 및 최근 추천 데이터 관리
class MyController extends StateNotifier<MyState> {
  final PetService _petService;
  final ProductRepository _productRepository;

  MyController(this._petService, this._productRepository)
      : super(MyState()) {
    _initialize();
  }

  /// 초기화
  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 1. Primary Pet 조회
      final petSummary = await _petService.getPrimaryPetSummary();

      // 2. 최근 추천 조회 (Pet이 있는 경우)
      List<RecentRecommendationData> recentRecommendations = [];
      if (petSummary != null) {
        try {
          final recommendations = await _productRepository.getRecommendations(
            petSummary.petId,
          );
          recentRecommendations = recommendations.items
              .take(3)
              .map((item) => RecentRecommendationData(
                    productId: item.product.id,
                    productName: item.product.productName,
                    brandName: item.product.brandName,
                    price: item.currentPrice,
                    // TODO: matchScore는 백엔드에서 제공되면 추가
                    recommendedAt: DateTime.now(), // TODO: 실제 추천 시간
                  ))
              .toList();
        } catch (e) {
          // 추천 실패해도 계속 진행
          print('[MyController] 추천 조회 실패: $e');
        }
      }

      state = state.copyWith(
        isLoading: false,
        petSummary: petSummary,
        recentRecommendations: recentRecommendations,
      );
    } catch (e) {
      final failure = e is Exception
          ? handleException(e)
          : ServerFailure('프로필을 불러오는데 실패했습니다: ${e.toString()}');
      state = state.copyWith(
        isLoading: false,
        error: failure.message,
      );
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
  final productRepository = ref.watch(productRepositoryProvider);
  return MyController(petService, productRepository);
});
