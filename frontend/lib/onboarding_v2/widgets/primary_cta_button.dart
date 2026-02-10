import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_radius.dart';

/// CTA Button component - DESIGN_GUIDE v1.0 준수
class PrimaryCTAButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool disabled;
  final bool isSecondary;

  const PrimaryCTAButton({
    super.key,
    required this.text,
    this.onPressed,
    this.disabled = false,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isSecondary) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton(
          onPressed: disabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            side: BorderSide(
              color: disabled
                  ? AppColors.divider
                  : AppColors.primaryBlue, // 결정/이동용
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          ),
          child: Text(
            text,
            style: AppTypography.button.copyWith(
              color: disabled
                  ? AppColors.textSecondary
                  : AppColors.primaryBlue,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: CupertinoButton(
        onPressed: disabled ? null : onPressed,
        color: disabled ? AppColors.divider : AppColors.primaryBlue, // 결정/이동용
        borderRadius: BorderRadius.circular(AppRadius.md),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Text(
          text,
          style: AppTypography.button.copyWith(
            color: disabled ? AppColors.textSecondary : Colors.white,
          ),
        ),
      ),
    );
  }
}
