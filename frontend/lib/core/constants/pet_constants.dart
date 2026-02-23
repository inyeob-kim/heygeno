/// 반려동물 관련 상수 (도메인 데이터)
import 'package:flutter/material.dart';
import 'package:pet_food_app/l10n/app_localizations.dart';

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
  static String? getAgeStageText(BuildContext context, String? ageStage) {
    if (ageStage == null) return null;
    final l10n = AppLocalizations.of(context)!;
    switch (ageStage.toUpperCase()) {
      case 'PUPPY':
        return l10n.pet_ageStage_puppy;
      case 'ADULT':
        return l10n.ageStage_adult;
      case 'SENIOR':
        return l10n.pet_ageStage_senior;
      default:
        return ageStage;
    }
  }

  /// 건강 관심사 이름 매핑 (DB와 동기화)
  static String getHealthConcernName(BuildContext context, String concern) {
    final l10n = AppLocalizations.of(context)!;
    switch (concern.toUpperCase()) {
      case 'ALLERGY':
        return l10n.healthConcern_allergy;
      case 'DIGESTIVE':
        return l10n.healthConcern_digestive;
      case 'DENTAL':
        return l10n.healthConcern_dental;
      case 'OBESITY':
        return l10n.healthConcern_obesity;
      case 'RESPIRATORY':
        return l10n.healthConcern_respiratory;
      case 'SKIN':
        return l10n.healthConcern_skin;
      case 'JOINT':
        return l10n.healthConcern_joint;
      case 'EYE':
        return l10n.healthConcern_eye;
      case 'KIDNEY':
        return l10n.healthConcern_kidney;
      case 'HEART':
        return l10n.healthConcern_heart;
      case 'SENIOR':
        return l10n.healthConcern_senior;
      default:
        return concern;
    }
  }

  /// 알레르겐 이름 매핑 (DB와 동기화)
  static String getAllergenName(BuildContext context, String allergen) {
    final l10n = AppLocalizations.of(context)!;
    switch (allergen.toUpperCase()) {
      case 'BEEF':
        return l10n.allergen_beef;
      case 'CHICKEN':
        return l10n.allergen_chicken;
      case 'PORK':
        return l10n.allergen_pork;
      case 'DUCK':
        return l10n.allergen_duck;
      case 'LAMB':
        return l10n.allergen_lamb;
      case 'FISH':
        return l10n.allergen_fish;
      case 'EGG':
        return l10n.allergen_egg;
      case 'DAIRY':
        return l10n.allergen_dairy;
      case 'WHEAT':
        return l10n.allergen_wheat;
      case 'CORN':
        return l10n.allergen_corn;
      case 'SOY':
        return l10n.allergen_soy;
      default:
        return allergen;
    }
  }
}

