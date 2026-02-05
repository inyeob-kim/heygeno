import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/endpoints.dart';
import '../../core/error/exceptions.dart';
import '../models/recommendation_dto.dart';
import '../models/product_dto.dart';

/// 상품 관련 데이터 레포지토리
/// 단일 책임: 상품 및 추천 데이터 조회
class ProductRepository {
  final ApiClient _apiClient;

  ProductRepository(this._apiClient);

  /// 상품 목록 조회
  Future<List<ProductDto>> getProducts() async {
    try {
      final response = await _apiClient.get(Endpoints.products);
      
      if (response.data is List) {
        return (response.data as List)
            .map((json) => ProductDto.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    } catch (e) {
      throw ServerException('상품 목록을 불러오는데 실패했습니다: ${e.toString()}');
    }
  }

  /// 추천 상품 목록 조회
  Future<RecommendationResponseDto> getRecommendations(String petId) async {
    try {
      final response = await _apiClient.get(
        Endpoints.productRecommendations,
        queryParameters: {'pet_id': petId},
      );

      return RecommendationResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    } catch (e) {
      throw ServerException('추천 상품을 불러오는데 실패했습니다: ${e.toString()}');
    }
  }

  /// 상품 상세 정보 조회
  Future<ProductDto> getProduct(String productId) async {
    try {
      final response = await _apiClient.get(Endpoints.product(productId));
      return ProductDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    } catch (e) {
      throw ServerException('상품 정보를 불러오는데 실패했습니다: ${e.toString()}');
    }
  }

  /// DioException 처리
  void _handleDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      throw NetworkException('네트워크 연결 시간이 초과되었습니다.');
    } else if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final message = e.response?.data?['detail'] as String? ?? '서버 오류가 발생했습니다.';
      
      if (statusCode == 404) {
        throw NotFoundException(message);
      } else {
        throw ServerException(message);
      }
    } else {
      throw NetworkException('네트워크 오류가 발생했습니다.');
    }
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProductRepository(apiClient);
});
