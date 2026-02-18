import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/endpoints.dart';
import '../../core/error/exceptions.dart';
import '../models/recommendation_dto.dart';
import '../models/product_dto.dart';
import '../models/product_detail_dto.dart';
import '../models/product_match_score_dto.dart';

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

  /// 전체 추천 캐시 제거 (모든 펫의 캐시)
  Future<Map<String, dynamic>> clearAllRecommendationCache() async {
    final startTime = DateTime.now();
    print('[ProductRepository] 🗑️ 전체 캐시 제거 API 호출 시작: DELETE ${Endpoints.productRecommendationCacheAll}');
    
    try {
      final response = await _apiClient.delete(
        Endpoints.productRecommendationCacheAll,
      );

      final duration = DateTime.now().difference(startTime);
      print('[ProductRepository] ✅ 전체 캐시 제거 완료: statusCode=${response.statusCode}, 소요시간=${duration.inMilliseconds}ms');
      
      final data = response.data as Map<String, dynamic>;
      final deletedRuns = data['deleted_runs'] as int? ?? 0;
      final redisKeysDeleted = data['redis_keys_deleted'] as int? ?? 0;
      print('[ProductRepository] 📦 삭제된 캐시: PostgreSQL=$deletedRuns개, Redis=$redisKeysDeleted개');
      
      return data;
    } on DioException catch (e) {
      final duration = DateTime.now().difference(startTime);
      print('[ProductRepository] ❌ 전체 캐시 제거 DioException 발생: type=${e.type}, message=${e.message}, 소요시간=${duration.inMilliseconds}ms');
      if (e.response != null) {
        print('[ProductRepository] ❌ 응답 상세: statusCode=${e.response?.statusCode}, data=${e.response?.data}');
      }
      _handleDioException(e);
      rethrow;
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      print('[ProductRepository] ❌ 전체 캐시 제거 예외 발생: error=$e, 소요시간=${duration.inMilliseconds}ms');
      print('[ProductRepository] ❌ StackTrace: $stackTrace');
      throw ServerException('전체 추천 캐시를 제거하는데 실패했습니다: ${e.toString()}');
    }
  }

  /// 추천 캐시 제거 (추천 재계산 없이 캐시만 삭제)
  Future<void> clearRecommendationCache(String petId) async {
    final startTime = DateTime.now();
    print('[ProductRepository] 🗑️ 캐시 제거 API 호출 시작: DELETE ${Endpoints.productRecommendationCache}?pet_id=$petId');
    
    try {
      final response = await _apiClient.delete(
        Endpoints.productRecommendationCache,
        queryParameters: {'pet_id': petId},
      );

      final duration = DateTime.now().difference(startTime);
      print('[ProductRepository] ✅ 캐시 제거 완료: statusCode=${response.statusCode}, 소요시간=${duration.inMilliseconds}ms');
      
      final data = response.data as Map<String, dynamic>;
      final deletedCount = data['deleted_runs'] as int? ?? 0;
      print('[ProductRepository] 📦 삭제된 캐시: $deletedCount개');
    } on DioException catch (e) {
      final duration = DateTime.now().difference(startTime);
      print('[ProductRepository] ❌ 캐시 제거 DioException 발생: type=${e.type}, message=${e.message}, 소요시간=${duration.inMilliseconds}ms');
      if (e.response != null) {
        print('[ProductRepository] ❌ 응답 상세: statusCode=${e.response?.statusCode}, data=${e.response?.data}');
      }
      _handleDioException(e);
      rethrow;
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      print('[ProductRepository] ❌ 캐시 제거 예외 발생: error=$e, 소요시간=${duration.inMilliseconds}ms');
      print('[ProductRepository] ❌ StackTrace: $stackTrace');
      throw ServerException('추천 캐시를 제거하는데 실패했습니다: ${e.toString()}');
    }
  }

  /// 추천 상품 목록 조회 (실시간 계산, 항상 RAG 실행)
  Future<RecommendationResponseDto> getRecommendations(
    String petId, {
    bool forceRefresh = false,
    bool generateExplanationOnly = false,
    int? minDailyAmount,
    int? maxDailyAmount,
    int? maxMonthlyBudget,
    List<String>? emphasizedConcerns,
    bool healthConcernPriority = false,
  }) async {
    final startTime = DateTime.now();
    
    print('[ProductRepository] 📥 getRecommendations 호출');
    print('[ProductRepository]   - petId: $petId');
    print('[ProductRepository]   - forceRefresh: $forceRefresh');
    print('[ProductRepository]   - generateExplanationOnly: $generateExplanationOnly');
    print('[ProductRepository]   - minDailyAmount: ${minDailyAmount ?? "null"}g');
    print('[ProductRepository]   - maxDailyAmount: ${maxDailyAmount ?? "null"}g');
    print('[ProductRepository]   - maxMonthlyBudget: ${maxMonthlyBudget != null ? "${maxMonthlyBudget}원" : "null"}');
    print('[ProductRepository]   - emphasizedConcerns: ${emphasizedConcerns?.join(", ") ?? "null"}');
    print('[ProductRepository]   - healthConcernPriority: $healthConcernPriority');
    
    // 쿼리 파라미터 구성
    final queryParams = <String, dynamic>{
      'pet_id': petId,
      'force_refresh': forceRefresh,
      'generate_explanation_only': generateExplanationOnly,
    };
    
    // 선택적 파라미터 추가
    if (minDailyAmount != null) {
      queryParams['min_daily_amount'] = minDailyAmount;
      print('[ProductRepository] ✅ min_daily_amount 추가: $minDailyAmount');
    }
    if (maxDailyAmount != null) {
      queryParams['max_daily_amount'] = maxDailyAmount;
      print('[ProductRepository] ✅ max_daily_amount 추가: $maxDailyAmount');
    }
    if (maxMonthlyBudget != null) {
      queryParams['max_monthly_budget'] = maxMonthlyBudget;
      print('[ProductRepository] ✅ max_monthly_budget 추가: $maxMonthlyBudget');
    }
    if (emphasizedConcerns != null && emphasizedConcerns.isNotEmpty) {
      queryParams['emphasized_concerns'] = emphasizedConcerns.join(',');
      print('[ProductRepository] ✅ emphasized_concerns 추가: ${emphasizedConcerns.join(",")}');
    }
    if (healthConcernPriority) {
      queryParams['health_concern_priority'] = healthConcernPriority;
      print('[ProductRepository] ✅ health_concern_priority 추가: $healthConcernPriority');
    }
    
    print('[ProductRepository] 🌐 API 호출 시작: GET ${Endpoints.productRecommendations}');
    print('[ProductRepository] 📋 최종 쿼리 파라미터: $queryParams');
    
    try {
      final response = await _apiClient.get(
        Endpoints.productRecommendations,
        queryParameters: queryParams,
      );

      final duration = DateTime.now().difference(startTime);
      print('[ProductRepository] ✅ API 응답 수신: statusCode=${response.statusCode}, 소요시간=${duration.inMilliseconds}ms');
      
      final data = response.data as Map<String, dynamic>;
      
      // 디버깅: 응답 데이터 확인
      if (generateExplanationOnly && data.containsKey('items') && (data['items'] as List).isNotEmpty) {
        final firstItem = (data['items'] as List).first as Map<String, dynamic>;
        print('[ProductRepository] 🔍 응답 데이터 확인:');
        print('[ProductRepository] 🔍 expert_explanation: ${firstItem['expert_explanation']?.toString().substring(0, 50) ?? "null"}...');
        print('[ProductRepository] 🔍 technical_explanation: ${firstItem['technical_explanation']?.toString().substring(0, 50) ?? "null"}...');
        print('[ProductRepository] 🔍 explanation: ${firstItem['explanation']?.toString().substring(0, 50) ?? "null"}...');
      }
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

  /// 상품 상세 정보 조회 (가격, 성분, 영양, 클레임 포함)
  Future<ProductDetailDto> getProductDetail(String productId) async {
    try {
      final response = await _apiClient.get(Endpoints.productDetail(productId));
      return ProductDetailDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    } catch (e) {
      throw ServerException('상품 상세 정보를 불러오는데 실패했습니다: ${e.toString()}');
    }
  }

  /// 특정 상품의 맞춤 점수 계산
  Future<ProductMatchScoreDto> getProductMatchScore({
    required String productId,
    required String petId,
  }) async {
    final startTime = DateTime.now();
    print('[ProductRepository] 🎯 맞춤 점수 계산 API 호출 시작: GET ${Endpoints.productMatchScore(productId)}?pet_id=$petId');
    
    try {
      final response = await _apiClient.get(
        Endpoints.productMatchScore(productId),
        queryParameters: {'pet_id': petId},
      );

      final duration = DateTime.now().difference(startTime);
      print('[ProductRepository] ✅ 맞춤 점수 계산 완료: statusCode=${response.statusCode}, 소요시간=${duration.inMilliseconds}ms');
      
      final data = response.data as Map<String, dynamic>;
      final matchScore = data['match_score'] as double? ?? 0.0;
      print('[ProductRepository] 📦 맞춤 점수: match_score=$matchScore, safety_score=${data['safety_score']}, fitness_score=${data['fitness_score']}');
      
      final result = ProductMatchScoreDto.fromJson(data);
      print('[ProductRepository] ✅ DTO 변환 완료: match_score=${result.matchScore}');
      
      return result;
    } on DioException catch (e) {
      final duration = DateTime.now().difference(startTime);
      print('[ProductRepository] ❌ 맞춤 점수 계산 DioException 발생: type=${e.type}, message=${e.message}, 소요시간=${duration.inMilliseconds}ms');
      if (e.response != null) {
        print('[ProductRepository] ❌ 응답 상세: statusCode=${e.response?.statusCode}, data=${e.response?.data}');
      }
      _handleDioException(e);
      rethrow;
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      print('[ProductRepository] ❌ 맞춤 점수 계산 예외 발생: error=$e, 소요시간=${duration.inMilliseconds}ms');
      print('[ProductRepository] ❌ StackTrace: $stackTrace');
      throw ServerException('맞춤 점수를 계산하는데 실패했습니다: ${e.toString()}');
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
