import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_shadows.dart';

/// Primary Button (DESIGN_GUIDE.md 스타일)
class AppPrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final double? width;
  final double height;

  const AppPrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.width,
    this.height = 48, // DESIGN_GUIDE: 48px
  });

  @override
  State<AppPrimaryButton> createState() => _AppPrimaryButtonState();
}

class _AppPrimaryButtonState extends State<AppPrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onPressed != null ? (_) {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      } : null,
      onTapCancel: widget.onPressed != null ? () => setState(() => _isPressed = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: widget.width ?? double.infinity,
        height: widget.height,
        transform: Matrix4.identity()..translate(0.0, _isPressed ? -1.0 : 0.0),
        decoration: BoxDecoration(
          color: widget.onPressed != null
              ? AppColors.primary
              : AppColors.primary.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppRadius.button),
          boxShadow: widget.onPressed != null ? AppShadows.button : null,
        ),
        child: Center(
          child: Text(
            widget.text,
            style: AppTypography.button,
          ),
        ),
      ),
    );
  }
}

/// Secondary Button (DESIGN_GUIDE.md 스타일)
class AppSecondaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final double? width;
  final double height;

  const AppSecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.width,
    this.height = 48,
  });

  @override
  State<AppSecondaryButton> createState() => _AppSecondaryButtonState();
}

class _AppSecondaryButtonState extends State<AppSecondaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onPressed != null ? (_) {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      } : null,
      onTapCancel: widget.onPressed != null ? () => setState(() => _isPressed = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: widget.width ?? double.infinity,
        height: widget.height,
        transform: Matrix4.identity()..translate(0.0, _isPressed ? -1.0 : 0.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(
            color: AppColors.divider,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            widget.text,
            style: AppTypography.button.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Button Row (DESIGN_GUIDE.md 스타일)
class AppButtonRow extends StatelessWidget {
  final List<Widget> children;
  final double gap;

  const AppButtonRow({
    super.key,
    required this.children,
    this.gap = AppSpacing.buttonRowGap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: children,
    );
  }
}
