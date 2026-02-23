import 'package:flutter/material.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../design_system/components/button.dart';

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
    print('[OnboardingFooter] build() called, buttonText: $buttonText, isEnabled: $isEnabled, onPressed: ${onPressed != null}');
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.md,
          bottom: AppSpacing.lg,
        ),
        child: PrimaryButton(
          text: buttonText,
          onPressed: isEnabled ? onPressed : null,
        ),
      ),
    );
  }
}
