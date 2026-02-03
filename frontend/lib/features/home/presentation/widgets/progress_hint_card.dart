import 'package:flutter/material.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../ui/widgets/card_container.dart';

/// 진행 힌트 카드 (로딩 중 신뢰 구축)
class ProgressHintCard extends StatelessWidget {
  const ProgressHintCard({super.key});

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '분석 중...',
            style: AppTypography.h3,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildHintItem('✔', '알레르기 제외 완료', true),
          const SizedBox(height: AppSpacing.sm),
          _buildHintItem('✔', '나이/체중 반영 완료', true),
          const SizedBox(height: AppSpacing.sm),
          _buildHintItem('⏳', '최저가 트래킹 준비 중', false),
        ],
      ),
    );
  }

  Widget _buildHintItem(String icon, String text, bool isCompleted) {
    return Row(
      children: [
        Text(
          icon,
          style: AppTypography.body,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          text,
          style: AppTypography.body2.copyWith(
            color: isCompleted
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
