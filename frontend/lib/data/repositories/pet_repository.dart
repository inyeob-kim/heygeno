import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/endpoints.dart';
import '../../core/error/exceptions.dart';
import '../../core/constants/enums.dart';
import '../models/pet_dto.dart';

class PetRepository {
  final ApiClient _apiClient;

  PetRepository(this._apiClient);

  Future<PetDto> createPet({
    required String breedCode,
    required String weightBucket,
    required String ageStage,
    bool isPrimary = false,
  }) async {
    try {
      final response = await _apiClient.post(
        Endpoints.pets,
        data: {
          'breed_code': breedCode,
          'weight_bucket_code': weightBucket,
          'age_stage': ageStage,
          'is_primary': isPrimary,
        },
      );

      // 응답 데이터 타입 확인 및 변환
      final responseData = response.data;
      
      // 디버깅: 응답 데이터 출력
      print('[PetRepository] Response data type: ${responseData.runtimeType}');
      print('[PetRepository] Response data: $responseData');
      
      if (responseData is! Map<String, dynamic>) {
        throw ServerException('서버 응답 형식이 올바르지 않습니다. 타입: ${responseData.runtimeType}');
      }

      try {
        return PetDto.fromJson(responseData);
      } catch (e, stackTrace) {
        print('[PetRepository] JSON 파싱 에러: $e');
        print('[PetRepository] Stack trace: $stackTrace');
        print('[PetRepository] 문제가 된 데이터: $responseData');
        rethrow;
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw NetworkException('네트워크 연결 시간이 초과되었습니다.');
      } else if (e.response != null) {
        throw ServerException(
          e.response?.data['detail'] as String? ?? '서버 오류가 발생했습니다.',
        );
      } else {
        throw NetworkException('네트워크 오류가 발생했습니다.');
      }
    } catch (e) {
      if (e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw ServerException('알 수 없는 오류가 발생했습니다.');
    }
  }

  /// 펫 프로필 업데이트 (변할 수 있는 정보만)
  Future<PetDto> updatePet({
    required String petId,
    double? weightKg,
    bool? isNeutered,
    List<String>? healthConcerns,
    List<String>? foodAllergies,
    String? otherAllergies,
  }) async {
    try {
      final data = <String, dynamic>{};
      
      if (weightKg != null) {
        data['weight_kg'] = weightKg;
      }
      if (isNeutered != null) {
        data['is_neutered'] = isNeutered;
      }
      if (healthConcerns != null) {
        data['health_concerns'] = healthConcerns;
        print('[PetRepository] 건강 고민 전송: $healthConcerns');
      }
      if (foodAllergies != null) {
        data['food_allergies'] = foodAllergies;
        print('[PetRepository] 음식 알레르기 전송: $foodAllergies');
      }
      if (otherAllergies != null) {
        data['other_allergies'] = otherAllergies;
      }

      print('[PetRepository] 펫 업데이트 요청: petId=$petId, data=$data');
      final response = await _apiClient.patch(
        Endpoints.pet(petId),
        data: data,
      );

      // 백엔드는 PetSummaryResponse를 반환하지만, 
      // PetDto에는 health_concerns, food_allergies 필드가 없어서 파싱 오류 발생 가능
      // 실제 데이터는 loadPet에서 가져오므로 여기서는 성공 여부만 확인
      final responseData = response.data;
      
      if (responseData is! Map<String, dynamic>) {
        throw ServerException('서버 응답 형식이 올바르지 않습니다.');
      }

      // PetDto로 파싱 시도 (필드가 없어도 기본값으로 처리)
      try {
        return PetDto.fromJson(responseData);
      } catch (e) {
        // 파싱 실패해도 성공한 것으로 간주 (loadPet에서 최신 데이터 가져옴)
        // 최소한의 필드만 있는 더미 객체 반환
        return PetDto(
          id: petId,
          userId: responseData['user_id']?.toString() ?? '',
          breedCode: responseData['breed_code']?.toString() ?? '',
          weightBucketCode: responseData['weight_bucket_code']?.toString() ?? '',
          ageStage: AgeStage.adult,
          isPrimary: responseData['is_primary'] == true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw NetworkException('네트워크 연결 시간이 초과되었습니다.');
      } else if (e.response != null) {
        throw ServerException(
          e.response?.data['detail'] as String? ?? '서버 오류가 발생했습니다.',
        );
      } else {
        throw NetworkException('네트워크 오류가 발생했습니다.');
      }
    } catch (e) {
      if (e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw ServerException('알 수 없는 오류가 발생했습니다.');
    }
  }
}

final petRepositoryProvider = Provider<PetRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PetRepository(apiClient);
});
