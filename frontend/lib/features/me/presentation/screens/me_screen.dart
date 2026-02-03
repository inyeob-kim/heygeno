import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../ui/widgets/app_scaffold.dart';
import '../../../../../ui/widgets/app_header.dart';
import '../../../../../ui/widgets/card_container.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../app/theme/app_spacing.dart';
import 'package:pet_food_app/features/home/presentation/controllers/home_controller.dart';

/// 마이 화면 (DESIGN_GUIDE.md 스타일)
class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeControllerProvider);
    final petName = homeState.petSummary?.name ?? '우리 아이';
    final healthSummary = homeState.petSummary?.healthSummary ?? '특이사항 없음';
    
    // 건강 포인트 요약 문구 생성
    final healthSummaryText = healthSummary.isEmpty || healthSummary == '특이사항 없음'
        ? '특이사항 없음, 건강해요!'
        : '$healthSummary, 꼼꼼히 챙겨요';

    return AppScaffold(
      appBar: const AppHeader(
        title: '마이',
        showNotification: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePaddingHorizontal),
        children: [
          // 반려동물 건강 리포트 섹션
          CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // H3: 18px
                Text('$petName의 건강 리포트', style: AppTypography.h3),
                const SizedBox(height: AppSpacing.gridGap),
                // 건강 포인트 요약
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '💚 ',
                        style: AppTypography.body,
                      ),
                      Expanded(
                        child: Text(
                          healthSummaryText,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.gridGap),
                _ProfileItem(label: '견종', value: '골든 리트리버'),
                const SizedBox(height: AppSpacing.gridGap),
                _ProfileItem(label: '체중', value: '10-15kg'),
                const SizedBox(height: AppSpacing.gridGap),
                _ProfileItem(label: '나이', value: '성견'),
                const SizedBox(height: AppSpacing.lg),
                // 프로필 수정 링크
                GestureDetector(
                  onTap: () {
                    // TODO: 프로필 수정 화면으로 이동
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
          ),
          const SizedBox(height: AppSpacing.gridGap),
          
          // 알림 설정 섹션
          CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // H3: 18px
                Text('알림 설정', style: AppTypography.h3),
                const SizedBox(height: AppSpacing.gridGap),
                _SettingItem(
                  title: '가격 알림',
                  subtitle: '최저가 알림 받기',
                  value: true,
                  onChanged: (value) {
                    // TODO: 알림 설정 업데이트
                  },
                ),
                const Divider(height: 1),
                _SettingItem(
                  title: '푸시 알림',
                  subtitle: '앱 푸시 알림 받기',
                  value: true,
                  onChanged: (value) {
                    // TODO: 알림 설정 업데이트
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.gridGap),
          
          // 포인트 섹션
          CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // H3: 18px
                Text('포인트', style: AppTypography.h3),
                const SizedBox(height: AppSpacing.gridGap),
                // H2: 26px
                Text('0 P', style: AppTypography.h2),
                const SizedBox(height: 4),
                // Body2: muted
                Text(
                  '사료 구매 시 포인트를 적립할 수 있습니다',
                  style: AppTypography.body2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: AppTypography.caption),
        ),
        Text(value, style: AppTypography.body),
      ],
    );
  }
}

class _SettingItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingItem({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Body: 16px
              Text(title, style: AppTypography.body),
              const SizedBox(height: 4),
              // Caption: 13px
              Text(subtitle, style: AppTypography.caption),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
