import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/storage/storage_keys.dart';
import '../../../data/models/pet_summary_dto.dart';
import 'package:dio/dio.dart';

/// Pet 관련 비즈니스 로직 서비스
class PetService {
  final ApiClient _apiClient;

  PetService(this._apiClient);

  /// Primary Pet 요약 정보 조회 (서버 우선, 실패 시 로컬 캐시)
  Future<PetSummaryDto?> getPrimaryPetSummary() async {
    try {
      // 1. 서버에서 primary pet 조회 시도
      // Device UID는 DeviceUidInterceptor에서 자동으로 헤더에 추가됨
      final response = await _apiClient.get(
        Endpoints.primaryPet,
      );
      
      print('[PetService] 서버 응답: ${response.data}');

      if (response.data != null) {
        final pet = PetSummaryDto.fromJson(
          response.data as Map<String, dynamic>,
        );
        
        // 성공 시 로컬 캐시에 저장
        await SecureStorage.write(StorageKeys.primaryPetId, pet.petId);
        await SecureStorage.write(
          StorageKeys.primaryPetSummary,
          _encodePetSummary(pet),
        );
        
        return pet;
      }
    } on DioException catch (e) {
      // 404 = pet 없음 (정상 케이스)
      if (e.response?.statusCode == 404) {
        // 로컬 캐시도 삭제
        await SecureStorage.delete(StorageKeys.primaryPetId);
        await SecureStorage.delete(StorageKeys.primaryPetSummary);
        return null;
      }
      
      // 네트워크 오류 등: 로컬 캐시 fallback
      print('[PetService] 서버 조회 실패, 로컬 캐시 확인: ${e.message}');
    } catch (e) {
      print('[PetService] 예상치 못한 오류: $e');
    }

    // 2. 로컬 캐시에서 조회 (fallback)
    return await _getCachedPetSummary();
  }

  /// 모든 펫 목록 조회
  Future<List<PetSummaryDto>> getAllPetSummaries() async {
    try {
      print('[PetService] 모든 펫 목록 조회 시작');
      final response = await _apiClient.get(Endpoints.pets);
      
      print('[PetService] API 응답: ${response.data}');
      
      if (response.data != null && response.data is List) {
        final List<dynamic> petsJson = response.data as List<dynamic>;
        print('[PetService] 펫 개수: ${petsJson.length}');
        
        final pets = petsJson
            .map((json) {
              print('[PetService] 펫 JSON 파싱: $json');
              return PetSummaryDto.fromJson(json as Map<String, dynamic>);
            })
            .toList();
        
        print('[PetService] 파싱된 펫 목록: ${pets.map((p) => p.name).toList()}');
        return pets;
      }
      
      print('[PetService] 응답 데이터가 리스트가 아님');
      return [];
    } on DioException catch (e) {
      print('[PetService] DioException 발생: ${e.message}');
      print('[PetService] 응답 상태 코드: ${e.response?.statusCode}');
      print('[PetService] 응답 데이터: ${e.response?.data}');
      
      if (e.response?.statusCode == 404) {
        print('[PetService] 404 - 펫 없음');
        return [];
      }
      print('[PetService] 모든 펫 조회 실패: ${e.message}');
      return [];
    } catch (e) {
      print('[PetService] 예상치 못한 오류: $e');
      return [];
    }
  }

  /// 특정 펫을 Primary Pet으로 설정
  Future<PetSummaryDto> setPrimaryPet(String petId) async {
    try {
      print('[PetService] Primary pet 설정 시작: petId=$petId');
      final response = await _apiClient.patch(
        '${Endpoints.pets}/$petId/set-primary',
      );
      
      print('[PetService] Primary pet 설정 응답: ${response.data}');
      
      if (response.data != null) {
        final pet = PetSummaryDto.fromJson(
          response.data as Map<String, dynamic>,
        );
        
        // 성공 시 로컬 캐시에 저장
        await SecureStorage.write(StorageKeys.primaryPetId, pet.petId);
        await SecureStorage.write(
          StorageKeys.primaryPetSummary,
          _encodePetSummary(pet),
        );
        
        return pet;
      }
      
      throw Exception('Invalid response data');
    } on DioException catch (e) {
      print('[PetService] Primary pet 설정 실패: ${e.message}');
      print('[PetService] 응답 상태 코드: ${e.response?.statusCode}');
      print('[PetService] 응답 데이터: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('[PetService] 예상치 못한 오류: $e');
      rethrow;
    }
  }

  /// 로컬 캐시에서 PetSummary 조회
  Future<PetSummaryDto?> _getCachedPetSummary() async {
    try {
      final cached = await SecureStorage.read(StorageKeys.primaryPetSummary);
      if (cached != null) {
        return _decodePetSummary(cached);
      }
    } catch (e) {
      print('[PetService] 캐시 읽기 실패: $e');
    }
    return null;
  }

  /// PetSummary를 JSON 문자열로 인코딩 (간단한 구현)
  String _encodePetSummary(PetSummaryDto pet) {
    return '${pet.petId}|${pet.name}|${pet.species}|${pet.ageStage ?? ""}|${pet.ageMonths ?? ""}|${pet.weightKg}|${pet.healthConcerns.join(",")}|${pet.photoUrl ?? ""}';
  }

  /// JSON 문자열에서 PetSummary 디코딩
  PetSummaryDto? _decodePetSummary(String encoded) {
    try {
      final parts = encoded.split('|');
      if (parts.length < 7) return null;
      
      return PetSummaryDto(
        petId: parts[0],
        name: parts[1],
        species: parts[2],
        ageStage: parts[3].isEmpty ? null : parts[3],
        ageMonths: parts[4].isEmpty ? null : int.tryParse(parts[4]),
        weightKg: double.tryParse(parts[5]) ?? 0.0,
        healthConcerns: parts[6].isEmpty ? [] : parts[6].split(','),
        photoUrl: parts.length > 7 && parts[7].isNotEmpty ? parts[7] : null,
      );
    } catch (e) {
      print('[PetService] 캐시 디코딩 실패: $e');
      return null;
    }
  }
}

/// PetService Provider
final petServiceProvider = Provider<PetService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PetService(apiClient);
});
