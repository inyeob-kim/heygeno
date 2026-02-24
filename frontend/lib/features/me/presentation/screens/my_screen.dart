import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../ui/widgets/app_top_bar.dart';
import '../../../../../ui/widgets/pet_selector.dart';
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
import '../../../../../data/repositories/auth_repository.dart';
import '../../../../../features/benefits/presentation/controllers/benefits_controller.dart';
import '../../../../../domain/services/user_service.dart';
import '../../../../../data/repositories/user_repository.dart';
import 'package:pet_food_app/l10n/app_localizations.dart';

/// 계정 허브 화면 (More 탭)
/// 관리·설정·계정만. 추천/가격 알림/기능 요약 없음.
class MyScreen extends ConsumerStatefulWidget {
  const MyScreen({super.key});

  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _notificationEnabled = true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myControllerProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    if (state.isLoading && state.pets.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: '',
                showBackButton: false,
                backgroundColor: Colors.white,
                leadingWidget: const PetSelector(),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    color: AppColors.textSecondary,
                    iconSize: 26,
                    onPressed: () {},
                  ),
                ],
              ),
              const Expanded(child: Center(child: LoadingWidget())),
            ],
          ),
        ),
      );
    }

    if (state.error != null && state.pets.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: EmptyState(
          icon: Icons.error_outline,
          title: state.error ?? l10n.me_errorOccurred,
          buttonText: l10n.action_tryAgain,
          onButtonPressed: () => ref.read(myControllerProvider.notifier).refresh(),
        ),
      );
    }

    final petName = state.petSummary?.name ?? 'your pet';
    const sectionSpacing = 28.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: '',
              showBackButton: false,
              backgroundColor: Colors.white,
              leadingWidget: const PetSelector(),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_none),
                  color: AppColors.textSecondary,
                  iconSize: 26,
                  onPressed: () {},
                ),
              ],
            ),
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
                      _buildAccountCard(context, petName),
                      const SizedBox(height: sectionSpacing),
                      _buildMyPetsSection(context, state.pets),
                      const SizedBox(height: sectionSpacing),
                      _buildRewardsSection(context),
                      const SizedBox(height: sectionSpacing),
                      _buildAppPreferencesSection(context),
                      const SizedBox(height: sectionSpacing),
                      _buildPrivacyAndDataSection(context),
                      const SizedBox(height: sectionSpacing),
                      _buildSupportSection(context),
                      const SizedBox(height: sectionSpacing),
                      _buildLogOut(context),
                      const SizedBox(height: AppSpacing.xxxl),
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

  /// Account Hero Card — radius 20, light blue tint 2–3%, Rewards bold; 0P hint when zero
  Widget _buildAccountCard(BuildContext context, String petName) {
    final l10n = AppLocalizations.of(context)!;
    final benefitsState = ref.watch(benefitsControllerProvider);
    final points = benefitsState.totalPoints;
    final isZeroPoints = points == 0;

    return FutureBuilder<UserDto?>(
      future: ref.read(userServiceProvider).getCurrentUser().then<UserDto?>((v) => v).catchError((_) => null),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final displayName = user?.nickname ?? 'Guest';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.025),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.me_accountTitle,
                style: AppTypography.body.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.me_accountSubtitle(petName),
                style: AppTypography.small.copyWith(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_outline,
                      size: 28,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${l10n.me_rewards}: ${points}P',
                          style: AppTypography.small.copyWith(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (isZeroPoints) ...[
                          const SizedBox(height: 6),
                          Text(
                            l10n.me_rewardsZeroHint,
                            style: AppTypography.small.copyWith(
                              fontSize: 12,
                              color: AppColors.textSecondary.withOpacity(0.6),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.push('/me/account'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(
                      color: AppColors.primary.withOpacity(0.15),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  child: Text(
                    l10n.me_manageAccount,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Rewards section — pure white card, lower shadow; labels 70%/60% opacity; number primary blue
  Widget _buildRewardsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final benefitsState = ref.watch(benefitsControllerProvider);
    final totalPoints = benefitsState.totalPoints;
    final missions = benefitsState.missions;
    final completedCount = benefitsState.completedCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.me_rewards,
          style: AppTypography.body.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.me_rewardsEarnSubtitle,
          style: AppTypography.small.copyWith(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.me_availablePoints,
                style: AppTypography.small.copyWith(
                  fontSize: 13,
                  color: AppColors.textSecondary.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${totalPoints}P',
                style: AppTypography.body.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${l10n.me_missionsCompleted}: $completedCount / ${missions.length}',
                style: AppTypography.small.copyWith(
                  fontSize: 13,
                  color: AppColors.textSecondary.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.push(RoutePaths.benefits),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  child: Text(
                    l10n.me_viewRewards,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// My Pets — 관리 전용, 추천/점수/현재 사료 표시 금지
  Widget _buildMyPetsSection(BuildContext context, List<PetSummaryDto> pets) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.me_myPets,
          style: AppTypography.body.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.me_myPetsSubtitle,
          style: AppTypography.small.copyWith(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        ...pets.map((pet) => _buildPetCard(context, pet)),
        _buildAddPetCard(context),
      ],
    );
  }

  Widget _buildPetCard(BuildContext context, PetSummaryDto pet) {
    final l10n = AppLocalizations.of(context)!;
    final speciesText = pet.species == 'DOG'
        ? l10n.pet_species_dog
        : l10n.pet_species_cat;
    final ageText = PetConstants.getAgeStageText(context, pet.ageStage) ?? '';
    final weightText = '${pet.weightKg.toStringAsFixed(1)} kg';
    final subtitle = [speciesText, if (ageText.isNotEmpty) ageText, weightText]
        .join(' · ');
    final hasAllergies = pet.foodAllergies.isNotEmpty ||
        (pet.otherAllergies != null && pet.otherAllergies!.isNotEmpty);
    final hasHealthFocus = pet.healthConcerns.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/pet-update/${pet.petId}'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PetAvatar(species: pet.species, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTypography.small.copyWith(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (hasAllergies) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (pet.foodAllergies.isNotEmpty)
                            ...pet.foodAllergies.take(3).map(
                                  (a) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      a,
                                      style: AppTypography.small.copyWith(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                          if (pet.otherAllergies != null &&
                              pet.otherAllergies!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.divider,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                pet.otherAllergies!,
                                style: AppTypography.small.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ],
                    if (hasHealthFocus) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: pet.healthConcerns.take(2).map((c) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.statusLight,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              c,
                              style: AppTypography.small.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.status,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                l10n.home_editProfile,
                style: AppTypography.small.copyWith(
                  color: AppColors.primary.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 20, color: AppColors.primary.withOpacity(0.9)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddPetCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('${RoutePaths.onboardingV2}?mode=add_pet'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.add, color: AppColors.textSecondary, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                l10n.me_addPet,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// App Preferences — Notifications, Units, Language, Dark mode (minimal divider)
  Widget _buildAppPreferencesSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _buildSection(
      title: l10n.me_appPreferences,
      children: [
        _buildSettingRow(
          icon: Icons.notifications_outlined,
          label: l10n.me_notificationSettings,
          trailing: ToggleSwitch(
            value: _notificationEnabled,
            onChanged: (v) => setState(() => _notificationEnabled = v),
          ),
        ),
        _buildSettingRow(
          icon: Icons.straighten_outlined,
          label: l10n.me_units,
          trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.iconMuted),
          onTap: () {},
        ),
        _buildSettingRow(
          icon: Icons.language_outlined,
          label: l10n.me_language,
          trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.iconMuted),
          onTap: () {},
        ),
        _buildSettingRow(
          icon: Icons.dark_mode_outlined,
          label: l10n.me_darkMode,
          trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.iconMuted),
          onTap: () {},
          showDivider: false,
        ),
      ],
    );
  }

  /// Privacy & Data
  Widget _buildPrivacyAndDataSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _buildSection(
      title: l10n.me_privacyAndData,
      children: [
        _buildSettingRow(
          icon: Icons.security_outlined,
          label: l10n.me_dataPermissions,
          trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.iconMuted),
          onTap: () {},
        ),
        _buildSettingRow(
          icon: Icons.download_outlined,
          label: l10n.me_downloadMyData,
          trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.iconMuted),
          onTap: () {},
        ),
        _buildSettingRow(
          icon: Icons.delete_outline,
          label: l10n.me_deleteAccount,
          trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.iconMuted),
          onTap: () {},
        ),
        _buildSettingRow(
          icon: Icons.privacy_tip_outlined,
          label: l10n.me_privacyPolicy,
          trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.iconMuted),
          onTap: () => context.push('/me/privacy'),
        ),
        _buildSettingRow(
          icon: Icons.description_outlined,
          label: l10n.me_termsOfService,
          trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.iconMuted),
          onTap: () {},
          showDivider: false,
        ),
      ],
    );
  }

  /// Support
  Widget _buildSupportSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _buildSection(
      title: l10n.me_support,
      children: [
        _buildSettingRow(
          icon: Icons.help_outline,
          label: l10n.me_helpCenter,
          trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.iconMuted),
          onTap: () => context.push('/me/help'),
        ),
        _buildSettingRow(
          icon: Icons.email_outlined,
          label: l10n.me_contact,
          trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.iconMuted),
          onTap: () => context.push('/me/contact'),
        ),
        _buildSettingRow(
          icon: Icons.lightbulb_outline,
          label: l10n.me_featureRequest,
          trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.iconMuted),
          onTap: () => _showFeatureRequestBottomSheet(context),
        ),
        _buildSettingRow(
          icon: Icons.info_outline,
          label: l10n.me_appVersionLabel,
          subtitle: '1.0.0 (1)',
          onTap: () => context.push('/me/app-info'),
          showDivider: false,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.body.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  static final Color _listIconColor = AppColors.iconMuted.withOpacity(0.7);

  Widget _buildSettingRow({
    required IconData icon,
    required String label,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool showDivider = true,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingItem(
          icon: icon,
          label: label,
          subtitle: subtitle,
          onTap: onTap,
          trailing: trailing,
          iconColor: _listIconColor,
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.border.withOpacity(0.12),
          ),
      ],
    );
  }

  Widget _buildLogOut(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: TextButton(
          onPressed: () => _showLogOutConfirm(context),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.drop.withOpacity(0.9),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            l10n.me_logOut,
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.drop.withOpacity(0.9),
              fontSize: 15,
            ),
          ),
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

  void _showFeatureRequestBottomSheet(BuildContext context) {
    final textController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    ModalBottomSheetWrapper.show(
      context,
      title: l10n.me_featureRequest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: l10n.me_featureRequestHint,
                hintStyle: AppTypography.body.copyWith(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.all(AppSpacing.md),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (textController.text.trim().isEmpty) {
                    SnackBarHelper.showError(context, l10n.me_featureRequestEmpty);
                    return;
                  }
                  Navigator.of(context).pop();
                  SnackBarHelper.showSuccess(context, l10n.me_featureRequestSent);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: Text(l10n.common_save, style: AppTypography.button.copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
