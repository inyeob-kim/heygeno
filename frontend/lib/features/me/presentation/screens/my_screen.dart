import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../ui/widgets/app_top_bar.dart';
import '../../../../../ui/widgets/match_score_badge.dart';
import '../../../../../ui/widgets/setting_item.dart';
import '../../../../../ui/widgets/toggle_switch.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/app_radius.dart';
import '../../../../../core/utils/price_formatter.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/utils/snackbar_helper.dart';
import '../../../../../core/utils/pet_update_helper.dart';
import '../../../../../core/widgets/loading.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/loading_dialog.dart';
import '../../../../../core/widgets/modal_bottom_sheet_wrapper.dart';
import '../../../../../core/constants/pet_constants.dart';
import '../../../../../features/home/presentation/widgets/pet_avatar.dart';
import '../../../../../data/models/pet_summary_dto.dart';
import '../../../../../app/router/route_paths.dart';
import '../../../../../domain/services/pet_service.dart';
import '../../../../../features/home/presentation/controllers/home_controller.dart';
import '../controllers/my_controller.dart';

/// 실제 API 데이터를 사용하는 My Screen
class MyScreen extends ConsumerStatefulWidget {
  const MyScreen({super.key});

  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen> {
  final ScrollController _scrollController = ScrollController();
  final Set<String> _dismissedUpdateCards = {}; // dismiss된 업데이트 카드 petId 저장

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  bool _notificationEnabled = true; // 알림 설정 상태

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myControllerProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myControllerProvider);

    // 로딩 상태
    if (state.isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(child: LoadingWidget()),
      );
    }

    // 에러 상태
    if (state.error != null && state.petSummary == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: EmptyStateWidget(
          title: state.error ?? '오류가 발생했습니다',
          buttonText: '다시 시도',
          onButtonPressed: () => ref.read(myControllerProvider.notifier).refresh(),
        ),
      );
    }

    final settings = [
      SettingData(
        icon: Icons.notifications_outlined,
        label: '알림 설정',
        hasToggle: true,
        onTap: null, // 토글로 처리
      ),
      SettingData(
        icon: Icons.lock_outline,
        label: '개인정보 보호',
        hasChevron: true,
        onTap: () {
          context.push('/me/privacy');
        },
      ),
      SettingData(
        icon: Icons.help_outline,
        label: '도움말',
        hasChevron: true,
        onTap: () {
          context.push('/me/help');
        },
      ),
      SettingData(
        icon: Icons.email_outlined,
        label: '문의하기',
        hasChevron: true,
        onTap: () {
          context.push('/me/contact');
        },
      ),
      SettingData(
        icon: Icons.lightbulb_outline,
        label: '기능 요청하기',
        hasChevron: true,
        onTap: () {
          _showFeatureRequestBottomSheet(context);
        },
      ),
      SettingData(
        icon: Icons.info_outline,
        label: '앱 정보',
        hasChevron: true,
        onTap: () {
          context.push('/me/app-info');
        },
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(title: '더보기', showBackButton: false),
            Expanded(
              child: CupertinoScrollbar(
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.xl),
                      // 펫 프로필 카드 섹션 (가로 스크롤)
                      _buildPetProfilesSection(state.pets),
                      const SizedBox(height: 24),
                      // Recent Recommendation History
                      _buildSectionCard(
                        title: '최근 추천 히스토리',
                        subtitle: '이전에 추천받은 사료를 확인할 수 있습니다.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (state.recentRecommendations.isNotEmpty)
                              ..._buildRecentRecommendations(state.recentRecommendations)
                            else
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  '아직 추천 히스토리가 없어요',
                                  style: AppTypography.small.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Settings
                      _buildSectionCard(
                        title: '설정',
                        subtitle: '앱 설정 및 정보를 관리할 수 있습니다.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...settings.asMap().entries.map((entry) {
                              final index = entry.key;
                              final setting = entry.value;
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: index == settings.length - 1 ? 0 : 12,
                                ),
                                child: _buildSettingItem(setting),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Point Summary Section
                      _buildSectionCard(
                        title: '사용 가능 포인트',
                        subtitle: '다음 구매 시 할인받으세요',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${state.totalPoints.toLocaleString()}P',
                                  style: AppTypography.h3.copyWith(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  '혜택 보기',
                                  style: AppTypography.button.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
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

  // 섹션 카드 공통 위젯
  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
          Text(
            title,
            style: AppTypography.body.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: AppTypography.small.copyWith(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }

  /// 펫 프로필 카드 섹션 (가로 스크롤)
  Widget _buildPetProfilesSection(List<PetSummaryDto> pets) {
    // 업데이트가 필요한 펫 찾기 (60일 이상)
    final petsNeedingUpdate = pets.where((pet) => 
      PetUpdateHelper.needsUpdate(pet.updatedAt, pet.createdAt)
    ).toList();
    
    // 가장 오래된 펫 찾기 (120일 이상)
    final oldestPet = petsNeedingUpdate.isNotEmpty
        ? petsNeedingUpdate.reduce((a, b) {
            final daysA = PetUpdateHelper.getDaysSinceUpdate(a.updatedAt, a.createdAt);
            final daysB = PetUpdateHelper.getDaysSinceUpdate(b.updatedAt, b.createdAt);
            return daysA > daysB ? a : b;
          })
        : null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '우리 아이들',
          style: AppTypography.body.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '펫 프로필을 관리하고 전환할 수 있습니다.',
          style: AppTypography.small.copyWith(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // 조건부 업데이트 카드 (120일 이상인 펫이 있고, dismiss되지 않은 경우)
        if (oldestPet != null && 
            PetUpdateHelper.getDaysSinceUpdate(oldestPet.updatedAt, oldestPet.createdAt) >= 120 &&
            !_dismissedUpdateCards.contains(oldestPet.petId))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _buildUpdatePromptCard(oldestPet),
          ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            itemCount: pets.length + 1, // 아이 목록 + 추가 카드
            itemBuilder: (context, index) {
              if (index == pets.length) {
                // 마지막: 아이 추가하기 카드
                return _buildAddPetCard();
              }
              // 아이 프로필 카드
              return _buildPetCard(pets[index]);
            },
          ),
        ),
      ],
    );
  }

  /// 펫 프로필 카드
  Widget _buildPetCard(PetSummaryDto pet) {
    final isPrimary = pet.isPrimary ?? false;
    
    return Padding(
      padding: const EdgeInsets.only(
        right: AppSpacing.md,
      ),
      child: GestureDetector(
        onTap: () {
          // 현재 아이가 아닌 경우에만 전환 확인 모달 표시
          if (!isPrimary) {
            _showPetSwitchConfirmDialog(context, pet);
          }
        },
        child: SizedBox(
          width: 220,
          height: 88,
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: isPrimary ? Border.all(
                color: AppColors.primary,
                width: 2,
              ) : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                    // 펫 아바타 (왼쪽)
                PetAvatar(
                  species: pet.species,
                      size: 64,
                ),
                    const SizedBox(width: 12),
                    // 텍스트 정보 (오른쪽)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                Text(
                  pet.name,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                              fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                Text(
                  pet.species == 'DOG' ? '강아지' : '고양이',
                  style: AppTypography.small.copyWith(
                                  fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (pet.ageStage != null) ...[
                                Text(
                                  ' • ',
                                  style: AppTypography.small.copyWith(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                  Text(
                    PetConstants.getAgeStageText(pet.ageStage) ?? '',
                    style: AppTypography.small.copyWith(
                                    fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // 업데이트 필요 배지 (오른쪽 상단)
              if (PetUpdateHelper.needsUpdate(pet.updatedAt, pet.createdAt))
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildUpdateBadge(pet),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 펫 추가하기 카드
  Widget _buildAddPetCard() {
    return Padding(
      padding: const EdgeInsets.only(
        right: AppSpacing.md,
      ),
      child: GestureDetector(
        onTap: () {
          // 아이 추가 모드로 온보딩 화면 이동 (닉네임 스킵)
          context.go('${RoutePaths.onboardingV2}?mode=add_pet');
        },
        child: SizedBox(
          width: 220,
          height: 88,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // 추가 아이콘 (왼쪽)
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.divider, // 중성 회색 배경
                    borderRadius: BorderRadius.circular(16), // rounded-2xl
                  ),
                  child: Icon(
                    Icons.add,
                    size: 32,
                    color: AppColors.textSecondary.withOpacity(0.6), // 텍스트와 같은 옅은 색상
                  ),
                ),
                const SizedBox(width: 12),
                // 텍스트 (오른쪽)
                Expanded(
                  child: Text(
                  '아이 추가하기',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                      fontSize: 18,
                    color: AppColors.textSecondary.withOpacity(0.6), // 옅은 색상
                  ),
                    maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRecentRecommendations(List<RecentRecommendationData> recommendations) {
    return recommendations.asMap().entries.map((entry) {
      final index = entry.key;
      final recommendation = entry.value;
      return Padding(
        padding: EdgeInsets.only(
          bottom: index == recommendations.length - 1 ? 0 : AppSpacing.md,
        ),
        child: GestureDetector(
          onTap: () {
            context.push('/products/${recommendation.productId}');
          },
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.divider, // 중성 회색 배경
                  borderRadius: BorderRadius.circular(12), // rounded-xl
                ),
                child: const Icon(
                  Icons.image_outlined,
                  size: 32,
                  color: AppColors.textSecondary, // 중성 회색 아이콘
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormatter.formatDateOrRecent(recommendation.recommendedAt),
                      style: AppTypography.small.copyWith(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      recommendation.productName,
                      style: AppTypography.small.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        if (recommendation.matchScore != null)
                          MatchScoreBadge(
                            score: recommendation.matchScore!,
                            size: MatchScoreSize.small,
                          ),
                        if (recommendation.matchScore != null)
                          const SizedBox(width: AppSpacing.sm),
                        if (recommendation.price != null)
                          Text(
                            PriceFormatter.formatWithCurrency(recommendation.price!),
                            style: AppTypography.small.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.iconMuted,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildSettingItem(SettingData setting) {
    Widget? trailing;
    
    if (setting.hasToggle) {
      trailing = ToggleSwitch(
        value: _notificationEnabled,
        onChanged: (value) {
          setState(() {
            _notificationEnabled = value;
          });
          // TODO: 알림 설정 저장 로직 추가
        },
      );
    } else if (setting.hasChevron) {
      trailing = const Icon(
        Icons.chevron_right,
        size: 18,
        color: AppColors.iconMuted,
      );
    }

    return SettingItem.withAutoColors(
      label: setting.label,
      icon: setting.icon,
      onTap: setting.onTap,
      trailing: trailing,
    );
  }

  /// 펫 전환 확인 다이얼로그 표시
  Future<void> _showPetSwitchConfirmDialog(BuildContext context, PetSummaryDto targetPet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
        title: Text(
          '펫 전환',
          style: AppTypography.h3.copyWith(
            fontWeight: FontWeight.w700,
            ),
          ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${targetPet.name}로 전환하시겠어요?',
              style: AppTypography.body.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '전환하면 홈 화면의 추천이 변경됩니다.',
              style: AppTypography.small.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              '취소',
              style: AppTypography.button.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          CupertinoButton(
            color: AppColors.primaryBlue,
            borderRadius: BorderRadius.circular(AppRadius.md),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              '전환',
              style: AppTypography.button.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _switchPet(targetPet);
    }
  }

  /// 펫 전환 실행
  Future<void> _switchPet(PetSummaryDto targetPet) async {
    if (!mounted) return;
    
    LoadingDialog.show(context);

    try {
      // Primary pet 설정
      await ref.read(petServiceProvider).setPrimaryPet(targetPet.petId);
      
      // 화면 새로고침
      await ref.read(myControllerProvider.notifier).refresh();
      await ref.read(homeControllerProvider.notifier).initialize();

      if (!mounted) return;
      LoadingDialog.hide(context);
      SnackBarHelper.showSuccess(context, '${targetPet.name}로 전환되었습니다');
    } catch (e) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      SnackBarHelper.showError(context, '아이 전환에 실패했습니다: ${e.toString()}');
    }
  }

  /// 업데이트 필요 배지 위젯
  Widget _buildUpdateBadge(PetSummaryDto pet) {
    final urgency = PetUpdateHelper.getUpdateUrgency(pet.updatedAt, pet.createdAt);
    
    if (urgency == UpdateUrgency.none) {
      return const SizedBox.shrink();
    }
    
    return GestureDetector(
      onTap: () {
        context.push(RoutePaths.petUpdate(pet.petId));
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.edit_note,
          size: 18,
          color: AppColors.primary,
        ),
      ),
    );
  }

  /// 업데이트 유도 카드 (조건부, dismiss 가능)
  Widget _buildUpdatePromptCard(PetSummaryDto pet) {
    final days = PetUpdateHelper.getDaysSinceUpdate(pet.updatedAt, pet.createdAt);
    final months = days ~/ 30;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED), // Amber 50
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withOpacity(0.3), // Amber 500
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${pet.name} 정보가 ${months}개월째 그대로예요!',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '체중이나 건강 고민 바뀐 거 있나요?',
                      style: AppTypography.small.copyWith(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '지금 업데이트하고 새 추천 받아보세요 🐶',
                      style: AppTypography.small.copyWith(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: AppColors.textSecondary,
                onPressed: () {
                  // TODO: dismiss 처리 (SharedPreferences에 저장, 30일 숨김)
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // 카드 dismiss (30일 숨김)
                    setState(() {
                      _dismissedUpdateCards.add(pet.petId);
                    });
                    // TODO: SharedPreferences에 저장하여 30일 동안 숨김
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: AppColors.primary),
                  ),
                  child: Text(
                    '나중에',
                    style: AppTypography.button.copyWith(
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    // 펫 프로필 업데이트 화면으로 이동
                    context.push(RoutePaths.petUpdate(pet.petId));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '업데이트 하기',
                    style: AppTypography.button.copyWith(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 기능 요청 바텀시트 표시
  void _showFeatureRequestBottomSheet(BuildContext context) {
    final textController = TextEditingController();
    
    ModalBottomSheetWrapper.show(
      context,
      title: '기능 요청하기',
                  child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 텍스트 필드
            TextField(
              controller: textController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: '원하시는 기능을 자유롭게 작성해주세요',
                hintStyle: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: AppColors.divider),
                    ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: AppColors.divider),
              ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
                ),
                contentPadding: const EdgeInsets.all(AppSpacing.md),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // 저장 버튼
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(AppRadius.md),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                onPressed: () {
                  if (textController.text.trim().isEmpty) {
                    SnackBarHelper.showError(context, '내용을 입력해주세요');
                    return;
                  }
                  // TODO: 기능 요청 저장 로직 추가
                  Navigator.of(context).pop();
                  SnackBarHelper.showSuccess(context, '기능 요청이 전송되었습니다');
                },
                child: Text(
                  '저장',
                  style: AppTypography.button.copyWith(color: Colors.white),
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }
}

class SettingData {
  final IconData icon;
  final String label;
  final String? value;
  final bool hasToggle;
  final bool hasChevron;
  final VoidCallback? onTap;

  SettingData({
    required this.icon,
    required this.label,
    this.value,
    this.hasToggle = false,
    this.hasChevron = false,
    this.onTap,
  });
}

extension IntExtension on int {
  String toLocaleString() {
    return toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
}
