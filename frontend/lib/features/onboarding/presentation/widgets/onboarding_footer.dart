import 'package:flutter/material.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../ui/widgets/app_buttons.dart';

/// 온보딩 푸터 (CTA 버튼)
class OnboardingFooter extends StatelessWidget {
  final String buttonText;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final bool isLastStep;

  const OnboardingFooter({
    super.key,
    required this.buttonText,
    this.onPressed,
    this.isEnabled = true,
    this.isLastStep = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.pagePadding,
          right: AppSpacing.pagePadding,
          top: AppSpacing.md,
          bottom: AppSpacing.pagePadding,
        ),
        child: AppPrimaryButton(
          text: buttonText,
          onPressed: isEnabled ? onPressed : null,
        ),
      ),
    );
  }
}
