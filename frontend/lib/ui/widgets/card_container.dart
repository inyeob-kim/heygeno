import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_shadows.dart';
import '../../app/theme/app_spacing.dart';

/// 카드 컨테이너 위젯 (DESIGN_GUIDE.md 스타일)
class CardContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool showBorder;

  const CardContainer({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.onTap,
    this.showBorder = true, // DESIGN_GUIDE: border 기본 사용
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: showBorder ? Border.all(
          color: AppColors.divider,
          width: 1,
        ) : null,
        boxShadow: AppShadows.card,
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: content,
      );
    }

    return content;
  }
}
