import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/product_repository.dart';
import '../../../../data/models/product_dto.dart';
import '../../../../data/models/product_match_score_dto.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../domain/services/tracking_service.dart';
import '../widgets/ingredient_analysis_section.dart';

class PriceHistoryItem {
  final DateTime date;
  final int price;

  PriceHistoryItem({required this.date, required this.price});
}

class ClaimItem {
  final String claimCode;
  final String? claimDisplayName;
  final int evidenceLevel;
  final String? note;

  ClaimItem({
    required this.claimCode,
    this.claimDisplayName,
    required this.evidenceLevel,
    this.note,
  });
}

class ProductDetailState {
  final ProductDto? product;
  final bool isLoading;
  final bool isTrackingLoading;
  final bool isLoadingLatestPrice;
  final String? error;
  final bool trackingCreated;
  final int? currentPrice; // 최신 가격
  final int? averagePrice; // 평균 가격 (14일)
  final int? minPrice; // 최저가
  final int? maxPrice; // 최고가
  final bool isFavorite; // 관심 사료 추가 여부
  final String? purchaseUrl; // 구매 링크
  final IngredientAnalysisData? ingredientAnalysis; // 성분 분석 데이터
  final ProductMatchScoreDto? matchScore; // 맞춤 점수
  final bool isLoadingMatchScore; // 맞춤 점수 로딩 중
  final String? matchScoreError; // 맞춤 점수 에러 타입 (null, 'no_ingredient_info', 'no_pet', etc.)
  final List<PriceHistoryItem> priceHistory; // 가격 히스토리
  final List<ClaimItem> claims; // 기능성 클레임

  ProductDetailState({
    this.product,
    this.isLoading = false,
    this.isTrackingLoading = false,
    this.isLoadingLatestPrice = false,
    this.error,
    this.trackingCreated = false,
    this.currentPrice,
    this.averagePrice,
    this.minPrice,
    this.maxPrice,
    this.isFavorite = false,
    this.purchaseUrl,
    this.ingredientAnalysis,
    this.matchScore,
    this.isLoadingMatchScore = false,
    this.matchScoreError,
    this.priceHistory = const [],
    this.claims = const [],
  });

  ProductDetailState copyWith({
    ProductDto? product,
    bool? isLoading,
    bool? isTrackingLoading,
    bool? isLoadingLatestPrice,
    String? error,
    bool? trackingCreated,
    int? currentPrice,
    int? averagePrice,
    int? minPrice,
    int? maxPrice,
    bool? isFavorite,
    String? purchaseUrl,
    IngredientAnalysisData? ingredientAnalysis,
    ProductMatchScoreDto? matchScore,
    bool? isLoadingMatchScore,
    String? matchScoreError,
    List<PriceHistoryItem>? priceHistory,
    List<ClaimItem>? claims,
  }) {
    return ProductDetailState(
      product: product ?? this.product,
      isLoading: isLoading ?? this.isLoading,
      isTrackingLoading: isTrackingLoading ?? this.isTrackingLoading,
      isLoadingLatestPrice: isLoadingLatestPrice ?? this.isLoadingLatestPrice,
      error: error ?? this.error,
      trackingCreated: trackingCreated ?? this.trackingCreated,
      currentPrice: currentPrice ?? this.currentPrice,
      averagePrice: averagePrice ?? this.averagePrice,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      isFavorite: isFavorite ?? this.isFavorite,
      purchaseUrl: purchaseUrl ?? this.purchaseUrl,
      ingredientAnalysis: ingredientAnalysis ?? this.ingredientAnalysis,
      matchScore: matchScore ?? this.matchScore,
      isLoadingMatchScore: isLoadingMatchScore ?? this.isLoadingMatchScore,
      matchScoreError: matchScoreError ?? this.matchScoreError,
      priceHistory: priceHistory ?? this.priceHistory,
      claims: claims ?? this.claims,
    );
  }

  /// 평균가 대비 하락 금액 계산
  int? get priceDifference {
    if (currentPrice == null || averagePrice == null) return null;
    return currentPrice! - averagePrice!;
  }
}

class ProductDetailController extends StateNotifier<ProductDetailState> {
  final ProductRepository _productRepository;
  final TrackingService _trackingService;

  ProductDetailController(
    this._productRepository,
    this._trackingService,
  ) : super(ProductDetailState(
    isLoadingMatchScore: false,
  ));

  Future<void> loadProduct(String productId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 상세 정보 조회 (가격, 성분, 영양, 클레임 포함)
      final detail = await _productRepository.getProductDetail(productId);
      
      // 영양 정보 맵 생성
      final nutritionFacts = <String, double>{};
      if (detail.nutrition != null) {
        if (detail.nutrition!.proteinPct != null) {
          nutritionFacts['조단백질'] = detail.nutrition!.proteinPct!;
        }
        if (detail.nutrition!.fatPct != null) {
          nutritionFacts['조지방'] = detail.nutrition!.fatPct!;
        }
        if (detail.nutrition!.fiberPct != null) {
          nutritionFacts['조섬유'] = detail.nutrition!.fiberPct!;
        }
        if (detail.nutrition!.moisturePct != null) {
          nutritionFacts['수분'] = detail.nutrition!.moisturePct!;
        }
        if (detail.nutrition!.calciumPct != null) {
          nutritionFacts['칼슘'] = detail.nutrition!.calciumPct!;
        }
        if (detail.nutrition!.phosphorusPct != null) {
          nutritionFacts['인'] = detail.nutrition!.phosphorusPct!;
        }
      }
      
      // 성분 분석 데이터 생성 (ingredient 또는 nutrition이 있으면 설정)
      IngredientAnalysisData? ingredientData;
      if (detail.ingredient != null || detail.nutrition != null) {
        final mainIngredients = detail.ingredient?.mainIngredients ?? [];
        final allergens = detail.ingredient?.allergens ?? [];
        final description = detail.ingredient?.description;
        
        print('[ProductDetailController] 성분 정보 수신:');
        print('  - mainIngredients: ${mainIngredients.length}개');
        print('  - allergens: ${allergens.length}개');
        print('  - description: ${description != null ? "있음" : "없음"}');
        print('  - nutritionFacts: ${nutritionFacts.length}개');
        
        ingredientData = IngredientAnalysisData(
          mainIngredients: mainIngredients,
          nutritionFacts: nutritionFacts,
          allergens: allergens.isNotEmpty ? allergens : null,
          description: description,
        );
      }
      
      // 가격 히스토리 설정
      final priceHistory = detail.priceHistory.map((h) => PriceHistoryItem(
        date: h.date,
        price: h.price,
      )).toList();
      
      // 기능성 클레임 설정
      final claims = detail.claims.map((c) => ClaimItem(
        claimCode: c.claimCode,
        claimDisplayName: c.claimDisplayName,
        evidenceLevel: c.evidenceLevel,
        note: c.note,
      )).toList();
      
      // 모든 데이터를 한 번에 업데이트
      state = state.copyWith(
        isLoading: false,
        product: detail.product,
        currentPrice: detail.currentPrice,
        averagePrice: detail.averagePrice,
        minPrice: detail.minPrice,
        maxPrice: detail.maxPrice,
        purchaseUrl: detail.purchaseUrl,
        ingredientAnalysis: ingredientData,
        priceHistory: priceHistory,
        claims: claims,
      );
      
      // 나머지 작업들은 병렬로 실행
      await Future.wait([
        _checkFavoriteStatus(productId),
      ], eagerError: false);
      
      // 맞춤 점수 로드 (petId가 있으면)
      // HomeState에서 petId를 가져와서 로드
      // 이 부분은 화면에서 처리하도록 함 (initState의 _maybeRecalculate에서)
      
    } catch (e) {
      final failure = e is Exception
          ? handleException(e)
          : ServerFailure('알 수 없는 오류가 발생했습니다: ${e.toString()}');
      state = state.copyWith(
        isLoading: false,
        error: failure.message,
      );
    }
  }
  
  /// 찜 상태 확인
  Future<void> _checkFavoriteStatus(String productId) async {
    try {
      final isTracked = await _trackingService.checkTrackingStatus(productId);
      state = state.copyWith(isFavorite: isTracked);
    } catch (e) {
      print('[ProductDetailController] 찜 상태 확인 실패: $e');
      // 에러가 발생해도 기본값(false)로 설정
      state = state.copyWith(isFavorite: false);
    }
  }

  /// 최신 가격 불러오기 (이미 loadProduct에서 처리되므로 빈 메서드)
  Future<void> loadLatestPrice(String productId) async {
    // 가격 정보는 loadProduct에서 이미 로드됨
    // 이 메서드는 하위 호환성을 위해 유지
  }

  /// 관심 사료 추가/제거 토글
  Future<void> toggleFavorite() async {
    if (state.product == null) {
      print('[ProductDetailController] toggleFavorite: product가 null');
      return;
    }
    
    print('[ProductDetailController] toggleFavorite 시작: productId=${state.product!.id}');
    
    // Optimistic update: 즉시 UI 업데이트
    final previousFavoriteState = state.isFavorite;
    state = state.copyWith(isFavorite: !state.isFavorite, error: null);
    
    try {
      final productId = state.product!.id;
      final newFavoriteState = await _trackingService.toggleTracking(
        productId: productId,
        currentIsTracked: previousFavoriteState,
      );
      
      // 서비스에서 반환된 상태로 업데이트
      state = state.copyWith(
        isFavorite: newFavoriteState,
        error: null,
      );
      
      print('[ProductDetailController] toggleFavorite 완료: isFavorite=$newFavoriteState');
    } catch (e, stackTrace) {
      print('[ProductDetailController] toggleFavorite 에러: $e');
      print('[ProductDetailController] Stack trace: $stackTrace');
      // 에러 발생 시 이전 상태로 되돌리기
      final failure = e is Exception
          ? handleException(e)
          : ServerFailure('찜하기 기능을 사용하는데 실패했습니다: ${e.toString()}');
      state = state.copyWith(
        isFavorite: previousFavoriteState,
        error: failure.message,
      );
    }
  }

  /// 성분 분석 데이터 로드 (이미 loadProduct에서 처리되므로 빈 메서드)
  Future<void> loadIngredientAnalysis(String productId) async {
    // 성분 분석 데이터는 loadProduct에서 이미 로드됨
    // 이 메서드는 하위 호환성을 위해 유지
  }

  Future<void> createTracking(String productId, String petId) async {
    state = state.copyWith(isTrackingLoading: true, error: null);

    try {
      // TrackingService를 사용하여 찜하기
      final isTracked = await _trackingService.checkTrackingStatus(productId);
      if (!isTracked) {
        await _trackingService.toggleTracking(
          productId: productId,
          currentIsTracked: false,
        );
      }
      
      state = state.copyWith(
        isTrackingLoading: false,
        trackingCreated: true,
      );
    } catch (e) {
      final failure = e is Exception
          ? handleException(e)
          : ServerFailure('알 수 없는 오류가 발생했습니다: ${e.toString()}');
      state = state.copyWith(
        isTrackingLoading: false,
        error: failure.message,
      );
    }
  }

  /// 맞춤 점수 로드 (재시도 로직 포함)
  /// 
  /// @deprecated 새로운 matchScoreProvider를 사용하세요.
  /// 이 메서드는 하위 호환성을 위해 유지되지만, 새로운 코드에서는 사용하지 마세요.
  @Deprecated('Use matchScoreProvider instead')
  Future<void> loadMatchScore(String productId, String petId, {int retryCount = 0}) async {
    print('[ProductDetailController] 🎯 loadMatchScore 시작 (retryCount: $retryCount) [DEPRECATED]');
    print('[ProductDetailController]   - productId: $productId');
    print('[ProductDetailController]   - petId: $petId');
    
    state = state.copyWith(isLoadingMatchScore: true, error: null, matchScoreError: null);

    try {
      print('[ProductDetailController] 📡 API 호출 시작: getProductMatchScore');
      final matchScore = await _productRepository.getProductMatchScore(
        productId: productId,
        petId: petId,
      );
      
      print('[ProductDetailController] ✅ API 호출 성공');
      print('[ProductDetailController]   - matchScore: ${matchScore.matchScore}');
      print('[ProductDetailController]   - safetyScore: ${matchScore.safetyScore}');
      print('[ProductDetailController]   - fitnessScore: ${matchScore.fitnessScore}');
      
      state = state.copyWith(
        isLoadingMatchScore: false,
        matchScore: matchScore,
        matchScoreError: null,
      );
      
      print('[ProductDetailController] ✅ loadMatchScore 완료 - 상태 업데이트됨');
    } catch (e, stackTrace) {
      print('[ProductDetailController] ❌ 맞춤 점수 로드 실패 (retryCount: $retryCount)');
      print('[ProductDetailController]   - 에러: $e');
      print('[ProductDetailController]   - StackTrace: $stackTrace');
      
      // 네트워크 에러이고 재시도 횟수가 2번 미만이면 재시도
      if (retryCount < 2 && e.toString().contains('NetworkException')) {
        print('[ProductDetailController] 🔄 재시도 예정: ${retryCount + 1}/2');
        await Future.delayed(Duration(seconds: 1));
        return loadMatchScore(productId, petId, retryCount: retryCount + 1);
      }
      
      // 에러 타입 구분
      String? errorType;
      final errorString = e.toString();
      // ServerException의 메시지 확인
      if (e is ServerException) {
        final message = e.message.toLowerCase();
        if (message.contains('product ingredient information is not available') ||
            message.contains('ingredient information')) {
          errorType = 'no_ingredient_info';
          print('[ProductDetailController] 📋 에러 타입: 성분 정보 없음');
        }
      } else if (errorString.contains('Product ingredient information is not available') ||
          errorString.contains('ingredient information')) {
        errorType = 'no_ingredient_info';
        print('[ProductDetailController] 📋 에러 타입: 성분 정보 없음');
      }
      
      // 에러가 발생해도 기본값(null)로 설정하되, 에러 타입 저장
      state = state.copyWith(
        isLoadingMatchScore: false,
        matchScore: null,
        matchScoreError: errorType,
      );
    }
  }
}

/// 제품 상세 Provider (Family + AutoDispose)
/// 화면 이탈 시 자동 해제되어 메모리 최적화
final productDetailControllerProvider =
    StateNotifierProvider.autoDispose.family<ProductDetailController, ProductDetailState, String>(
  (ref, productId) {
    final productRepository = ref.watch(productRepositoryProvider);
    final trackingService = ref.watch(trackingServiceProvider);
    return ProductDetailController(productRepository, trackingService);
  },
);
