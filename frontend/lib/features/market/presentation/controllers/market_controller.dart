import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/product_repository.dart';
import '../../../../data/models/product_dto.dart';
import '../widgets/product_card.dart';
import '../widgets/category_chips.dart';

/// 마켓 화면 상태
class MarketState {
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final List<ProductCardData> hotDealProducts;
  final List<ProductCardData> popularProducts;
  final List<ProductCardData> allProducts;
  final List<CategoryChipData> categories;
  final String? selectedCategoryId;
  final String? searchQuery;

  MarketState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.hotDealProducts = const [],
    this.popularProducts = const [],
    this.allProducts = const [],
    this.categories = const [],
    this.selectedCategoryId,
    this.searchQuery,
  });

  MarketState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    List<ProductCardData>? hotDealProducts,
    List<ProductCardData>? popularProducts,
    List<ProductCardData>? allProducts,
    List<CategoryChipData>? categories,
    String? selectedCategoryId,
    String? searchQuery,
  }) {
    return MarketState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error ?? this.error,
      hotDealProducts: hotDealProducts ?? this.hotDealProducts,
      popularProducts: popularProducts ?? this.popularProducts,
      allProducts: allProducts ?? this.allProducts,
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// 마켓 화면 컨트롤러
/// 단일 책임: 상품 목록 관리
class MarketController extends StateNotifier<MarketState> {
  final ProductRepository _productRepository;

  MarketController(ProductRepository productRepository)
      : _productRepository = productRepository,
        super(MarketState()) {
    _initialize();
  }

  /// 초기화
  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final products = await _productRepository.getProducts();
      final productCards = _convertToProductCards(products);
      
      state = state.copyWith(
        isLoading: false,
        allProducts: productCards,
        hotDealProducts: productCards.take(5).toList(), // 임시: 상위 5개
        popularProducts: productCards.take(5).toList(), // 임시: 상위 5개
        categories: _generateCategories(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '상품 목록을 불러오는데 실패했습니다: ${e.toString()}',
      );
    }
  }

  /// 새로고침
  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, error: null);
    
    try {
      final products = await _productRepository.getProducts();
      final productCards = _convertToProductCards(products);
      
      state = state.copyWith(
        isRefreshing: false,
        allProducts: productCards,
        hotDealProducts: productCards.take(5).toList(),
        popularProducts: productCards.take(5).toList(),
      );
    } catch (e) {
      state = state.copyWith(
        isRefreshing: false,
        error: '상품 목록을 불러오는데 실패했습니다: ${e.toString()}',
      );
    }
  }

  /// ProductDto를 ProductCardData로 변환
  List<ProductCardData> _convertToProductCards(List<ProductDto> products) {
    return products.map((product) {
      return ProductCardData(
        id: product.id,
        brandName: product.brandName,
        productName: product.productName,
        price: 0, // TODO: ProductOffer에서 가격 정보 가져오기 (API 확장 필요)
        imageUrl: null, // TODO: 상품 이미지 URL 추가
      );
    }).toList();
  }

  /// 카테고리 선택
  void selectCategory(String? categoryId) {
    state = state.copyWith(selectedCategoryId: categoryId);
    // TODO: 백엔드에 카테고리 필터 API 추가 시 구현
  }

  /// 검색 쿼리 설정
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    // TODO: 백엔드에 검색 API 추가 시 구현
  }

  List<CategoryChipData> _generateCategories() {
    return [
      CategoryChipData(id: 'all', label: '전체'),
      CategoryChipData(id: 'dog', label: '강아지', icon: Icons.pets),
      CategoryChipData(id: 'cat', label: '고양이', icon: Icons.pets),
      CategoryChipData(id: 'puppy', label: '퍼피'),
      CategoryChipData(id: 'adult', label: '어덜트'),
      CategoryChipData(id: 'senior', label: '시니어'),
    ];
  }
}

final marketControllerProvider =
    StateNotifierProvider<MarketController, MarketState>((ref) {
  final productRepository = ref.watch(productRepositoryProvider);
  return MarketController(productRepository);
});
