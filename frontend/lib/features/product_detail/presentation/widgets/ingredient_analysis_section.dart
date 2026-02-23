import 'package:flutter/material.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_radius.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../data/models/product_display_models.dart';
import 'package:pet_food_app/l10n/app_localizations.dart';

/// 성분 분석 섹션 위젯
class IngredientAnalysisSection extends StatefulWidget {
  final IngredientAnalysisData? data;

  const IngredientAnalysisSection({
    super.key,
    this.data,
  });

  @override
  State<IngredientAnalysisSection> createState() => _IngredientAnalysisSectionState();
}

class _IngredientAnalysisSectionState extends State<IngredientAnalysisSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.data == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더 (클릭 가능)
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.productDetailWidget_ingredientAnalysis,
                      style: AppTypography.h3.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (!_isExpanded) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        AppLocalizations.of(context)!.productDetailWidget_checkIngredientsNutrition,
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              AnimatedRotation(
                turns: _isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
        // 접기/펼치기 콘텐츠
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppLocalizations.of(context)!.productDetailWidget_checkIngredientsNutrition,
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 주요 원료
              if (widget.data!.mainIngredients.isNotEmpty) ...[
                _buildMainIngredients(widget.data!.mainIngredients),
                const SizedBox(height: AppSpacing.xl),
              ],

              // 영양소 분석
              if (widget.data!.nutritionFacts.isNotEmpty) ...[
                _buildNutritionFacts(widget.data!.nutritionFacts),
                if (widget.data!.allergens != null && widget.data!.allergens!.isNotEmpty)
                  const SizedBox(height: AppSpacing.xl),
              ],
              
              // 알레르기 유발 성분
              if (widget.data!.allergens != null && widget.data!.allergens!.isNotEmpty)
                _buildAllergens(widget.data!.allergens!),
            ],
          ),
          crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
          sizeCurve: Curves.easeInOut,
        ),
      ],
    );
  }

  Widget _buildMainIngredients(List<String> ingredients) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.eco,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              AppLocalizations.of(context)!.productDetailWidget_mainIngredients,
              style: AppTypography.body1.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Pill 형태로 표시
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: ingredients.map((ingredient) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: Text(
                ingredient,
                style: AppTypography.caption.copyWith(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNutritionFacts(Map<String, double> nutritionFacts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 18,
              color: AppColors.status,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              AppLocalizations.of(context)!.productDetailWidget_nutritionAnalysis,
              style: AppTypography.body1.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...nutritionFacts.entries.map((entry) {
          final label = entry.key;
          final value = entry.value;
          final isLast = entry.key == nutritionFacts.keys.last;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: AppTypography.body2.copyWith(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${value.toStringAsFixed(1)}%',
                      style: AppTypography.body1.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: value / 100,
                    minHeight: 6,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.status,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildAllergens(List<String> allergens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 18,
              color: AppColors.drop,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              AppLocalizations.of(context)!.productDetailWidget_allergenIngredients,
              style: AppTypography.body1.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppColors.drop,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: allergens.map((allergen) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.dropLight,
                borderRadius: BorderRadius.circular(AppRadius.chip),
                border: Border.all(
                  color: AppColors.drop.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                allergen,
                style: AppTypography.caption.copyWith(
                  fontSize: 13,
                  color: AppColors.drop,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

}
