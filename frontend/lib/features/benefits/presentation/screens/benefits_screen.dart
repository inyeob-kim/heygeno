import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../ui/widgets/app_top_bar.dart';
import '../../../../../app/router/route_paths.dart';
import '../../../../../data/models/mission_dto.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/app_radius.dart';
import '../../../../../core/widgets/loading.dart';
import '../../../../../design_system/components/empty_state.dart';
import '../controllers/benefits_controller.dart';
// Design System
import '../../../../../design_system/components/index.dart';
// i18n
import 'package:pet_food_app/l10n/app_localizations.dart';

/// 실제 API 데이터를 사용하는 Benefits Screen
class BenefitsScreen extends ConsumerStatefulWidget {
  const BenefitsScreen({super.key});

  @override
  ConsumerState<BenefitsScreen> createState() => _BenefitsScreenState();
}

class _BenefitsScreenState extends ConsumerState<BenefitsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(benefitsControllerProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(benefitsControllerProvider);

    // 로딩 상태
    if (state.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              AppTopBar(title: AppLocalizations.of(context)!.section_rewards, showBackButton: true),
              const Expanded(
                child: Center(child: LoadingWidget()),
              ),
            ],
          ),
        ),
      );
    }

    // 에러 상태
    if (state.error != null && state.missions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: EmptyState(
          icon: Icons.error_outline,
          title: state.error ?? AppLocalizations.of(context)!.error_occurred,
          buttonText: AppLocalizations.of(context)!.action_tryAgain,
          onButtonPressed: () => ref.read(benefitsControllerProvider.notifier).refresh(),
        ),
      );
    }

    final totalPoints = state.totalPoints;
    final availablePoints = state.availablePoints;
    final missions = state.missions;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(title: AppLocalizations.of(context)!.section_rewards, showBackButton: true),
            Expanded(
              child: CupertinoScrollbar(
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.xl),
                      // Hero Point Section
                      Container(
                        padding: const EdgeInsets.all(20), // Card Padding
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16), // rounded-2xl
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.benefits_myPoints,
                                  style: AppTypography.body.copyWith(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFCD34D), // Amber 300 - 더 밝은 노란색
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'P',
                                          style: TextStyle(
                                            color: Color(0xFFF59E0B), // Amber 500 - 주황색
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFCD34D), // Amber 300 - 더 밝은 노란색
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'P',
                                      style: TextStyle(
                                        color: Color(0xFFF59E0B), // Amber 500 - 주황색
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${totalPoints.toLocaleString()}',
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary, // 검은색
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context)!.benefits_morePointsAvailable(availablePoints.toInt()),
                              style: AppTypography.body.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Mission Cards Container
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16), // rounded-2xl
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Mission List Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)!.benefits_completeMissions,
                                    style: AppTypography.h3.copyWith(
                                      color: AppColors.textPrimary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${state.completedCount}/${missions.length}',
                                  style: AppTypography.small.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Mission Cards (경계선 없이)
                            ...missions.map((mission) {
                              return _buildMissionCard(context, mission);
                            }),
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

  Widget _buildMissionCard(BuildContext context, MissionDto mission) {
    // 미션 타입별 아이콘 및 색상 매핑
    final icon = _getMissionIcon(mission.title);
    final missionColor = _getMissionColor(mission.title);
    
    return GestureDetector(
      onTap: () {
        _showMissionBottomSheet(context, mission);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12), // 상하 패딩만
        margin: EdgeInsets.zero, // 마진 제거
        decoration: BoxDecoration(
          color: Colors.transparent, // 배경 투명
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이모지 + 아이콘 컨테이너 (동그라미)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: mission.completed
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.status,
                          AppColors.status.withOpacity(0.8),
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          missionColor['main']!,
                          missionColor['main']!.withOpacity(0.8),
                        ],
                      ),
                shape: BoxShape.circle, // 완전한 동그라미
                boxShadow: [
                  BoxShadow(
                    color: mission.completed
                        ? AppColors.status.withOpacity(0.3)
                        : missionColor['main']!.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: mission.completed
                    ? const Icon(
                        Icons.check_circle,
                        size: 26,
                        color: Colors.white,
                      )
                    : Icon(
                        icon,
                        size: 26,
                        color: Colors.white,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: AppTypography.body.copyWith(
                              color: mission.completed
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                            children: [
                              TextSpan(text: mission.title),
                              TextSpan(
                                text: ' ${AppLocalizations.of(context)!.mission_getReward(mission.reward)}',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (mission.completed)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.status,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.mission_completed,
                            style: AppTypography.small.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mission.description,
                    style: AppTypography.small.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!mission.completed && mission.targetValue > 1) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.mission_progressCompleted(mission.currentValue, mission.targetValue),
                        style: AppTypography.small.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  /// 미션 제목에 따라 아이콘 반환 (귀엽고 트렌디한 스타일)
  IconData _getMissionIcon(String title) {
    if (title.contains('찜') || title.contains('추천')) {
      return Icons.favorite; // 하트 아이콘 (찜)
    } else if (title.contains('알림') || title.contains('가격')) {
      return Icons.notifications_active; // 활성 알림 아이콘
    } else if (title.contains('프로필') || title.contains('업데이트')) {
      return Icons.account_circle; // 원형 프로필 아이콘
    } else if (title.contains('구매') || title.contains('제품')) {
      return Icons.shopping_cart; // 장바구니 아이콘
    } else if (title.contains('리뷰') || title.contains('작성')) {
      return Icons.rate_review; // 별점 리뷰 아이콘
    }
    return Icons.emoji_events; // 트로피 아이콘 (기본)
  }

  /// 미션 제목에 따라 색상 반환 (main, light)
  Map<String, Color> _getMissionColor(String title) {
    if (title.contains('찜') || title.contains('추천')) {
      return {
        'main': const Color(0xFFF59E0B), // Amber 500
        'light': const Color(0xFFFEF3C7), // Amber 100
      };
    } else if (title.contains('알림') || title.contains('가격')) {
      return {
        'main': const Color(0xFF8B5CF6), // Violet 500
        'light': const Color(0xFFEDE9FE), // Violet 100
      };
    } else if (title.contains('프로필') || title.contains('업데이트')) {
      return {
        'main': const Color(0xFF14B8A6), // Teal 500
        'light': const Color(0xFFCCFBF1), // Teal 100
      };
    } else if (title.contains('구매') || title.contains('제품')) {
      return {
        'main': const Color(0xFF10B981), // Emerald 500
        'light': const Color(0xFFD1FAE5), // Emerald 100
      };
    } else if (title.contains('리뷰') || title.contains('작성')) {
      return {
        'main': const Color(0xFFEC4899), // Pink 500
        'light': const Color(0xFFFCE7F3), // Pink 100
      };
    }
    return {
      'main': AppColors.primary, // 기본 파란색
      'light': AppColors.primaryLight,
    };
  }

  void _showMissionBottomSheet(BuildContext context, MissionDto mission) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _MissionBottomSheet(mission: mission),
    );
  }
}

/// 미션 상세 바텀 시트
class _MissionBottomSheet extends ConsumerWidget {
  final MissionDto mission;

  const _MissionBottomSheet({required this.mission});

  IconData _getMissionIcon(String title) {
    if (title.contains('찜') || title.contains('추천')) {
      return Icons.favorite; // 하트 아이콘 (찜)
    } else if (title.contains('알림') || title.contains('가격')) {
      return Icons.notifications_active; // 활성 알림 아이콘
    } else if (title.contains('프로필') || title.contains('업데이트')) {
      return Icons.account_circle; // 원형 프로필 아이콘
    } else if (title.contains('구매') || title.contains('제품')) {
      return Icons.shopping_cart; // 장바구니 아이콘
    } else if (title.contains('리뷰') || title.contains('작성')) {
      return Icons.rate_review; // 별점 리뷰 아이콘
    }
    return Icons.emoji_events; // 트로피 아이콘 (기본)
  }

  Map<String, Color> _getMissionColor(String title) {
    if (title.contains('찜') || title.contains('추천')) {
      return {
        'main': const Color(0xFFF59E0B), // Amber 500
        'light': const Color(0xFFFEF3C7), // Amber 100
      };
    } else if (title.contains('알림') || title.contains('가격')) {
      return {
        'main': const Color(0xFF8B5CF6), // Violet 500
        'light': const Color(0xFFEDE9FE), // Violet 100
      };
    } else if (title.contains('프로필') || title.contains('업데이트')) {
      return {
        'main': const Color(0xFF14B8A6), // Teal 500
        'light': const Color(0xFFCCFBF1), // Teal 100
      };
    } else if (title.contains('구매') || title.contains('제품')) {
      return {
        'main': const Color(0xFF10B981), // Emerald 500
        'light': const Color(0xFFD1FAE5), // Emerald 100
      };
    } else if (title.contains('리뷰') || title.contains('작성')) {
      return {
        'main': const Color(0xFFEC4899), // Pink 500
        'light': const Color(0xFFFCE7F3), // Pink 100
      };
    }
    return {
      'main': AppColors.primary, // 기본 파란색
      'light': AppColors.primaryLight,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionColor = _getMissionColor(mission.title);
    
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: ui.Radius.circular(AppRadius.lg),
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
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    gradient: mission.completed
                                        ? LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              AppColors.status,
                                              AppColors.status.withOpacity(0.8),
                                            ],
                                          )
                                        : LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              missionColor['main']!,
                                              missionColor['main']!.withOpacity(0.8),
                                            ],
                                          ),
                                    shape: BoxShape.circle, // 완전한 동그라미
                                    boxShadow: [
                                      BoxShadow(
                                        color: mission.completed
                                            ? AppColors.status.withOpacity(0.3)
                                            : missionColor['main']!.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: mission.completed
                                        ? const Icon(
                                            Icons.check_circle,
                                            size: 34,
                                            color: Colors.white,
                                          )
                                        : Icon(
                                            _getMissionIcon(mission.title),
                                            size: 34,
                                            color: Colors.white,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mission.title,
                                        style: AppTypography.h3.copyWith(
                                          color: AppColors.textPrimary,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: mission.completed
                                              ? AppColors.statusLight
                                              : missionColor['light']!,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '💰',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '+${mission.reward}P',
                                              style: AppTypography.body.copyWith(
                                                color: mission.completed
                                                    ? AppColors.status
                                                    : missionColor['main']!,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
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
                            AppLocalizations.of(context)!.mission_progress,
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
                                AppLocalizations.of(context)!.mission_progressCompleted(mission.currentValue, mission.targetValue),
                                style: AppTypography.small.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '${((mission.currentValue / mission.targetValue) * 100).round()}%',
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
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: mission.targetValue > 0
                                  ? mission.currentValue / mission.targetValue
                                  : 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primary, // Primary Blue #2563EB
                                  borderRadius: BorderRadius.circular(4),
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
                      child: PrimaryButton(
                        text: AppLocalizations.of(context)!.action_start,
                        height: 56,
                        onPressed: () async {
                          Navigator.pop(context);
                          
                          // 펫 프로필 업데이트 미션인 경우
                          if (mission.title.contains('프로필 업데이트') || 
                              mission.title.contains('업데이트')) {
                            try {
                              final petId = await ref.read(benefitsControllerProvider.notifier).getPetIdForPetUpdateMission();
                              if (petId != null && context.mounted) {
                                context.push(RoutePaths.petUpdate(petId));
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(AppLocalizations.of(context)!.error_failedToLoadPetInfo),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(AppLocalizations.of(context)!.error_failedToLoadPetInfo),
                                  ),
                                );
                              }
                            }
                          }
                          // TODO: 다른 미션 타입별 로직 구현
                        },
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
