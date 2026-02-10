import 'package:flutter/material.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/app_radius.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../app/theme/app_colors.dart';

/// 카테고리 칩 데이터
class CategoryChipData {
  final String id;
  final String label;
  final IconData? icon;

  CategoryChipData({
    required this.id,
    required this.label,
    this.icon,
  });
}

/// 가로 스크롤 카테고리 칩 리스트
class CategoryChips extends StatelessWidget {
  final List<CategoryChipData> categories;
  final String? selectedCategoryId;
  final Function(String categoryId)? onCategoryTap;

  const CategoryChips({
    super.key,
    required this.categories,
    this.selectedCategoryId,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category.id == selectedCategoryId;
          
          return FilterChip(
            selected: isSelected,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (category.icon != null) ...[
                  Icon(
                    category.icon,
                    size: 16,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs + 2),
                ],
                Text(category.label),
              ],
            ),
            onSelected: (selected) {
              onCategoryTap?.call(category.id);
            },
            selectedColor: AppColors.primary,
            checkmarkColor: Colors.white,
            labelStyle: AppTypography.caption.copyWith(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.chip),
              side: BorderSide(
                color: isSelected ? AppColors.primary : Colors.grey.shade300,
                width: isSelected ? 0 : 1,
              ),
            ),
          );
        },
      ),
    );
  }
}
