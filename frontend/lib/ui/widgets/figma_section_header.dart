import 'package:flutter/material.dart';
import '../../app/theme/app_typography.dart';

/// Figma 디자인 기반 Section Header 위젯
class FigmaSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onViewAll;
  final bool showInfo;

  const FigmaSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onViewAll,
    this.showInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: AppTypography.h2.copyWith(
                      color: const Color(0xFF111827),
                    ),
                  ),
                  if (showInfo) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        // TODO: Show info dialog
                      },
                      child: const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: AppTypography.small.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (onViewAll != null)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onViewAll,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '전체보기',
                      style: AppTypography.small.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
