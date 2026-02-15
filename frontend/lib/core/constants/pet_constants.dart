/// 반려동물 관련 상수 (도메인 데이터)

class PetConstants {
  /// 견종 목록
  static const List<String> breeds = [
    '비글',
    '골든 리트리버',
    '래브라도 리트리버',
    '퍼그',
    '치와와',
    '포메라니안',
  ];

  /// 체중 구간 목록
  static const List<String> weightBuckets = [
    '5kg 이하',
    '5-10kg',
    '10-15kg',
    '15-20kg',
    '20kg 이상',
  ];

  /// 나이 단계 목록
  static const List<String> ageStages = [
    'PUPPY',
    'ADULT',
    'SENIOR',
  ];

  /// 나이 단계 텍스트 변환
  static String? getAgeStageText(String? ageStage) {
    if (ageStage == null) return null;
    switch (ageStage.toUpperCase()) {
      case 'PUPPY':
        return '강아지';
      case 'ADULT':
        return '성견';
      case 'SENIOR':
        return '노견';
      default:
        return ageStage;
    }
  }

  /// 건강 관심사 이름 매핑 (DB와 동기화)
  static const Map<String, String> healthConcernNames = {
    'ALLERGY': '알레르기',
    'DIGESTIVE': '장/소화',
    'DENTAL': '치아/구강',
    'OBESITY': '비만',
    'RESPIRATORY': '호흡기',
    'SKIN': '피부/털',
    'JOINT': '관절',
    'EYE': '눈/눈물',
    'KIDNEY': '신장/요로',
    'HEART': '심장',
    'SENIOR': '노령',
  };

  /// 알레르겐 이름 매핑 (DB와 동기화)
  static const Map<String, String> allergenNames = {
    'BEEF': '소고기',
    'CHICKEN': '닭고기',
    'PORK': '돼지고기',
    'DUCK': '오리고기',
    'LAMB': '양고기',
    'FISH': '생선',
    'EGG': '계란',
    'DAIRY': '유제품',
    'WHEAT': '밀/글루텐',
    'CORN': '옥수수',
    'SOY': '콩',
  };
}

