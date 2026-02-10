/// Primary Pet 요약 정보 (홈 화면용)
class PetSummaryDto {
  final String petId;
  final String name;
  final String species; // 'DOG' | 'CAT'
  final String? ageStage; // 'PUPPY' | 'ADULT' | 'SENIOR'
  final int? ageMonths; // 개월 단위
  final double weightKg;
  final List<String> healthConcerns; // 빈 배열 = "특이사항 없음"
  final String? photoUrl;
  final String? breedCode; // 품종 코드
  final bool? isNeutered; // 중성화 여부
  final String? sex; // 'MALE' | 'FEMALE' | 'UNKNOWN'
  final List<String> foodAllergies; // 음식 알레르기 코드 리스트
  final String? otherAllergies; // 기타 알레르기 텍스트
  final bool? isPrimary; // 주 반려동물 여부

  PetSummaryDto({
    required this.petId,
    required this.name,
    required this.species,
    this.ageStage,
    this.ageMonths,
    required this.weightKg,
    List<String>? healthConcerns,
    this.photoUrl,
    this.breedCode,
    this.isNeutered,
    this.sex,
    List<String>? foodAllergies,
    this.otherAllergies,
    this.isPrimary,
  }) : healthConcerns = healthConcerns ?? [],
       foodAllergies = foodAllergies ?? [];

  factory PetSummaryDto.fromJson(Map<String, dynamic> json) {
    print('[PetSummaryDto] fromJson 호출, json: $json');
    // UUID는 문자열로 직렬화됨
    final id = json['id'];
    final petId = id is String ? id : id.toString();
    
    return PetSummaryDto(
      petId: petId,
      name: json['name'] as String,
      species: json['species'] as String,
      ageStage: json['age_stage'] as String?,
      ageMonths: json['approx_age_months'] as int?,
      weightKg: (json['weight_kg'] as num).toDouble(),
      healthConcerns: (json['health_concerns'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      photoUrl: json['photo_url'] as String?,
      breedCode: json['breed_code'] as String?,
      isNeutered: json['is_neutered'] as bool?,
      sex: json['sex'] as String?,
      foodAllergies: (json['food_allergies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      otherAllergies: json['other_allergies'] as String?,
      isPrimary: (json['is_primary'] as bool?) ?? false,
    );
  }

  /// 나이 요약 텍스트
  String get ageSummary {
    if (ageStage != null) {
      switch (ageStage) {
        case 'PUPPY':
          return '강아지';
        case 'ADULT':
          return '성견';
        case 'SENIOR':
          return '노견';
        default:
          break;
      }
    }
    if (ageMonths != null) {
      if (ageMonths! < 12) {
        return '${ageMonths}개월';
      } else {
        final years = ageMonths! ~/ 12;
        final months = ageMonths! % 12;
        if (months == 0) {
          return '${years}세';
        } else {
          return '${years}세 ${months}개월';
        }
      }
    }
    return '나이 정보 없음';
  }

  /// 건강 포인트 요약
  String get healthSummary {
    if (healthConcerns.isEmpty) {
      return '특이사항 없음';
    }
    return healthConcerns.join(', ');
  }
}
