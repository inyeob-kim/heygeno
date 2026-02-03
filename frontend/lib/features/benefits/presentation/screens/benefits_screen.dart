import 'package:flutter/material.dart';
import '../../../../../ui/widgets/app_scaffold.dart';
import '../../../../../ui/widgets/app_header.dart';
import '../../../../../ui/widgets/card_container.dart';
import '../../../../../ui/widgets/app_buttons.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../app/theme/app_spacing.dart';

/// 혜택 화면 (DESIGN_GUIDE.md 스타일)
class BenefitsScreen extends StatelessWidget {
  const BenefitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const AppHeader(title: '혜택'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePaddingHorizontal),
        children: [
          // 포인트 섹션
          CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('내 포인트', style: AppTypography.h3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '곧 시작해요 🎁',
                        style: AppTypography.small.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.gridGap),
                // H2: 26px
                Text('0 P', style: AppTypography.h2),
                const SizedBox(height: 4),
                // Body2: muted
                Text(
                  '미션을 완료하면 포인트가 쌓여요',
                  style: AppTypography.body2,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.gridGap),
          
          // 미션 카드들
          _MissionCard(
            title: '알림 설정하기',
            description: '완료하면 100P 적립',
            onTap: () {
              // TODO: 알림 설정 화면으로 이동
            },
          ),
          const SizedBox(height: AppSpacing.gridGap),
          _MissionCard(
            title: '첫 추천 확인하기',
            description: '완료하면 50P 적립',
            onTap: () {
              // TODO: 홈 화면으로 이동
            },
          ),
          const SizedBox(height: AppSpacing.gridGap),
          _MissionCard(
            title: '프로필 완성하기',
            description: '완료하면 200P 적립',
            onTap: () {
              // TODO: 프로필 화면으로 이동
            },
          ),
        ],
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onTap;

  const _MissionCard({
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: AppSecondaryButton(
              text: '시작하기',
              onPressed: onTap,
              width: 100,
            ),
          ),
        ],
      ),
    );
  }
}
