/// 반려동물 프로필 초안 모델
class PetProfileDraft {
  final String? name;
  final String? species; // 'dog' | 'cat'
  final String? birthMode; // 'exactBirthdate' | 'approxAge'
  final DateTime? birthdate;
  final int? ageYears;
  final int? ageMonths;
  final String? breed;
  final String? sex; // 'male' | 'female'
  final String? neutered; // 'yes' | 'no' | 'unknown'
  final double? weightKg;
  final int? bodyConditionScore; // 1~9
  final Set<String> healthConcerns;
  final Set<String> foodAllergies;
  final String? photoUrl;

  PetProfileDraft({
    this.name,
    this.species,
    this.birthMode,
    this.birthdate,
    this.ageYears,
    this.ageMonths,
    this.breed,
    this.sex,
    this.neutered,
    this.weightKg,
    this.bodyConditionScore,
    Set<String>? healthConcerns,
    Set<String>? foodAllergies,
    this.photoUrl,
  })  : healthConcerns = healthConcerns ?? {},
        foodAllergies = foodAllergies ?? {};

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'species': species,
      'birthMode': birthMode,
      'birthdate': birthdate?.toIso8601String(),
      'ageYears': ageYears,
      'ageMonths': ageMonths,
      'breed': breed,
      'sex': sex,
      'neutered': neutered,
      'weightKg': weightKg,
      'bodyConditionScore': bodyConditionScore,
      'healthConcerns': healthConcerns.toList(),
      'foodAllergies': foodAllergies.toList(),
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
      ageYears: json['ageYears'] as int?,
      ageMonths: json['ageMonths'] as int?,
      breed: json['breed'] as String?,
      sex: json['sex'] as String?,
      neutered: json['neutered'] as String?,
      weightKg: json['weightKg'] as double?,
      bodyConditionScore: json['bodyConditionScore'] as int?,
      healthConcerns: (json['healthConcerns'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          {},
      foodAllergies: (json['foodAllergies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          {},
      photoUrl: json['photoUrl'] as String?,
    );
  }

  /// 복사 생성
  PetProfileDraft copyWith({
    String? name,
    String? species,
    String? birthMode,
    DateTime? birthdate,
    int? ageYears,
    int? ageMonths,
    String? breed,
    String? sex,
    String? neutered,
    double? weightKg,
    int? bodyConditionScore,
    Set<String>? healthConcerns,
    Set<String>? foodAllergies,
    String? photoUrl,
  }) {
    return PetProfileDraft(
      name: name ?? this.name,
      species: species ?? this.species,
      birthMode: birthMode ?? this.birthMode,
      birthdate: birthdate ?? this.birthdate,
      ageYears: ageYears ?? this.ageYears,
      ageMonths: ageMonths ?? this.ageMonths,
      breed: breed ?? this.breed,
      sex: sex ?? this.sex,
      neutered: neutered ?? this.neutered,
      weightKg: weightKg ?? this.weightKg,
      bodyConditionScore: bodyConditionScore ?? this.bodyConditionScore,
      healthConcerns: healthConcerns ?? this.healthConcerns,
      foodAllergies: foodAllergies ?? this.foodAllergies,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
