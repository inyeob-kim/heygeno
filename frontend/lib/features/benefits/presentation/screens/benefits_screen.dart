import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../ui/widgets/top_bar.dart';
import '../../../../../ui/widgets/card_container.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/app_radius.dart';
import '../../../../../core/widgets/loading.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../controllers/benefits_controller.dart';

/// 실제 API 데이터를 사용하는 Benefits Screen
class BenefitsScreen extends ConsumerStatefulWidget {
  const BenefitsScreen({super.key});

  @override
  ConsumerState<BenefitsScreen> createState() => _BenefitsScreenState();
}

class _BenefitsScreenState extends ConsumerState<BenefitsScreen> {
  @override
  void initState() {
    super.initState();
    // 화면 진입 시 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(benefitsControllerProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(benefitsControllerProvider);

    // 로딩 상태
    if (state.isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(child: LoadingWidget()),
      );
    }

    // 에러 상태
    if (state.error != null && state.missions.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: EmptyStateWidget(
          title: state.error ?? '오류가 발생했습니다',
          buttonText: '다시 시도',
          onButtonPressed: () => ref.read(benefitsControllerProvider.notifier).refresh(),
        ),
      );
    }

    final totalPoints = state.totalPoints;
    final availablePoints = state.availablePoints;
    final missions = state.missions;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const TopBar(title: '혜택'),
            Expanded(
              child: CupertinoScrollbar(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.xl),
                      // Hero Point Section
                      CardContainer(
                        isHomeStyle: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.card_giftcard,
                                  size: 24,
                                  color: AppColors.primaryBlue, // 결정/정보용
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  '내 포인트',
                                  style: AppTypography.body.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              '${totalPoints.toLocaleString()}P',
                              style: AppTypography.h1Mobile.copyWith(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue, // 결정/정보용
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              '${availablePoints.toLocaleString()}P 더 받을 수 있어요',
                              style: AppTypography.body.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Mission List Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '미션 완료하고 포인트 받기',
                            style: AppTypography.body.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${state.completedCount}/${missions.length}',
                            style: AppTypography.small.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Mission Cards
                      ...missions.map((mission) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _buildMissionCard(context, mission),
                      )),
                      const SizedBox(height: AppSpacing.lg),
                      // Points Usage
                      CardContainer(
                        isHomeStyle: true,
                        backgroundColor: AppColors.primaryBlue.withOpacity(0.05),
                        showBorder: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '포인트 사용 방법',
                              style: AppTypography.body.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              '100P = 100원 할인 (다음 구매 시 자동 적용)',
                              style: AppTypography.small.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl * 2),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionCard(BuildContext context, MissionData mission) {
    return CardContainer(
      isHomeStyle: true,
      backgroundColor: mission.completed
          ? AppColors.petGreen.withOpacity(0.1) // 상태/안심용
          : Colors.white,
      showBorder: mission.completed,
      onTap: () {
        _showMissionBottomSheet(context, mission);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: mission.completed
                  ? AppColors.petGreen // 상태/안심용
                  : Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              mission.completed ? Icons.check_circle : Icons.flag,
              size: 18,
              color: mission.completed
                  ? Colors.white
                  : AppColors.iconMuted,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: AppTypography.body.copyWith(
                    color: mission.completed
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  mission.description,
                  style: AppTypography.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs + 2),
                Row(
                  children: [
                    Text(
                      '+${mission.reward}P',
                      style: AppTypography.small.copyWith(
                        color: mission.completed
                            ? AppColors.petGreen // 상태/안심용
                            : AppColors.primaryBlue, // 결정/정보용
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!mission.completed) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '· ${mission.current}/${mission.total} 완료',
                        style: AppTypography.small.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            size: 20,
            color: AppColors.iconMuted,
          ),
        ],
      ),
    );
  }

  void _showMissionBottomSheet(BuildContext context, MissionData mission) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _MissionBottomSheet(mission: mission),
    );
  }
}

/// 미션 상세 바텀 시트
class _MissionBottomSheet extends StatelessWidget {
  final MissionData mission;

  const _MissionBottomSheet({required this.mission});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Grabber
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon and Title
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: mission.completed
                                    ? AppColors.petGreen // 상태/안심용
                                    : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.divider,
                                  width: 1,
                                ),
                              ),
                          child: Icon(
                            mission.completed 
                                ? Icons.check_circle 
                                : Icons.flag,
                            size: 24,
                            color: mission.completed
                                ? Colors.white
                                : AppColors.iconMuted,
                          ),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mission.title,
                                    style: AppTypography.h2.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    '+${mission.reward}P',
                                    style: AppTypography.body.copyWith(
                                      color: mission.completed
                                          ? AppColors.petGreen // 상태/안심용
                                          : AppColors.primaryBlue, // 결정/정보용
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        // Description
                        Text(
                          mission.description,
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        // Progress
                        if (!mission.completed) ...[
                          Text(
                            '진행 상황',
                            style: AppTypography.body.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${mission.current}/${mission.total} 완료',
                                style: AppTypography.small.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '${((mission.current / mission.total) * 100).round()}%',
                                style: AppTypography.small.copyWith(
                                  color: AppColors.primaryBlue, // 결정/정보용
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.divider,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: mission.total > 0
                                  ? mission.current / mission.total
                                  : 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue, // 결정/정보용
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xl * 2),
                      ],
                    ),
                  ),
                ),
                // Fixed Bottom Button
                if (!mission.completed)
                  Container(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: AppColors.divider,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: SafeArea(
                      child: SizedBox(
                        width: double.infinity,
                        child: CupertinoButton(
                          color: AppColors.primaryBlue, // 결정/이동용
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          onPressed: () {
                            Navigator.pop(context);
                            // TODO: 미션 시작 로직 구현
                          },
                          child: Text(
                            '시작하기',
                            style: AppTypography.button.copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

extension IntExtension on int {
  String toLocaleString() {
    return toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
}
