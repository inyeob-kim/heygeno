import 'package:flutter/material.dart';
import '../../app/theme/app_spacing.dart';

/// 카드 컨테이너 위젯 (DESIGN_GUIDE.md 스타일)
class CardContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool showBorder;
  final bool isHomeStyle; // Home 전용 스타일 프리셋
  final Color? borderColor; // 테두리 색상 커스터마이징
  final double? borderWidth; // 테두리 두께 커스터마이징

  const CardContainer({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.onTap,
    this.showBorder = true, // DESIGN_GUIDE: border 기본 사용
    this.isHomeStyle = false, // Home 전용 스타일 (기본값: false)
    this.borderColor,
    this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    // Home 전용 스타일 프리셋 적용
    // 기본 padding은 AppSpacing.lg로 통일
    final effectivePadding = isHomeStyle 
        ? (padding ?? const EdgeInsets.all(AppSpacing.lg))
        : (padding ?? const EdgeInsets.all(AppSpacing.lg));
    
    final effectiveBackgroundColor = isHomeStyle
        ? (backgroundColor ?? Colors.white)
        : (backgroundColor ?? const Color(0xFFFFFFFF));
    
    final effectiveBorderRadius = BorderRadius.circular(12);
    
    final content = Container(
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: effectiveBorderRadius,
        border: showBorder ? Border.all(
          color: borderColor ?? const Color(0xFFF1F3F5),
          width: borderWidth ?? 1,
        ) : null,
        // shadow 제거
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: effectiveBorderRadius,
        child: content,
      );
    }

    return content;
  }
}
