import 'package:flutter/material.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';

/// 카드 컨테이너 위젯 (HeyGeno Landing Style)
/// 
/// 규칙:
/// - padding: AppSpacing.xl (24px) 또는 p-6 sm:p-8 (24px-32px)
/// - borderRadius: AppRadius.lg (16px) - rounded-2xl
/// - backgroundColor: AppColors.surface (White)
/// - border: border-2 border-gray-100 hover:border-gray-200
/// - shadow: shadow-sm hover:shadow-md
class CardContainer extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool showBorder; // 기본값: false (펫 분석 프로필 스타일)
  final bool showShadow; // 기본값: true
  final Color? borderColor;
  final double? borderWidth;
  @deprecated // v4.1: 더 이상 사용되지 않음, 호환성을 위해 유지
  final bool isHomeStyle; // Legacy 호환성

  const CardContainer({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.onTap,
    this.showBorder = false, // 펫 분석 프로필 스타일: border 없음
    this.showShadow = true,
    this.borderColor,
    this.borderWidth,
    this.isHomeStyle = false, // Legacy 호환성
  });

  @override
  State<CardContainer> createState() => _CardContainerState();
}

class _CardContainerState extends State<CardContainer> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // HeyGeno Landing: padding은 AppSpacing.xl (24px)로 통일
    final effectivePadding = widget.padding ?? const EdgeInsets.all(AppSpacing.xl);
    
    // HeyGeno Landing: 카드 배경은 surface (White)
    final effectiveBackgroundColor = widget.backgroundColor ?? AppColors.surface;
    
    // HeyGeno Landing: borderRadius는 AppRadius.lg (16px) - rounded-2xl
    final effectiveBorderRadius = BorderRadius.circular(AppRadius.lg);
    
    // 펫 분석 프로필 스타일: border 제거 (기본값)
    final effectiveBorderWidth = widget.borderWidth ?? 0.0;
    final effectiveBorderColor = widget.borderColor ?? Colors.transparent;
    
    // 펫 분석 프로필 스타일: soft shadow 하나만 (blur 10)
    final effectiveShadow = widget.showShadow 
        ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ]
        : null;
    
    final content = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: effectiveBorderRadius,
          border: widget.showBorder ? Border.all(
            color: effectiveBorderColor,
            width: effectiveBorderWidth,
        ) : null,
          boxShadow: effectiveShadow,
        ),
        child: widget.child,
      ),
    );

    if (widget.onTap != null) {
      return InkWell(
        onTap: widget.onTap,
        borderRadius: effectiveBorderRadius,
        child: content,
      );
    }

    return content;
  }
}
