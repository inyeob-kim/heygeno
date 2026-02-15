// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommendation_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecommendationItemDto _$RecommendationItemDtoFromJson(
  Map<String, dynamic> json,
) => RecommendationItemDto(
  product: ProductDto.fromJson(json['product'] as Map<String, dynamic>),
  offerMerchant: RecommendationItemDto._merchantFromJson(
    json['offer_merchant'] as String,
  ),
  currentPrice: (json['current_price'] as num).toInt(),
  avgPrice: (json['avg_price'] as num).toInt(),
  deltaPercent: (json['delta_percent'] as num?)?.toDouble(),
  isNewLow: json['is_new_low'] as bool,
  matchScore: (json['match_score'] as num).toDouble(),
  safetyScore: (json['safety_score'] as num).toDouble(),
  fitnessScore: (json['fitness_score'] as num).toDouble(),
  matchReasons: (json['match_reasons'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  technicalExplanation: json['technical_explanation'] as String?,
  expertExplanation: json['expert_explanation'] as String?,
  explanation: json['explanation'] as String?,
  ingredientCount: (json['ingredient_count'] as num?)?.toInt(),
  mainIngredients: (json['main_ingredients'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  allergyIngredients: (json['allergy_ingredients'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  harmfulIngredients: (json['harmful_ingredients'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  qualityChecklist: (json['quality_checklist'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  dailyAmountG: (json['daily_amount_g'] as num?)?.toDouble(),
  animationExplanation: json['animation_explanation'] as String?,
  safetyBadges: (json['safety_badges'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
);

Map<String, dynamic> _$RecommendationItemDtoToJson(
  RecommendationItemDto instance,
) => <String, dynamic>{
  'product': instance.product,
  'offer_merchant': RecommendationItemDto._merchantToJson(
    instance.offerMerchant,
  ),
  'current_price': instance.currentPrice,
  'avg_price': instance.avgPrice,
  'delta_percent': instance.deltaPercent,
  'is_new_low': instance.isNewLow,
  'match_score': instance.matchScore,
  'safety_score': instance.safetyScore,
  'fitness_score': instance.fitnessScore,
  'match_reasons': instance.matchReasons,
  'technical_explanation': instance.technicalExplanation,
  'expert_explanation': instance.expertExplanation,
  'explanation': instance.explanation,
  'ingredient_count': instance.ingredientCount,
  'main_ingredients': instance.mainIngredients,
  'allergy_ingredients': instance.allergyIngredients,
  'harmful_ingredients': instance.harmfulIngredients,
  'quality_checklist': instance.qualityChecklist,
  'daily_amount_g': instance.dailyAmountG,
  'animation_explanation': instance.animationExplanation,
  'safety_badges': instance.safetyBadges,
  'confidence_score': instance.confidenceScore,
};

RecommendationResponseDto _$RecommendationResponseDtoFromJson(
  Map<String, dynamic> json,
) => RecommendationResponseDto(
  petId: json['pet_id'] as String,
  items: (json['items'] as List<dynamic>)
      .map((e) => RecommendationItemDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  isCached: json['is_cached'] as bool? ?? false,
  lastRecommendedAt: json['last_recommended_at'] == null
      ? null
      : DateTime.parse(json['last_recommended_at'] as String),
  message: json['message'] as String?,
);

Map<String, dynamic> _$RecommendationResponseDtoToJson(
  RecommendationResponseDto instance,
) => <String, dynamic>{
  'pet_id': instance.petId,
  'items': instance.items,
  'is_cached': instance.isCached,
  'last_recommended_at': instance.lastRecommendedAt?.toIso8601String(),
  'message': instance.message,
};
