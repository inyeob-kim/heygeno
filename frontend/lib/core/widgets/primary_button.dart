import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';

/// Primary Button (DESIGN_GUIDE.md v4.1 - Data-Driven Premium Platform Edition)
/// 
/// @deprecated Use `design_system/components/button.dart` PrimaryButton instead.
/// This widget is kept for backward compatibility and will be removed in a future version.
/// 
/// 주요 CTA 버튼 ("가격 비교하기", "최저가 확인", "알림 설정", "등록하기")에 사용
/// Blue (#2563EB) Primary 색상 사용
@Deprecated('Use design_system/components/button.dart PrimaryButton instead')
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary, // Blue (#1D4ED8)
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md), // 12px
        ),
        elevation: 0, // Shadow 없음
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              text,
              style: AppTypography.button,
            ),
    );

    if (width != null) {
      return SizedBox(
        width: width,
        child: button,
      );
    }

    return SizedBox(
      width: double.infinity,
      child: button,
    );
  }
}
