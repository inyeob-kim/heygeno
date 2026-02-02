import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../app/router/route_paths.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../app/theme/app_radius.dart';
import '../../../../../app/theme/app_shadows.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../ui/icons/app_icons.dart';
import '../../../../../ui/widgets/app_buttons.dart';

/// DESIGN_GUIDE.md 스타일 Today EmptyState (프로필 없음)
class TodayEmptyState extends StatelessWidget {
  final VoidCallback? onAddProfile;
  final VoidCallback? onBrowseProducts;

  const TodayEmptyState({
    super.key,
    this.onAddProfile,
    this.onBrowseProducts,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePaddingHorizontal,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // AddCard (흰색 카드, radius 18, 중앙 + 아이콘)
            _AddCard(
              onTap: onAddProfile ?? () {
                context.push(RoutePaths.petProfile);
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            // 설명 텍스트 (Lead: 17px, color: muted)
            Text(
              '프로필을 등록하면 우리 아이에게 맞는 사료를 추천하고\n가격 알림을 받을 수 있어요',
              style: AppTypography.lead,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            // Primary CTA 버튼
            AppPrimaryButton(
              text: '반려동물 프로필 추가',
              onPressed: onAddProfile ?? () {
                context.push(RoutePaths.petProfile);
              },
            ),
            // Secondary CTA 버튼 (선택적)
            if (onBrowseProducts != null) ...[
              const SizedBox(height: AppSpacing.buttonRowGap),
              AppSecondaryButton(
                text: '대표 사료 둘러보기',
                onPressed: onBrowseProducts,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// AddCard 위젯 (DESIGN_GUIDE.md 스타일)
class _AddCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: AppColors.divider,
            width: 1,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // + 아이콘
            AppIcons.addCircle(size: 56),
            const SizedBox(height: AppSpacing.md),
            // '추가' 텍스트
            Text(
              '추가',
              style: AppTypography.body2,
            ),
          ],
        ),
      ),
    );
  }
}
