import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../app/router/route_paths.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../ui/widgets/card_container.dart';
import '../../../../data/models/pet_summary_dto.dart';

/// 내 아이 카드 컴포넌트
class PetCard extends StatelessWidget {
  final PetSummaryDto pet;

  const PetCard({
    super.key,
    required this.pet,
  });

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이름 · 나이 · 몸무게
          Row(
            children: [
              Text(
                pet.name,
                style: AppTypography.h3,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '· ${pet.ageSummary} · ${pet.weightKg}kg',
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          
          // 건강 포인트
          Row(
            children: [
              Text(
                '건강 포인트: ',
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                pet.healthSummary,
                style: AppTypography.body2,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          
          // 프로필 수정 링크
          GestureDetector(
            onTap: () {
              context.push(RoutePaths.petProfile);
            },
            child: Text(
              '프로필 수정',
              style: AppTypography.body2.copyWith(
                color: AppColors.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
