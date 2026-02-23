import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../app/router/route_paths.dart';
import '../../../../../ui/theme/app_colors.dart';
import '../../../../../ui/theme/app_typography.dart';
import '../../../../data/models/pet_summary_dto.dart';
import '../../../../utils/formatters.dart';
import 'package:pet_food_app/l10n/app_localizations.dart';

/// 내 아이 섹션 (토스 스타일 - 카드 없음)
class PetCard extends StatelessWidget {
  final PetSummaryDto pet;

  const PetCard({
    super.key,
    required this.pet,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 이름 · 나이 · 몸무게
        Row(
          children: [
            Text(
              pet.name,
              style: AppTypography.title,
            ),
            const SizedBox(width: 8),
            Text(
              '· ${pet.ageSummary} · ${Formatters.weightLb(pet.weightKg)}',
              style: AppTypography.sub,
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // 건강 포인트 (sub 색상)
        Text(
          pet.healthSummary,
          style: AppTypography.sub.copyWith(
            color: AppColors.textSub,
          ),
        ),
        const SizedBox(height: 8),
        
        // 프로필 수정 링크
        GestureDetector(
          onTap: () {
            context.push(RoutePaths.petProfile);
          },
          child: Text(
            AppLocalizations.of(context)!.home_editProfile,
            style: AppTypography.sub.copyWith(
              color: AppColors.textSecondary, // 중성 회색 텍스트
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
