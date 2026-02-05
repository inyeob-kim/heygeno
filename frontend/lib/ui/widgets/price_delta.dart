import 'package:flutter/material.dart';

/// Price Delta component matching React implementation
class PriceDelta extends StatelessWidget {
  final int currentPrice;
  final int avgPrice;
  final PriceDeltaSize size;

  const PriceDelta({
    super.key,
    required this.currentPrice,
    required this.avgPrice,
    this.size = PriceDeltaSize.medium,
  });

  int _calculateDelta() {
    if (avgPrice <= 0) return 0;
    return ((avgPrice - currentPrice) / avgPrice * 100).round();
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case PriceDeltaSize.small:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case PriceDeltaSize.medium:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case PriceDeltaSize.large:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    }
  }

  double _getFontSize() {
    switch (size) {
      case PriceDeltaSize.small:
        return 11;
      case PriceDeltaSize.medium:
        return 14;
      case PriceDeltaSize.large:
        return 16;
    }
  }

  double _getIconSize() {
    switch (size) {
      case PriceDeltaSize.small:
        return 12;
      case PriceDeltaSize.medium:
        return 14;
      case PriceDeltaSize.large:
        return 16;
    }
  }

  @override
  Widget build(BuildContext context) {
    final delta = _calculateDelta();
    
    if (delta <= 0) return const SizedBox.shrink();

    return Container(
      padding: _getPadding(),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.arrow_downward,
            size: _getIconSize(),
            color: const Color(0xFFEF4444),
          ),
          const SizedBox(width: 4),
          Text(
            '$delta% 좋은 딜',
            style: TextStyle(
              fontSize: _getFontSize(),
              fontWeight: FontWeight.w600,
              color: const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }
}

enum PriceDeltaSize {
  small,
  medium,
  large,
}
