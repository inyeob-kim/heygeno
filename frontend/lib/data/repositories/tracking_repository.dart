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
            .map((item) {
              // 각 항목이 Map인지 확인
              if (item is! Map<String, dynamic>) {
                print('[TrackingRepository] getTrackings: 예상하지 못한 항목 타입: ${item.runtimeType}');
                return null;
              }
              
              // UUID 필드를 문자열로 변환
              final jsonData = Map<String, dynamic>.from(item);
              if (jsonData['id'] != null) {
                jsonData['id'] = jsonData['id'].toString();
              }
              if (jsonData['pet_id'] != null) {
                jsonData['pet_id'] = jsonData['pet_id'].toString();
              }
              if (jsonData['product_id'] != null) {
                jsonData['product_id'] = jsonData['product_id'].toString();
              }
              
              try {
                return TrackingDto.fromJson(jsonData);
              } catch (e, stackTrace) {
                print('[TrackingRepository] getTrackings: TrackingDto 파싱 에러: $e');
                print('[TrackingRepository] getTrackings: Stack trace: $stackTrace');
                print('[TrackingRepository] getTrackings: 문제가 된 데이터: $jsonData');
                return null;
              }
            })
            .whereType<TrackingDto>() // null 제거
            .toList();
      }
      return [];
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    } catch (e, stackTrace) {
      print('[TrackingRepository] getTrackings 에러: $e');
      print('[TrackingRepository] getTrackings Stack trace: $stackTrace');
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

      // 응답 데이터 타입 확인 및 변환
      final responseData = response.data;
      print('[TrackingRepository] createTracking 응답 데이터 타입: ${responseData.runtimeType}');
      print('[TrackingRepository] createTracking 응답 데이터: $responseData');
      
      if (responseData is! Map<String, dynamic>) {
        throw ServerException('예상하지 못한 응답 형식입니다: ${responseData.runtimeType}');
      }
      
      // UUID 필드를 문자열로 변환
      final jsonData = Map<String, dynamic>.from(responseData);
      if (jsonData['id'] != null) {
        jsonData['id'] = jsonData['id'].toString();
      }
      if (jsonData['pet_id'] != null) {
        jsonData['pet_id'] = jsonData['pet_id'].toString();
      }
      if (jsonData['product_id'] != null) {
        jsonData['product_id'] = jsonData['product_id'].toString();
      }
      
      return TrackingDto.fromJson(jsonData);
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    } catch (e, stackTrace) {
      print('[TrackingRepository] createTracking 에러: $e');
      print('[TrackingRepository] Stack trace: $stackTrace');
      throw ServerException('추적을 생성하는데 실패했습니다: ${e.toString()}');
    }
  }

  /// 추적 삭제
  Future<void> deleteTracking(String trackingId) async {
    try {
      print('[TrackingRepository] deleteTracking 시작: trackingId=$trackingId');
      final response = await _apiClient.delete(Endpoints.tracking(trackingId));
      print('[TrackingRepository] deleteTracking 완료: statusCode=${response.statusCode}');
    } on DioException catch (e) {
      print('[TrackingRepository] deleteTracking DioException: ${e.message}');
      print('[TrackingRepository] deleteTracking statusCode: ${e.response?.statusCode}');
      print('[TrackingRepository] deleteTracking response: ${e.response?.data}');
      _handleDioException(e);
      rethrow;
    } catch (e, stackTrace) {
      print('[TrackingRepository] deleteTracking 에러: $e');
      print('[TrackingRepository] Stack trace: $stackTrace');
      throw ServerException('추적을 삭제하는데 실패했습니다: ${e.toString()}');
    }
  }

  /// product_id와 pet_id로 tracking 찾기
  Future<TrackingDto?> findTrackingByProductAndPet({
    required String productId,
    required String petId,
  }) async {
    try {
      final trackings = await getTrackings();
      print('[TrackingRepository] findTrackingByProductAndPet: 전체 tracking 개수=${trackings.length}, 찾는 productId=$productId, petId=$petId');
      
      final matching = trackings.where(
        (tracking) => tracking.productId == productId && tracking.petId == petId,
      ).toList();
      
      if (matching.isEmpty) {
        print('[TrackingRepository] findTrackingByProductAndPet: 매칭되는 tracking 없음');
        return null;
      }
      
      print('[TrackingRepository] findTrackingByProductAndPet: 매칭되는 tracking 찾음: ${matching.first.id}');
      return matching.first;
    } catch (e, stackTrace) {
      print('[TrackingRepository] findTrackingByProductAndPet 에러: $e');
      print('[TrackingRepository] Stack trace: $stackTrace');
      return null;
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
      } else if (statusCode == 400) {
        // 400 Bad Request - 중복 생성 등의 클라이언트 오류
        if (message.contains('already exists') || message.contains('Tracking already exists')) {
          throw ServerException('이미 찜한 상품입니다.');
        }
        throw ServerException(message);
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
