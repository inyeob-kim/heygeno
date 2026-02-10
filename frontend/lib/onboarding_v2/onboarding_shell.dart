import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/app_spacing.dart';
import 'widgets/progress_bar.dart';
import 'widgets/primary_cta_button.dart';

/// Onboarding shell layout - DESIGN_GUIDE v1.0 준수
class OnboardingShell extends StatefulWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback? onBack;
  final String emoji;
  final String title;
  final String? subtitle;
  final Widget child;
  final String ctaText;
  final bool ctaDisabled;
  final VoidCallback onCTAClick;
  final CTASecondary? ctaSecondary;
  final Widget? leadingWidget;

  const OnboardingShell({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.onBack,
    required this.emoji,
    required this.title,
    this.subtitle,
    required this.child,
    required this.ctaText,
    this.ctaDisabled = false,
    required this.onCTAClick,
    this.ctaSecondary,
    this.leadingWidget,
  });

  @override
  State<OnboardingShell> createState() => _OnboardingShellState();
}

class _OnboardingShellState extends State<OnboardingShell>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                0,
              ),
              child: ProgressBar(
                current: widget.currentStep,
                total: widget.totalSteps,
              ),
            ),

            // Back Button
            if (widget.onBack != null)
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.md,
                  left: AppSpacing.lg,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 0,
                    onPressed: widget.onBack,
                    child: const Icon(
                      Icons.arrow_back_ios,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),

            // Scrollable Content
            Expanded(
              child: CupertinoScrollbar(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    widget.onBack != null ? AppSpacing.xl : AppSpacing.xl * 1.5,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Leading Widget (e.g., Logo)
                          if (widget.leadingWidget != null) ...[
                            Center(child: widget.leadingWidget!),
                            const SizedBox(height: AppSpacing.xl),
                          ],

                          // Emoji (only show if not empty) - 섹션 헤더로 사용
                          if (widget.emoji.isNotEmpty) ...[
                            Text(
                              widget.emoji,
                              style: const TextStyle(fontSize: 64),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                          ],

                          // Title
                          Text(
                            widget.title,
                            style: AppTypography.h2.copyWith(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),

                          // Subtitle
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              widget.subtitle!,
                              style: AppTypography.body.copyWith(
                                fontSize: 15,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],

                          const SizedBox(height: AppSpacing.xl * 1.5),

                          // Content
                          widget.child,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom CTA
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: AppColors.divider,
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                children: [
                  PrimaryCTAButton(
                    text: widget.ctaText,
                    onPressed: widget.ctaDisabled ? null : widget.onCTAClick,
                    disabled: widget.ctaDisabled,
                  ),
                  if (widget.ctaSecondary != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    PrimaryCTAButton(
                      text: widget.ctaSecondary!.text,
                      onPressed: widget.ctaSecondary!.onClick,
                      isSecondary: true,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Secondary CTA configuration
class CTASecondary {
  final String text;
  final VoidCallback onClick;

  const CTASecondary({
    required this.text,
    required this.onClick,
  });
}
