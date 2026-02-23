import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Primary 버튼 위젯
/// 
/// @deprecated Use `design_system/components/button.dart` PrimaryButton instead.
/// This widget is kept for backward compatibility and will be removed in a future version.
@Deprecated('Use design_system/components/button.dart PrimaryButton instead')
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSmall;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: Size(
          double.infinity,
          isSmall ? 40 : 48,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
        ),
      ),
      child: isLoading
          ? Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: Lottie.asset(
                  'assets/animations/loading_dots.json',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  repeat: true,
                  animate: true,
                ),
              ),
            )
          : Text(
              text,
              style: AppTypography.body.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

