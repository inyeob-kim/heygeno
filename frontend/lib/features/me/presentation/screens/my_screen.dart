import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../ui/widgets/top_bar.dart';
import '../../../../../ui/widgets/match_score_badge.dart';
import '../../../../../ui/widgets/card_container.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/app_radius.dart';
import '../../../../../core/utils/price_formatter.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/utils/snackbar_helper.dart';
import '../../../../../core/widgets/loading.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/loading_dialog.dart';
import '../../../../../core/widgets/modal_bottom_sheet_wrapper.dart';
import '../../../../../ui/widgets/setting_item.dart';
import '../../../../../ui/widgets/toggle_switch.dart';
import '../../../../../ui/widgets/section_header.dart';
import '../../../../../features/home/presentation/widgets/pet_avatar.dart';
import '../../../../../features/home/presentation/widgets/pet_constants.dart';
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
          context.push('privacy');
        },
      ),
      SettingData(
        icon: Icons.help_outline,
        label: '도움말',
        hasChevron: true,
        onTap: () {
          context.push('help');
        },
      ),
      SettingData(
        icon: Icons.email_outlined,
        label: '문의하기',
        hasChevron: true,
        onTap: () {
          context.push('contact');
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
          context.push('app-info');
        },
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const TopBar(title: '더보기'),
            Expanded(
              child: CupertinoScrollbar(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.xl),
                      // 펫 프로필 카드 섹션 (가로 스크롤)
                      _buildPetProfilesSection(state.pets),
                      const SizedBox(height: AppSpacing.lg),
                      // Recent Recommendation History
                      CardContainer(
                        isHomeStyle: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionHeader(
                              title: '최근 추천 히스토리',
                              actionText: state.recentRecommendations.isNotEmpty ? '전체보기' : null,
                              onActionTap: state.recentRecommendations.isNotEmpty
                                  ? () {
                                      // TODO: 전체 추천 히스토리 화면으로 이동
                                    }
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            if (state.recentRecommendations.isNotEmpty)
                              ..._buildRecentRecommendations(state.recentRecommendations)
                            else
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                child: Text(
                                  '아직 추천 히스토리가 없어요',
                                  style: AppTypography.small.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Settings
                      CardContainer(
                        isHomeStyle: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...settings.map((setting) => Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: _buildSettingItem(setting),
                            )),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Point Summary Section
                      CardContainer(
                        isHomeStyle: true,
                        backgroundColor: AppColors.primaryBlue.withOpacity(0.05),
                        showBorder: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '사용 가능 포인트',
                                  style: AppTypography.body.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${state.totalPoints.toLocaleString()}P',
                                  style: AppTypography.h3.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryBlue, // 결정/정보용
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              '다음 구매 시 할인받으세요',
                              style: AppTypography.small.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            SizedBox(
                              width: double.infinity,
                              child: CupertinoButton(
                                color: AppColors.primaryBlue, // 결정/이동용
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                                onPressed: () {},
                                child: Text(
                                  '혜택 보기',
                                  style: AppTypography.button.copyWith(color: Colors.white),
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

  /// 펫 프로필 카드 섹션 (가로 스크롤)
  Widget _buildPetProfilesSection(List<PetSummaryDto> pets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '우리 아이들',
          style: AppTypography.body.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 140,
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
          width: 120,
          child: CardContainer(
            isHomeStyle: true,
            showBorder: true,
            borderColor: isPrimary ? AppColors.primaryBlue : null,
            borderWidth: isPrimary ? 2.0 : null,
            padding: const EdgeInsets.symmetric(
              vertical: 6,
              horizontal: AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PetAvatar(
                  species: pet.species,
                  size: 36,
                  backgroundColor: AppColors.petGreen.withOpacity(0.1),
                ),
                const SizedBox(height: 3),
                Text(
                  pet.name,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  pet.species == 'DOG' ? '강아지' : '고양이',
                  style: AppTypography.small.copyWith(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (pet.ageStage != null) ...[
                  const SizedBox(height: 0),
                  Text(
                    PetConstants.getAgeStageText(pet.ageStage) ?? '',
                    style: AppTypography.small.copyWith(
                      fontSize: 8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 펫 추가하기 카드
  Widget _buildAddPetCard() {
    return Padding(
      padding: EdgeInsets.only(right: 0),
      child: GestureDetector(
        onTap: () {
          // 아이 추가 모드로 온보딩 화면 이동 (닉네임 스킵)
          context.go('${RoutePaths.onboardingV2}?mode=add_pet');
        },
        child: SizedBox(
          width: 120,
          child: CardContainer(
            isHomeStyle: true,
            backgroundColor: AppColors.background,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 6,
                horizontal: AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryBlue.withOpacity(0.3),
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 22,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '아이 추가하기',
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: AppColors.primaryBlue,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
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
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.image_outlined,
                  size: 32,
                  color: AppColors.iconMuted,
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
      icon: setting.icon,
      label: setting.label,
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
      final petService = ref.read(petServiceProvider);
      await petService.setPrimaryPet(targetPet.petId);

      // 화면 새로고침
      await ref.read(myControllerProvider.notifier).refresh();
      ref.read(homeControllerProvider.notifier).initialize();

      // 로딩 닫기
      if (mounted) {
        LoadingDialog.hide(context);
      }

      // 성공 메시지
      if (mounted) {
        SnackBarHelper.showSuccess(context, '${targetPet.name}로 전환되었습니다');
      }
    } catch (e) {
      // 로딩 닫기
      if (mounted) {
        LoadingDialog.hide(context);
      }

      // 에러 메시지
      if (mounted) {
        SnackBarHelper.showError(context, '아이 전환에 실패했습니다: ${e.toString()}');
      }
    }
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
