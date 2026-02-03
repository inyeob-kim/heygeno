/// 반려동물 프로필 초안 모델
class PetProfileDraft {
  final String? name;
  final String? species; // 'DOG' | 'CAT' (서버 형식)
  final String? birthMode; // 'BIRTHDATE' | 'APPROX' (서버 형식)
  final DateTime? birthdate;
  final int? approxAgeMonths; // 개월 단위로 통일
  final String? breedCode; // 품종 코드
  final String? sex; // 'MALE' | 'FEMALE' (서버 형식)
  final bool? isNeutered; // true | false | null (null = 모름)
  final double? weightKg;
  final int? bodyConditionScore; // 1~9
  final List<String> healthConcerns; // 코드 배열 (빈 배열 = "없어요")
  final List<String> foodAllergies; // 코드 배열 (빈 배열 = "없어요")
  final String? otherAllergyText; // 기타 알레르기 텍스트
  final String? photoUrl;

  PetProfileDraft({
    this.name,
    this.species,
    this.birthMode,
    this.birthdate,
    this.approxAgeMonths,
    this.breedCode,
    this.sex,
    this.isNeutered,
    this.weightKg,
    this.bodyConditionScore,
    List<String>? healthConcerns,
    List<String>? foodAllergies,
    this.otherAllergyText,
    this.photoUrl,
  })  : healthConcerns = healthConcerns ?? [],
        foodAllergies = foodAllergies ?? [];

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'species': species,
      'birthMode': birthMode,
      'birthdate': birthdate?.toIso8601String(),
      'approxAgeMonths': approxAgeMonths,
      'breedCode': breedCode,
      'sex': sex,
      'isNeutered': isNeutered,
      'weightKg': weightKg,
      'bodyConditionScore': bodyConditionScore,
      'healthConcerns': healthConcerns,
      'foodAllergies': foodAllergies,
      'otherAllergyText': otherAllergyText,
      'photoUrl': photoUrl,
    };
  }

  /// JSON에서 생성
  factory PetProfileDraft.fromJson(Map<String, dynamic> json) {
    return PetProfileDraft(
      name: json['name'] as String?,
      species: json['species'] as String?,
      birthMode: json['birthMode'] as String?,
      birthdate: json['birthdate'] != null
          ? DateTime.parse(json['birthdate'] as String)
          : null,
      approxAgeMonths: json['approxAgeMonths'] as int?,
      breedCode: json['breedCode'] as String?,
      sex: json['sex'] as String?,
      isNeutered: json['isNeutered'] as bool?,
      weightKg: json['weightKg'] as double?,
      bodyConditionScore: json['bodyConditionScore'] as int?,
      healthConcerns: (json['healthConcerns'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      foodAllergies: (json['foodAllergies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      otherAllergyText: json['otherAllergyText'] as String?,
      photoUrl: json['photoUrl'] as String?,
    );
  }

  /// 복사 생성
  PetProfileDraft copyWith({
    String? name,
    String? species,
    String? birthMode,
    DateTime? birthdate,
    int? approxAgeMonths,
    String? breedCode,
    String? sex,
    bool? isNeutered,
    double? weightKg,
    int? bodyConditionScore,
    List<String>? healthConcerns,
    List<String>? foodAllergies,
    String? otherAllergyText,
    String? photoUrl,
  }) {
    return PetProfileDraft(
      name: name ?? this.name,
      species: species ?? this.species,
      birthMode: birthMode ?? this.birthMode,
      birthdate: birthdate ?? this.birthdate,
      approxAgeMonths: approxAgeMonths ?? this.approxAgeMonths,
      breedCode: breedCode ?? this.breedCode,
      sex: sex ?? this.sex,
      isNeutered: isNeutered ?? this.isNeutered,
      weightKg: weightKg ?? this.weightKg,
      bodyConditionScore: bodyConditionScore ?? this.bodyConditionScore,
      healthConcerns: healthConcerns ?? this.healthConcerns,
      foodAllergies: foodAllergies ?? this.foodAllergies,
      otherAllergyText: otherAllergyText ?? this.otherAllergyText,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
  
  /// 서버 API 요청 형식으로 변환
  Map<String, dynamic> toApiRequest(String deviceUid, String nickname) {
    return {
      'device_uid': deviceUid,
      'nickname': nickname,
      'pet_name': name!,
      'species': species!,
      'age_mode': birthMode!,
      'birthdate': birthdate?.toIso8601String().split('T')[0], // YYYY-MM-DD 형식
      'approx_age_months': approxAgeMonths,
      'breed_code': breedCode,
      'sex': sex!,
      'is_neutered': isNeutered,
      'weight_kg': weightKg!,
      'body_condition_score': bodyConditionScore!,
      'health_concerns': healthConcerns,
      'food_allergies': foodAllergies,
      'other_allergy_text': otherAllergyText,
      'photo_url': photoUrl,
    };
  }
}
