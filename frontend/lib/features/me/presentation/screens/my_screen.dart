import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../ui/widgets/app_top_bar.dart';
import '../../../../../ui/widgets/setting_item.dart';
import '../../../../../ui/widgets/toggle_switch.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/app_radius.dart';
import '../../../../../core/utils/snackbar_helper.dart';
import '../../../../../core/widgets/loading.dart';
import '../../../../../design_system/components/empty_state.dart';
import '../../../../../core/widgets/modal_bottom_sheet_wrapper.dart';
import '../../../../../core/constants/pet_constants.dart';
import '../../../../../features/home/presentation/widgets/pet_avatar.dart';
import '../../../../../data/models/pet_summary_dto.dart';
import '../../../../../app/router/route_paths.dart';
import '../controllers/my_controller.dart';
import '../../../../../features/benefits/presentation/controllers/benefits_controller.dart';
import '../../../../../data/repositories/auth_repository.dart';
import 'package:pet_food_app/l10n/app_localizations.dart';

/// 실제 API 데이터를 사용하는 My Screen
class MyScreen extends ConsumerStatefulWidget {
  const MyScreen({super.key});

  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen> {
  final ScrollController _scrollController = ScrollController();

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
        body: SafeArea(
          child: Column(
            children: [
              AppTopBar(title: AppLocalizations.of(context)!.tab_more, showBackButton: false),
              const Expanded(
                child: Center(child: LoadingWidget()),
              ),
            ],
          ),
        ),
      );
    }

    // 에러 상태
    if (state.error != null && state.petSummary == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: EmptyState(
          icon: Icons.error_outline,
          title: state.error ?? AppLocalizations.of(context)!.me_errorOccurred,
          buttonText: AppLocalizations.of(context)!.action_tryAgain,
          onButtonPressed: () => ref.read(myControllerProvider.notifier).refresh(),
        ),
      );
    }

    // Benefits 데이터 가져오기 (Rewards 메뉴용)
    final benefitsState = ref.watch(benefitsControllerProvider);
    final rewardsPoints = benefitsState.totalPoints;
    final rewardsMissionsCount = benefitsState.missions.length;
    
    final settings = [
      SettingData(
        icon: Icons.card_giftcard,
        label: AppLocalizations.of(context)!.me_rewards,
        value: AppLocalizations.of(context)!.me_rewardsSubtitle(rewardsPoints, rewardsMissionsCount),
        hasChevron: true,
        onTap: () {
          context.push(RoutePaths.benefits);
        },
      ),
      SettingData(
        icon: Icons.notifications_outlined,
        label: AppLocalizations.of(context)!.me_notificationSettings,
        hasToggle: true,
        onTap: null, // 토글로 처리
      ),
      SettingData(
        icon: Icons.lock_outline,
        label: AppLocalizations.of(context)!.me_privacy,
        hasChevron: true,
        onTap: () {
          context.push('/me/privacy');
        },
      ),
      SettingData(
        icon: Icons.help_outline,
        label: AppLocalizations.of(context)!.me_help,
        hasChevron: true,
        onTap: () {
          context.push('/me/help');
        },
      ),
      SettingData(
        icon: Icons.email_outlined,
        label: AppLocalizations.of(context)!.me_contact,
        hasChevron: true,
        onTap: () {
          context.push('/me/contact');
        },
      ),
      SettingData(
        icon: Icons.lightbulb_outline,
        label: AppLocalizations.of(context)!.me_featureRequest,
        hasChevron: true,
        onTap: () {
          _showFeatureRequestBottomSheet(context);
        },
      ),
      SettingData(
        icon: Icons.info_outline,
        label: AppLocalizations.of(context)!.me_appInfo,
        hasChevron: true,
        onTap: () {
          context.push('/me/app-info');
        },
      ),
      SettingData(
        icon: Icons.logout,
        label: AppLocalizations.of(context)!.me_logOut,
        hasChevron: false,
        isDestructive: true,
        onTap: () => _showLogOutConfirm(context),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(title: AppLocalizations.of(context)!.tab_more, showBackButton: false),
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
                      // Settings
                      _buildSectionCard(
                        title: AppLocalizations.of(context)!.me_settings,
                        subtitle: AppLocalizations.of(context)!.me_settingsSubtitle,
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

  void _showLogOutConfirm(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.me_logOutConfirmTitle),
        content: Text(l10n.me_logOutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go(RoutePaths.start);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.drop,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.me_logOut),
          ),
        ],
      ),
    );
  }

  // 섹션 카드 공통 위젯
  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Container(
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
      ),
    );
  }

  /// 펫 프로필 카드 섹션 (가로 스크롤)
  Widget _buildPetProfilesSection(List<PetSummaryDto> pets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.me_ourPets,
          style: AppTypography.body.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          AppLocalizations.of(context)!.me_ourPetsSubtitle,
          style: AppTypography.small.copyWith(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
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
          // 펫 카드 클릭 시 전환 기능 제거 (Manage Pets만 유지)
          // 전환은 TopBar의 PetSelector에서만 가능
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
                  pet.species == 'DOG' 
                      ? AppLocalizations.of(context)!.pet_species_dog
                      : AppLocalizations.of(context)!.pet_species_cat,
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
                    PetConstants.getAgeStageText(context, pet.ageStage) ?? '',
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
                  AppLocalizations.of(context)!.me_addPet,
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

    if (setting.isDestructive) {
      return SettingItem(
        icon: setting.icon,
        label: setting.label,
        subtitle: setting.value,
        onTap: setting.onTap,
        trailing: trailing,
        iconBackgroundColor: const Color(0xFFFEE2E2),
        iconColor: const Color(0xFFDC2626),
      );
    }

    return SettingItem.withAutoColors(
      label: setting.label,
      subtitle: setting.value,
      icon: setting.icon,
      onTap: setting.onTap,
      trailing: trailing,
    );
  }

  /// 펫 전환 확인 다이얼로그 표시


  /// 기능 요청 바텀시트 표시
  void _showFeatureRequestBottomSheet(BuildContext context) {
    final textController = TextEditingController();
    
    ModalBottomSheetWrapper.show(
      context,
      title: AppLocalizations.of(context)!.me_featureRequest,
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
                hintText: AppLocalizations.of(context)!.me_featureRequestHint,
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
                    SnackBarHelper.showError(context, AppLocalizations.of(context)!.me_featureRequestEmpty);
                    return;
                  }
                  // TODO: 기능 요청 저장 로직 추가
                  Navigator.of(context).pop();
                  SnackBarHelper.showSuccess(context, AppLocalizations.of(context)!.me_featureRequestSent);
                },
                child: Text(
                  AppLocalizations.of(context)!.common_save,
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
  final bool isDestructive;
  final VoidCallback? onTap;

  SettingData({
    required this.icon,
    required this.label,
    this.value,
    this.hasToggle = false,
    this.hasChevron = false,
    this.isDestructive = false,
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
