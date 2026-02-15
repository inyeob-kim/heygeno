import 'package:json_annotation/json_annotation.dart';

part 'product_dto.g.dart';

@JsonSerializable()
class ProductDto {
  final String id;
  @JsonKey(name: 'brand_name')
  final String brandName;
  @JsonKey(name: 'product_name')
  final String productName;
  @JsonKey(name: 'size_label')
  final String? sizeLabel;
  @JsonKey(name: 'is_active')
  final bool isActive;
  final String? species; // 'DOG' | 'CAT'

  ProductDto({
    required this.id,
    required this.brandName,
    required this.productName,
    this.sizeLabel,
    required this.isActive,
    this.species,
  });

  factory ProductDto.fromJson(Map<String, dynamic> json) => _$ProductDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ProductDtoToJson(this);
}

