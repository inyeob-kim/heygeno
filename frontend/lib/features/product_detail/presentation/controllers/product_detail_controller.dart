import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/product_repository.dart';
import '../../../../data/models/product_dto.dart';
import '../../../../data/models/product_match_score_dto.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../domain/services/tracking_service.dart';
import '../widgets/ingredient_analysis_section.dart';

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
      // 1. 기본 제품 정보는 먼저 로드 (UI에 필수)
      final product = await _productRepository.getProduct(productId);
      state = state.copyWith(
        isLoading: false,  // 기본 정보 로드 완료 시 로딩 해제
        product: product,
      );
      
      // 2. 나머지 작업들은 병렬로 실행
      // 각 작업의 에러를 독립적으로 처리하여 하나가 실패해도 나머지는 계속 진행
      await Future.wait([
        loadLatestPrice(productId),
        loadIngredientAnalysis(productId),
        _checkFavoriteStatus(productId),
      ], eagerError: false);  // eagerError: false = 하나 실패해도 나머지 계속
      
    } catch (e) {
      // 제품 기본 정보 로드 실패 시에만 에러 처리
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

  /// 최신 가격 불러오기 (껍데기만 - 실제 구현은 나중에)
  Future<void> loadLatestPrice(String productId) async {
    state = state.copyWith(isLoadingLatestPrice: true);
    
    try {
      // TODO: 실제 API 호출로 최신 가격 및 평균 가격 불러오기
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 임시 데이터
      state = state.copyWith(
        isLoadingLatestPrice: false,
        currentPrice: 29000, // TODO: 실제 최신 가격
        averagePrice: 50000, // TODO: 실제 평균 가격 (14일)
        minPrice: 28000, // TODO: 실제 최저가
        maxPrice: 52000, // TODO: 실제 최고가
        purchaseUrl: 'https://www.coupang.com/vp/products/123456', // TODO: 실제 구매 링크
      );
    } catch (e) {
      // 에러 발생 시 로딩만 해제하고 기본값 유지
      print('[ProductDetailController] 가격 정보 로드 실패: $e');
      state = state.copyWith(isLoadingLatestPrice: false);
      // 가격 정보는 null로 유지 (UI에서 처리)
    }
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

  /// 성분 분석 데이터 로드 (임시 데이터)
  Future<void> loadIngredientAnalysis(String productId) async {
    try {
      // TODO: 실제 API 호출로 성분 분석 데이터 불러오기
      await Future.delayed(const Duration(milliseconds: 300));
      
      // 임시 데이터 (나중에 실제 API 응답으로 대체)
      final analysisData = IngredientAnalysisData(
        mainIngredients: [
          '닭고기',
          '옥수수',
          '쌀',
          '동물성 지방',
          '비트펄프',
          '계란',
          '어분',
          '소맥분',
        ],
        nutritionFacts: {
          '조단백질': 28.0,
          '조지방': 15.0,
          '조섬유': 3.5,
          '수분': 10.0,
          '칼슘': 1.2,
          '인': 1.0,
        },
        allergens: [
          '닭고기',
          '계란',
          '옥수수',
        ],
        description: '고품질 단백질과 필수 영양소가 균형있게 함유된 사료입니다. 알레르기 유발 성분이 포함되어 있으니 주의하세요.',
      );
      
      state = state.copyWith(ingredientAnalysis: analysisData);
    } catch (e) {
      print('[ProductDetailController] 성분 분석 로드 실패: $e');
      // 에러 발생해도 기본값(null) 유지
    }
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

  /// 맞춤 점수 로드
  Future<void> loadMatchScore(String productId, String petId) async {
    print('[ProductDetailController] 🎯 loadMatchScore 시작');
    print('[ProductDetailController]   - productId: $productId');
    print('[ProductDetailController]   - petId: $petId');
    
    state = state.copyWith(isLoadingMatchScore: true, error: null);

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
      );
      
      print('[ProductDetailController] ✅ loadMatchScore 완료 - 상태 업데이트됨');
    } catch (e, stackTrace) {
      print('[ProductDetailController] ❌ 맞춤 점수 로드 실패');
      print('[ProductDetailController]   - 에러: $e');
      print('[ProductDetailController]   - StackTrace: $stackTrace');
      // 에러가 발생해도 기본값(null)로 설정 (점수 섹션 숨김)
      state = state.copyWith(
        isLoadingMatchScore: false,
        matchScore: null,
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
