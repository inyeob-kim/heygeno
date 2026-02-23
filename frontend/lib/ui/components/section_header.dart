import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// 섹션 헤더 컴포넌트 (토스 스타일)
/// 카드/구분선 없이 '타이틀 + 서브 + 더보기'로 섹션 구분
/// 
/// @deprecated Use `design_system/components/section_header.dart` SectionHeader instead.
/// This widget is kept for backward compatibility and will be removed in a future version.
@Deprecated('Use design_system/components/section_header.dart SectionHeader instead')
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onTapMore;
  final String? trailingText;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onTapMore,
    this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title: theme.title
                Text(
                  title,
                  style: AppTypography.title,
                ),
                // Subtitle: theme.sub (있는 경우)
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: AppTypography.sub,
                  ),
                ],
              ],
            ),
          ),
          // Trailing: 아이콘 버튼(chevron_right) 또는 텍스트
          if (onTapMore != null)
            IconButton(
              onPressed: onTapMore,
              icon: Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.iconMuted,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            )
          else if (trailingText != null)
            Text(
              trailingText!,
              style: AppTypography.sub.copyWith(
                color: AppColors.textSub,
              ),
            ),
        ],
      ),
    );
  }
}
