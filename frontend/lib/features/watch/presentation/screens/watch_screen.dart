import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
            reasons: ['장 건강 케어', '평균가 대비 안정적'],
            isAlertOn: true,
          ),
          const SizedBox(height: AppSpacing.gridGap),
          _TrackingCard(
            title: '힐스 프리미엄 케어',
            price: '52,000원',
            reasons: ['피부 건강 케어', '최근 14일 평균 대비 할인'],
            isAlertOn: false,
          ),
          const SizedBox(height: AppSpacing.gridGap),
          _TrackingCard(
            title: '퍼피 초이스',
            price: '38,000원',
            reasons: ['알레르기 제외', '가성비 우수'],
            isAlertOn: true,
          ),
        ],
      ),
    );
  }
}

class _TrackingCard extends StatefulWidget {
  final String title;
  final String price;
  final List<String> reasons;
  final bool isAlertOn;

  const _TrackingCard({
    required this.title,
    required this.price,
    required this.reasons,
    required this.isAlertOn,
  });

  @override
  State<_TrackingCard> createState() => _TrackingCardState();
}

class _TrackingCardState extends State<_TrackingCard> {
  late bool _isAlertOn;

  @override
  void initState() {
    super.initState();
    _isAlertOn = widget.isAlertOn;
  }

  void _onSwitchChanged(bool value) {
    HapticFeedback.lightImpact();
    setState(() {
      _isAlertOn = value;
    });
    
    // 토스트 메시지
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value ? '가격 내려가면 알려드릴게요' : '알림이 꺼졌어요',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    
    // TODO: 알림 설정 업데이트
  }

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
                Text(widget.title, style: AppTypography.h3),
                const SizedBox(height: 4),
                // Body: 16px
                Text(widget.price, style: AppTypography.body),
                const SizedBox(height: AppSpacing.xs),
                // 추적 이유
                ...widget.reasons.map((reason) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      Text(
                        '• ',
                        style: AppTypography.body2,
                      ),
                      Text(
                        reason,
                        style: AppTypography.body2,
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          Switch(
            value: _isAlertOn,
            onChanged: _onSwitchChanged,
          ),
        ],
      ),
    );
  }
}
