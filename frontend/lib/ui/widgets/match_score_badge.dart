import 'package:flutter/material.dart';

/// Match Score Badge component matching React implementation
class MatchScoreBadge extends StatelessWidget {
  final int score;
  final MatchScoreSize size;

  const MatchScoreBadge({
    super.key,
    required this.score,
    this.size = MatchScoreSize.small,
  });

  Color _getBackgroundColor() {
    if (score >= 90) return const Color(0xFFF0FDF4); // Green
    if (score >= 80) return const Color(0xFFEFF6FF); // Blue
    return const Color(0xFFF7F8FA); // Gray
  }

  Color _getTextColor() {
    if (score >= 90) return const Color(0xFF16A34A); // Green
    if (score >= 80) return const Color(0xFF2563EB); // Blue
    return const Color(0xFF6B7280); // Gray
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case MatchScoreSize.small:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case MatchScoreSize.medium:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case MatchScoreSize.large:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    }
  }

  double _getFontSize() {
    switch (size) {
      case MatchScoreSize.small:
        return 11;
      case MatchScoreSize.medium:
        return 14;
      case MatchScoreSize.large:
        return 16;
    }
  }

  double _getIconSize() {
    switch (size) {
      case MatchScoreSize.small:
        return 12;
      case MatchScoreSize.medium:
        return 14;
      case MatchScoreSize.large:
        return 16;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: _getPadding(),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite,
            size: _getIconSize(),
            color: _getTextColor(),
          ),
          const SizedBox(width: 4),
          Text(
            '$score%',
            style: TextStyle(
              fontSize: _getFontSize(),
              fontWeight: FontWeight.w600,
              color: _getTextColor(),
            ),
          ),
        ],
      ),
    );
  }
}

enum MatchScoreSize {
  small,
  medium,
  large,
}
