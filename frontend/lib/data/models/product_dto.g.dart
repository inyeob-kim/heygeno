// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductDto _$ProductDtoFromJson(Map<String, dynamic> json) => ProductDto(
  id: json['id'] as String,
  brandName: json['brand_name'] as String,
  productName: json['product_name'] as String,
  sizeLabel: json['size_label'] as String?,
  isActive: json['is_active'] as bool,
  species: json['species'] as String?,
);

Map<String, dynamic> _$ProductDtoToJson(ProductDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'brand_name': instance.brandName,
      'product_name': instance.productName,
      'size_label': instance.sizeLabel,
      'is_active': instance.isActive,
      'species': instance.species,
    };
