import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/endpoints.dart';
import '../../core/error/exceptions.dart';
import '../models/tracking_dto.dart';

/// 가격 추적 관련 데이터 레포지토리
/// 단일 책임: 추적 데이터 CRUD
class TrackingRepository {
  final ApiClient _apiClient;

  TrackingRepository(this._apiClient);

  /// 추적 목록 조회
  Future<List<TrackingDto>> getTrackings() async {
    try {
      final response = await _apiClient.get(Endpoints.trackings);
      
      if (response.data is List) {
        return (response.data as List)
            .map((json) => TrackingDto.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    } catch (e) {
      throw ServerException('추적 목록을 불러오는데 실패했습니다: ${e.toString()}');
    }
  }

  /// 추적 생성
  Future<TrackingDto> createTracking({
    required String productId,
    required String petId,
    int? targetPrice,
  }) async {
    try {
      final response = await _apiClient.post(
        Endpoints.trackings,
        data: {
          'product_id': productId,
          'pet_id': petId,
          if (targetPrice != null) 'target_price': targetPrice,
        },
      );

      return TrackingDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    } catch (e) {
      throw ServerException('추적을 생성하는데 실패했습니다: ${e.toString()}');
    }
  }

  /// 추적 삭제
  Future<void> deleteTracking(String trackingId) async {
    try {
      await _apiClient.delete(Endpoints.tracking(trackingId));
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    } catch (e) {
      throw ServerException('추적을 삭제하는데 실패했습니다: ${e.toString()}');
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

final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TrackingRepository(apiClient);
});
