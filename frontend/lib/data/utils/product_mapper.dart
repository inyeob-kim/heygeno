import '../models/product_dto.dart';
import '../models/recommendation_dto.dart';
import '../../ui/widgets/figma_product_tile.dart';

/// ProductDto를 UI 모델로 변환하는 유틸리티
/// 단일 책임: 데이터 변환
class ProductMapper {
  /// ProductDto를 ProductTileData로 변환
  static ProductTileData toProductTileData(ProductDto product) {
    return ProductTileData(
      id: product.id,
      name: product.productName,
      brand: product.brandName,
      price: 0, // TODO: ProductOffer에서 가격 정보 가져오기
      image: '', // TODO: 상품 이미지 URL 추가
      isWatched: false,
    );
  }

  /// RecommendationItemDto를 ProductTileData로 변환
  static ProductTileData toProductTileDataFromRecommendation(RecommendationItemDto item) {
    final product = item.product;
    return ProductTileData(
      id: product.id,
      name: product.productName,
      brand: product.brandName,
      price: item.currentPrice,
      avgPrice: item.avgPrice,
      image: '', // TODO: 상품 이미지 URL 추가
      isWatched: false,
      badge: item.isNewLow ? '최저가' : null,
    );
  }
}
