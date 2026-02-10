import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_radius.dart';

/// Text input component - DESIGN_GUIDE v1.0 준수
class TossTextInput extends StatelessWidget {
  final String? value;
  final ValueChanged<String>? onChanged;
  final String? placeholder;
  final int? maxLength;
  final TextInputType? keyboardType;
  final String? counterText;

  const TossTextInput({
    super.key,
    this.value,
    this.onChanged,
    this.placeholder,
    this.maxLength,
    this.keyboardType,
    this.counterText,
  });

  @override
  Widget build(BuildContext context) {
    return _TossTextInputStateful(
      value: value,
      onChanged: onChanged,
      placeholder: placeholder,
      maxLength: maxLength,
      keyboardType: keyboardType,
      counterText: counterText,
    );
  }
}

class _TossTextInputStateful extends StatefulWidget {
  final String? value;
  final ValueChanged<String>? onChanged;
  final String? placeholder;
  final int? maxLength;
  final TextInputType? keyboardType;
  final String? counterText;

  const _TossTextInputStateful({
    this.value,
    this.onChanged,
    this.placeholder,
    this.maxLength,
    this.keyboardType,
    this.counterText,
  });

  @override
  State<_TossTextInputStateful> createState() => _TossTextInputStatefulState();
}

class _TossTextInputStatefulState extends State<_TossTextInputStateful> {
  late TextEditingController _controller;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
  }

  @override
  void didUpdateWidget(_TossTextInputStateful oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 외부에서 값이 변경되었을 때만 컨트롤러 업데이트
    // 사용자가 직접 입력 중이 아닐 때만 동기화 (커서 위치 보존)
    if (widget.value != oldWidget.value && widget.value != _controller.text) {
      final selection = _controller.selection;
      _controller.text = widget.value ?? '';
      // 커서 위치 복원 (가능한 경우)
      if (selection.isValid && selection.end <= _controller.text.length) {
        _controller.selection = selection;
      } else {
        _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: _hasFocus ? Colors.white : AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: _hasFocus
              ? AppColors.primaryBlue // 결정/이동용
              : AppColors.divider,
          width: _hasFocus ? 2 : 1,
        ),
      ),
      child: Focus(
        onFocusChange: (hasFocus) {
          setState(() {
            _hasFocus = hasFocus;
          });
        },
        child: TextField(
          controller: _controller,
          onChanged: (value) {
            setState(() {}); // Force rebuild to update counter
            widget.onChanged?.call(value);
          },
          maxLength: widget.maxLength,
          keyboardType: widget.keyboardType,
          style: AppTypography.body.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.placeholder,
            hintStyle: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            // 기본 counter 숨기기 (우리가 커스텀 counter를 사용하므로)
            counterText: widget.counterText ?? (widget.maxLength != null ? '' : null),
            counterStyle: AppTypography.small,
            // 커스텀 counter를 suffixIcon으로 표시
            suffixIcon: widget.maxLength != null && widget.counterText == null
                ? Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.lg),
                    child: Center(
                      widthFactor: 1.0,
                      child: Text(
                        '${_controller.text.length}/${widget.maxLength}',
                        style: AppTypography.small.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
