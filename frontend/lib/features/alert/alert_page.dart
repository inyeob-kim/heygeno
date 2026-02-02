import 'package:flutter/material.dart';
import '../../../ui/widgets/app_scaffold.dart';
import '../../../ui/widgets/app_header.dart';
import '../../../ui/widgets/card_container.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_spacing.dart';

/// 알림 화면 (DESIGN_GUIDE.md 스타일)
class AlertPage extends StatelessWidget {
  const AlertPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const AppHeader(
        title: '알림',
        showNotification: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePaddingHorizontal),
        children: [
          // 가격 하락 알림 섹션
          CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // H3: 18px
                Text('가격 하락 알림', style: AppTypography.h3),
                const SizedBox(height: AppSpacing.gridGap),
                _AlertItem(
                  title: '로얄캐닌 미니 어덜트',
                  message: '평균가 대비 12% 하락',
                  price: '45,000원',
                  time: '2시간 전',
                ),
                const Divider(height: 1),
                _AlertItem(
                  title: '힐스 프리미엄 케어',
                  message: '새로운 최저가 기록',
                  price: '52,000원',
                  time: '5시간 전',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.gridGap),
          
          // 소진 임박 알림 섹션
          CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // H3: 18px
                Text('소진 임박 알림', style: AppTypography.h3),
                const SizedBox(height: AppSpacing.gridGap),
                _AlertItem(
                  title: '퍼피 초이스',
                  message: '재고가 부족합니다',
                  price: '38,000원',
                  time: '1일 전',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  final String title;
  final String message;
  final String price;
  final String time;

  const _AlertItem({
    required this.title,
    required this.message,
    required this.price,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.gridGap),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Body: 16px, bold
                Text(
                  title,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                // Body2: muted
                Text(
                  message,
                  style: AppTypography.body2,
                ),
                const SizedBox(height: 4),
                // Body: 16px
                Text(
                  price,
                  style: AppTypography.body,
                ),
              ],
            ),
          ),
          // Caption: 13px, muted
          Text(
            time,
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}