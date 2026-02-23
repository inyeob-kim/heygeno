import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/app_radius.dart';

/// 쿠팡 스타일 EmptyState 위젯
/// 
/// @deprecated Use `design_system/components/empty_state.dart` EmptyState instead.
/// This widget is kept for backward compatibility and will be removed in a future version.
@Deprecated('Use design_system/components/empty_state.dart EmptyState instead')
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? description;
  final IconData? icon;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyStateWidget({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.buttonText,
    this.onButtonPressed,
  });

  // Legacy 호환성
  const EmptyStateWidget.legacy({
    super.key,
    required String message,
    IconData? icon,
  }) : title = message,
       description = null,
       icon = icon,
       buttonText = null,
       onButtonPressed = null;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 아이콘 (예: paw/box)
            if (icon != null)
              Icon(
                icon,
                size: 64,
                color: AppColors.iconMuted,
              )
            else
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: AppColors.iconMuted,
              ),
            const SizedBox(height: 24),
            // 제목 (굵게)
            Text(
              title,
              style: AppTypography.titleMedium,
              textAlign: TextAlign.center,
            ),
            // 설명 (회색)
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: AppTypography.body2,
                textAlign: TextAlign.center,
              ),
            ],
            // 버튼 (파란 pill)
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 32),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: onButtonPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.buttonPill),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    elevation: 0,
                  ),
                  child: Text(
                    buttonText!,
                    style: AppTypography.button,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

