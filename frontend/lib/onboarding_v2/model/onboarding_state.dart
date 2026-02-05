/// Onboarding data model matching React OnboardingData
class OnboardingStateV2 {
  final String nickname;
  final String petName;
  final String species; // 'dog' | 'cat' | ''
  final String ageType; // 'birthdate' | 'approximate' | ''
  final String birthdate;
  final String approximateAge;
  final String breed;
  final String sex; // 'male' | 'female' | ''
  final bool? neutered; // true | false | null
  final String weight;
  final int bcs;
  final List<String> healthConcerns;
  final List<String> foodAllergies;
  final String otherAllergy;
  final String photo; // base64 or file path

  const OnboardingStateV2({
    this.nickname = '',
    this.petName = '',
    this.species = '',
    this.ageType = '',
    this.birthdate = '',
    this.approximateAge = '',
    this.breed = '',
    this.sex = '',
    this.neutered,
    this.weight = '',
    this.bcs = 5,
    this.healthConcerns = const [],
    this.foodAllergies = const [],
    this.otherAllergy = '',
    this.photo = '',
  });

  OnboardingStateV2 copyWith({
    String? nickname,
    String? petName,
    String? species,
    String? ageType,
    String? birthdate,
    String? approximateAge,
    String? breed,
    String? sex,
    bool? neutered,
    String? weight,
    int? bcs,
    List<String>? healthConcerns,
    List<String>? foodAllergies,
    String? otherAllergy,
    String? photo,
  }) {
    return OnboardingStateV2(
      nickname: nickname ?? this.nickname,
      petName: petName ?? this.petName,
      species: species ?? this.species,
      ageType: ageType ?? this.ageType,
      birthdate: birthdate ?? this.birthdate,
      approximateAge: approximateAge ?? this.approximateAge,
      breed: breed ?? this.breed,
      sex: sex ?? this.sex,
      neutered: neutered ?? this.neutered,
      weight: weight ?? this.weight,
      bcs: bcs ?? this.bcs,
      healthConcerns: healthConcerns ?? this.healthConcerns,
      foodAllergies: foodAllergies ?? this.foodAllergies,
      otherAllergy: otherAllergy ?? this.otherAllergy,
      photo: photo ?? this.photo,
    );
  }

  /// 서버 API 요청 형식으로 변환
  Map<String, dynamic> toApiRequest(String deviceUid) {
    // species 변환: 'dog' -> 'DOG', 'cat' -> 'CAT'
    final speciesUpper = species.toUpperCase();
    
    // age_mode 변환: 'birthdate' -> 'BIRTHDATE', 'approximate' -> 'APPROX'
    final ageMode = ageType == 'birthdate' ? 'BIRTHDATE' : 'APPROX';
    
    // birthdate 파싱 (YYYY-MM-DD 형식)
    DateTime? parsedBirthdate;
    if (birthdate.isNotEmpty && ageMode == 'BIRTHDATE') {
      try {
        parsedBirthdate = DateTime.parse(birthdate);
      } catch (e) {
        // 파싱 실패 시 null
      }
    }
    
    // approximateAge를 개월 수로 변환 (예: "2살 3개월" -> 27개월)
    int? approxAgeMonths;
    if (approximateAge.isNotEmpty && ageMode == 'APPROX') {
      approxAgeMonths = _parseApproximateAge(approximateAge);
    }
    
    // weight를 double로 변환
    final weightKg = double.tryParse(weight) ?? 0.0;
    
    // sex 변환: 'male' -> 'MALE', 'female' -> 'FEMALE'
    final sexUpper = sex.toUpperCase();
    
    // 한글 건강 고민을 코드로 변환
    final healthConcernCodeMap = {
      '알레르기': 'ALLERGY',
      '장/소화': 'DIGESTIVE',
      '치아/구강': 'DENTAL',
      '비만': 'OBESITY',
      '호흡기': 'RESPIRATORY',
      '피부/털': 'SKIN',
      '관절': 'JOINT',
      '눈/눈물': 'EYE',
      '신장/요로': 'KIDNEY',
      '심장': 'HEART',
      '노령': 'SENIOR',
    };
    
    // "없어요"를 필터링하고 한글을 코드로 변환
    final filteredHealthConcerns = healthConcerns
        .where((c) => c != '없어요')
        .map((c) => healthConcernCodeMap[c] ?? c) // 코드로 변환, 없으면 그대로
        .toList();
    
    // 한글 알레르기를 코드로 변환
    final allergenCodeMap = {
      '소고기': 'BEEF',
      '닭고기': 'CHICKEN',
      '돼지고기': 'PORK',
      '오리고기': 'DUCK',
      '양고기': 'LAMB',
      '생선': 'FISH',
      '계란': 'EGG',
      '유제품': 'DAIRY',
      '밀/글루텐': 'WHEAT',
      '옥수수': 'CORN',
      '콩': 'SOY',
    };
    
    final filteredFoodAllergies = foodAllergies
        .where((a) => a != '없어요')
        .map((a) => allergenCodeMap[a] ?? a) // 코드로 변환, 없으면 그대로
        .toList();
    
    return {
      'device_uid': deviceUid,
      'nickname': nickname,
      'pet_name': petName,
      'species': speciesUpper,
      'age_mode': ageMode,
      'birthdate': parsedBirthdate != null 
          ? parsedBirthdate.toIso8601String().split('T')[0] 
          : null,
      'approx_age_months': approxAgeMonths,
      'breed_code': breed.isNotEmpty ? breed : null,
      'sex': sexUpper,
      'is_neutered': neutered,
      'weight_kg': weightKg,
      'body_condition_score': bcs,
      'health_concerns': filteredHealthConcerns,
      'food_allergies': filteredFoodAllergies,
      'other_allergy_text': otherAllergy.isNotEmpty ? otherAllergy : null,
      'photo_url': photo.isNotEmpty ? photo : null,
    };
  }

  /// 대략 나이 문자열을 개월 수로 변환 (예: "2살 3개월" -> 27)
  int? _parseApproximateAge(String ageStr) {
    try {
      int years = 0;
      int months = 0;
      
      // "X살 Y개월" 형식 파싱
      final yearMatch = RegExp(r'(\d+)살').firstMatch(ageStr);
      if (yearMatch != null) {
        years = int.parse(yearMatch.group(1)!);
      }
      
      final monthMatch = RegExp(r'(\d+)개월').firstMatch(ageStr);
      if (monthMatch != null) {
        months = int.parse(monthMatch.group(1)!);
      }
      
      return years * 12 + months;
    } catch (e) {
      return null;
    }
  }
}
