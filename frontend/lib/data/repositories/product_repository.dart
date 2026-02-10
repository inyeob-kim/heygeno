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

  /// 최근 추천 히스토리 조회 (저장된 히스토리에서 조회)
  Future<RecommendationResponseDto> getRecommendationHistory(String petId, {int limit = 10}) async {
    final startTime = DateTime.now();
    print('[ProductRepository] 📚 히스토리 API 호출 시작: GET ${Endpoints.productRecommendationHistory}?pet_id=$petId&limit=$limit');
    
    try {
      final response = await _apiClient.get(
        Endpoints.productRecommendationHistory,
        queryParameters: {'pet_id': petId, 'limit': limit},
      );

      final duration = DateTime.now().difference(startTime);
      print('[ProductRepository] ✅ 히스토리 API 응답 수신: statusCode=${response.statusCode}, 소요시간=${duration.inMilliseconds}ms');
      
      final data = response.data as Map<String, dynamic>;
      final itemsCount = (data['items'] as List?)?.length ?? 0;
      print('[ProductRepository] 📦 히스토리 응답 데이터: pet_id=${data['pet_id']}, items=$itemsCount개');
      
      final result = RecommendationResponseDto.fromJson(data);
      print('[ProductRepository] ✅ 히스토리 DTO 변환 완료: ${result.items.length}개 추천 상품');
      
      return result;
    } on DioException catch (e) {
      final duration = DateTime.now().difference(startTime);
      print('[ProductRepository] ❌ 히스토리 DioException 발생: type=${e.type}, message=${e.message}, 소요시간=${duration.inMilliseconds}ms');
      if (e.response != null) {
        print('[ProductRepository] ❌ 히스토리 응답 상세: statusCode=${e.response?.statusCode}, data=${e.response?.data}');
      }
      _handleDioException(e);
      rethrow;
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      print('[ProductRepository] ❌ 히스토리 예외 발생: error=$e, 소요시간=${duration.inMilliseconds}ms');
      print('[ProductRepository] ❌ 히스토리 StackTrace: $stackTrace');
      throw ServerException('추천 히스토리를 불러오는데 실패했습니다: ${e.toString()}');
    }
  }

  /// 추천 상품 목록 조회 (실시간 계산)
  Future<RecommendationResponseDto> getRecommendations(String petId) async {
    final startTime = DateTime.now();
    print('[ProductRepository] 🌐 API 호출 시작: GET ${Endpoints.productRecommendations}?pet_id=$petId');
    
    try {
      final response = await _apiClient.get(
        Endpoints.productRecommendations,
        queryParameters: {'pet_id': petId},
      );

      final duration = DateTime.now().difference(startTime);
      print('[ProductRepository] ✅ API 응답 수신: statusCode=${response.statusCode}, 소요시간=${duration.inMilliseconds}ms');
      
      final data = response.data as Map<String, dynamic>;
      final itemsCount = (data['items'] as List?)?.length ?? 0;
      print('[ProductRepository] 📦 응답 데이터: pet_id=${data['pet_id']}, items=$itemsCount개');
      
      final result = RecommendationResponseDto.fromJson(data);
      print('[ProductRepository] ✅ DTO 변환 완료: ${result.items.length}개 추천 상품');
      
      return result;
    } on DioException catch (e) {
      final duration = DateTime.now().difference(startTime);
      print('[ProductRepository] ❌ DioException 발생: type=${e.type}, message=${e.message}, 소요시간=${duration.inMilliseconds}ms');
      if (e.response != null) {
        print('[ProductRepository] ❌ 응답 상세: statusCode=${e.response?.statusCode}, data=${e.response?.data}');
      }
      _handleDioException(e);
      rethrow;
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      print('[ProductRepository] ❌ 예외 발생: error=$e, 소요시간=${duration.inMilliseconds}ms');
      print('[ProductRepository] ❌ StackTrace: $stackTrace');
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
