import 'package:flutter/material.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import 'package:pet_food_app/l10n/app_localizations.dart';

/// Search Bar 위젯 (DESIGN_GUIDE.md v2.2)
class FigmaSearchBar extends StatelessWidget {
  final String? placeholder;
  final ValueChanged<String>? onSearch;
  final TextEditingController? controller;

  const FigmaSearchBar({
    super.key,
    this.placeholder,
    this.onSearch,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight, // 연한 회색
        borderRadius: BorderRadius.circular(AppRadius.lg), // 16px
        border: Border.all(
          color: AppColors.line, // #E5E7EB
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onSearch,
        style: AppTypography.body.copyWith(
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: placeholder ?? AppLocalizations.of(context)!.search_placeholderProduct,
          hintStyle: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: AppColors.textSecondary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg), // 16px
            borderSide: BorderSide(
              color: AppColors.primary.withOpacity(0.3), // Emerald Green
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
