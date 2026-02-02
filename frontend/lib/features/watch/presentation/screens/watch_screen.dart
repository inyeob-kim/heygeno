import 'package:flutter/material.dart';
import '../../../../../ui/widgets/app_scaffold.dart';
import '../../../../../ui/widgets/app_header.dart';
import '../../../../../ui/widgets/card_container.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../app/theme/app_spacing.dart';

/// 관심(알림) 화면 (DESIGN_GUIDE.md 스타일)
class WatchScreen extends StatelessWidget {
  const WatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const AppHeader(title: '내 사료'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePaddingHorizontal),
        children: [
          // 추적 중 사료 카드들
          _TrackingCard(
            title: '로얄캐닌 미니 어덜트',
            price: '45,000원',
            isAlertOn: true,
          ),
          const SizedBox(height: AppSpacing.gridGap),
          _TrackingCard(
            title: '힐스 프리미엄 케어',
            price: '52,000원',
            isAlertOn: false,
          ),
          const SizedBox(height: AppSpacing.gridGap),
          _TrackingCard(
            title: '퍼피 초이스',
            price: '38,000원',
            isAlertOn: true,
          ),
        ],
      ),
    );
  }
}

class _TrackingCard extends StatelessWidget {
  final String title;
  final String price;
  final bool isAlertOn;

  const _TrackingCard({
    required this.title,
    required this.price,
    required this.isAlertOn,
  });

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // H3: 18px
                Text(title, style: AppTypography.h3),
                const SizedBox(height: 4),
                // Body: 16px
                Text(price, style: AppTypography.body),
              ],
            ),
          ),
          Switch(
            value: isAlertOn,
            onChanged: (value) {
              // TODO: 알림 설정 업데이트
            },
          ),
        ],
      ),
    );
  }
}
