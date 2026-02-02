import 'package:flutter/material.dart';
import '../../../../../ui/widgets/app_scaffold.dart';
import '../../../../../ui/widgets/app_header.dart';
import '../../../../../ui/widgets/card_container.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../app/theme/app_spacing.dart';

/// 혜택 화면 (DESIGN_GUIDE.md 스타일)
class BenefitsScreen extends StatelessWidget {
  const BenefitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const AppHeader(title: '혜택'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePaddingHorizontal),
        children: [
          // 포인트 섹션
          CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // H3: 18px
                Text('내 포인트', style: AppTypography.h3),
                const SizedBox(height: AppSpacing.gridGap),
                // H2: 26px
                Text('0 P', style: AppTypography.h2),
                const SizedBox(height: 4),
                // Body2: muted
                Text(
                  '사료 구매 시 포인트를 적립할 수 있습니다',
                  style: AppTypography.body2,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.gridGap),
          
          // 적립 내역 섹션
          CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // H3: 18px
                Text('적립 내역', style: AppTypography.h3),
                const SizedBox(height: AppSpacing.gridGap),
                _HistoryItem(
                  title: '로얄캐닌 미니 어덜트 구매',
                  date: '2024.01.15',
                  points: '+500P',
                  isPositive: true,
                ),
                const Divider(height: 1),
                _HistoryItem(
                  title: '힐스 프리미엄 케어 구매',
                  date: '2024.01.10',
                  points: '+300P',
                  isPositive: true,
                ),
                const Divider(height: 1),
                _HistoryItem(
                  title: '포인트 사용',
                  date: '2024.01.05',
                  points: '-200P',
                  isPositive: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.gridGap),
          
          // 혜택 안내 섹션
          CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // H3: 18px
                Text('혜택 안내', style: AppTypography.h3),
                const SizedBox(height: AppSpacing.gridGap),
                _BenefitInfo(
                  title: '구매 적립',
                  description: '사료 구매 시 결제 금액의 1% 적립',
                ),
                const SizedBox(height: AppSpacing.gridGap),
                _BenefitInfo(
                  title: '리뷰 적립',
                  description: '사료 리뷰 작성 시 100P 적립',
                ),
                const SizedBox(height: AppSpacing.gridGap),
                _BenefitInfo(
                  title: '포인트 사용',
                  description: '1P = 1원으로 사용 가능',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final String title;
  final String date;
  final String points;
  final bool isPositive;

  const _HistoryItem({
    required this.title,
    required this.date,
    required this.points,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.gridGap),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Body: 16px
                Text(title, style: AppTypography.body),
                const SizedBox(height: 4),
                // Caption: 13px
                Text(date, style: AppTypography.caption),
              ],
            ),
          ),
          // Body: bold, color: green/red
          Text(
            points,
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w700,
              color: isPositive ? AppColors.positiveGreen : AppColors.dangerRed,
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitInfo extends StatelessWidget {
  final String title;
  final String description;

  const _BenefitInfo({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Body: bold
        Text(
          title,
          style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        // Caption: 13px
        Text(description, style: AppTypography.caption),
      ],
    );
  }
}
