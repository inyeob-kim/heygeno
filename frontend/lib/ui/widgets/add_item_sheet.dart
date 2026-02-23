import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'package:pet_food_app/l10n/app_localizations.dart';

/// 추가 아이템 Bottom Sheet
class AddItemSheet extends StatelessWidget {
  const AddItemSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheetRadius),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grabber
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sectionGap),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Options
          _SheetOption(
            icon: Icons.search,
            title: AppLocalizations.of(context)!.addItem_searchFood,
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.common_comingSoon)),
              );
            },
          ),
          const Divider(height: 1),
          _SheetOption(
            icon: Icons.link,
            title: AppLocalizations.of(context)!.addItem_addByLink,
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.common_comingSoon)),
              );
            },
          ),
          const Divider(height: 1),
          _SheetOption(
            icon: Icons.notifications_outlined,
            title: AppLocalizations.of(context)!.addItem_keywordAlert,
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.common_comingSoon)),
              );
            },
          ),
          
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.iconMuted),
      title: Text(title, style: AppTypography.body),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.sectionGap,
      ),
    );
  }
}
