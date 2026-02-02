import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

/// 진행률 바
class ProgressBar extends StatelessWidget {
  final double progress; // 0.0 ~ 1.0

  const ProgressBar({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        backgroundColor: AppColors.divider,
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
        minHeight: 4,
      ),
    );
  }
}
