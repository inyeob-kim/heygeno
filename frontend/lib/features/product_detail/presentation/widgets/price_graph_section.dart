import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/utils/price_formatter.dart';
import 'package:pet_food_app/l10n/app_localizations.dart';

/// 가격 변동 그래프 섹션
class PriceGraphSection extends ConsumerWidget {
  final int? minPrice;
  final int? maxPrice;
  final int? averagePrice;
  final List<PriceDataPoint>? priceHistory; // 최근 14일 가격 데이터

  const PriceGraphSection({
    super.key,
    this.minPrice,
    this.maxPrice,
    this.averagePrice,
    this.priceHistory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.productDetailWidget_priceGraph,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.productDetailWidget_priceGraphDescription,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // 그래프 영역
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _buildGraph(context),
        ),
        const SizedBox(height: 16),
        
        // 숫자 요약
        _buildPriceSummary(context),
      ],
    );
  }

  Widget _buildGraph(BuildContext context) {
    // TODO: 실제 그래프 라이브러리로 구현 (fl_chart 등)
    // 임시로 간단한 바 차트 스타일
    if (priceHistory == null || priceHistory!.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.productDetailWidget_noPriceData,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: priceHistory!.asMap().entries.map((entry) {
          final data = entry.value;
          final maxValue = maxPrice ?? data.price;
          final heightRatio = data.price / maxValue;
          
          Color barColor;
          if (data.price == minPrice) {
            barColor = AppColors.positiveGreen; // 최저가: 초록
          } else if (data.price == maxPrice) {
            barColor = Colors.red.shade200; // 최고가: 연한 빨강
          } else {
            barColor = Colors.grey.shade400; // 평균: 회색
          }
          
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: 150 * heightRatio,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriceSummary(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        if (minPrice != null)
          _buildSummaryItem(
            context,
            AppLocalizations.of(context)!.productDetailWidget_lowestPrice,
            PriceFormatter.formatWithCurrency(minPrice!),
            AppColors.positiveGreen,
          ),
        if (averagePrice != null)
          _buildSummaryItem(
            context,
            AppLocalizations.of(context)!.productDetailWidget_averagePrice,
            PriceFormatter.formatWithCurrency(averagePrice!),
            Colors.grey.shade600,
          ),
        if (maxPrice != null)
          _buildSummaryItem(
            context,
            AppLocalizations.of(context)!.productDetailWidget_highestPrice,
            PriceFormatter.formatWithCurrency(maxPrice!),
            Colors.red.shade300,
          ),
      ],
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

}

/// 가격 데이터 포인트
class PriceDataPoint {
  final int price;
  final DateTime date;

  PriceDataPoint({
    required this.price,
    required this.date,
  });
}
