import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/theme/app_typography.dart';
import '../../../../../core/utils/price_formatter.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/loading.dart';
import '../../../../../ui/widgets/figma_app_bar.dart';
import '../../../../../ui/widgets/figma_primary_button.dart';
import '../../../../../ui/widgets/price_delta.dart';
import '../controllers/product_detail_controller.dart';

/// 실제 API 데이터를 사용하는 Product Detail Screen
class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  @override
  void initState() {
    super.initState();
    // 화면 진입 시 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productDetailControllerProvider(widget.productId).notifier).loadProduct(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productDetailControllerProvider(widget.productId));

    // 로딩 상태
    if (state.isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(child: LoadingWidget()),
      );
    }

    // 에러 상태
    if (state.error != null && state.product == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('제품 상세'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: EmptyStateWidget(
          title: state.error ?? '오류가 발생했습니다',
          buttonText: '다시 시도',
          onButtonPressed: () => ref
              .read(productDetailControllerProvider(widget.productId).notifier)
              .loadProduct(widget.productId),
        ),
      );
    }

    final product = state.product;
    if (product == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(child: LoadingWidget()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            FigmaAppBar(
              title: '제품 상세',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Hero
                      Stack(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 320,
                            child: Container(
                              color: const Color(0xFFF7F8FA),
                              child: const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 64,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ),
                          // Favorite Button
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => ref
                                    .read(productDetailControllerProvider(widget.productId).notifier)
                                    .toggleFavorite(),
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    state.isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 24,
                                    color: state.isFavorite
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            // Product Info
                            Text(
                              product.brandName,
                              style: AppTypography.small.copyWith(
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              product.productName,
                              style: AppTypography.h2.copyWith(
                                color: const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Price Hero - Strongest Visual
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  state.currentPrice != null
                                      ? PriceFormatter.formatWithCurrency(state.currentPrice!)
                                      : '가격 정보 없음',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111827),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                if (state.averagePrice != null &&
                                    state.currentPrice != null &&
                                    state.averagePrice! > state.currentPrice!)
                                  PriceDelta(
                                    currentPrice: state.currentPrice!,
                                    avgPrice: state.averagePrice!,
                                    size: PriceDeltaSize.large,
                                  ),
                              ],
                            ),
                            if (state.averagePrice != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                '평균 ${PriceFormatter.formatWithCurrency(state.averagePrice!)}',
                                style: AppTypography.body.copyWith(
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            // Price Comparison Message
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFFEF4444).withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.trending_down,
                                    size: 20,
                                    color: Color(0xFFEF4444),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '💰 평균 대비 ${state.averagePrice != null && state.currentPrice != null && state.averagePrice! > state.currentPrice! ? ((state.averagePrice! - state.currentPrice!) / state.averagePrice! * 100).round() : 0}% 저렴해요. 지금이 구매 타이밍입니다!',
                                      style: AppTypography.body.copyWith(
                                        color: const Color(0xFFEF4444),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Price Graph Section
                            Text(
                              '가격 추이',
                              style: AppTypography.body.copyWith(
                                color: const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F8FA),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 128,
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [65, 58, 62, 55, 60, 52, 48].asMap().entries.map((entry) {
                                        final index = entry.key;
                                        final isLatest = index == 6;
                                        return Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 2),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                Expanded(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: isLatest
                                                          ? const Color(0xFF2563EB)
                                                          : const Color(0xFFE5E7EB),
                                                      borderRadius: const BorderRadius.vertical(
                                                        top: Radius.circular(2),
                                                      ),
                                                    ),
                                                    height: double.infinity,
                                                    width: double.infinity,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '최저 ${state.minPrice != null ? PriceFormatter.formatWithCurrency(state.minPrice!) : "정보 없음"}',
                                        style: AppTypography.small.copyWith(
                                          color: const Color(0xFF6B7280),
                                        ),
                                      ),
                                      if (state.averagePrice != null)
                                        Text(
                                          '평균 ${PriceFormatter.formatWithCurrency(state.averagePrice!)}',
                                          style: AppTypography.small.copyWith(
                                            color: const Color(0xFF6B7280),
                                          ),
                                        ),
                                      Text(
                                        '최고 ${state.maxPrice != null ? PriceFormatter.formatWithCurrency(state.maxPrice!) : "정보 없음"}',
                                        style: AppTypography.small.copyWith(
                                          color: const Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Match Analysis Section - NEW & ENHANCED
                            Text(
                              '맞춤 분석',
                              style: AppTypography.h2.copyWith(
                                color: const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Match Score with Bar
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFF16A34A).withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '맞춤 점수',
                                        style: AppTypography.body.copyWith(
                                          color: const Color(0xFF111827),
                                        ),
                                      ),
                                      Text(
                                        '92%', // TODO: 실제 맞춤 점수 API 추가 시 수정
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF16A34A),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16A34A).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: 0.92, // TODO: 실제 맞춤 점수 API 추가 시 수정
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF16A34A),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Match Reasons List (임시로 제거 - 추후 API에서 제공되면 추가)
                            // TODO: 추천 API에서 matchReasons 제공 시 추가
                            // Nutritional Analysis
                            if (state.ingredientAnalysis != null &&
                                state.ingredientAnalysis!.nutritionFacts.isNotEmpty) ...[
                              Text(
                                '영양 성분',
                                style: AppTypography.body.copyWith(
                                  color: const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (state.ingredientAnalysis!.nutritionFacts.containsKey('조단백질'))
                                _buildNutritionItem(
                                  '단백질',
                                  '${state.ingredientAnalysis!.nutritionFacts['조단백질']}%',
                                ),
                              const SizedBox(height: 12),
                              if (state.ingredientAnalysis!.nutritionFacts.containsKey('조지방'))
                                _buildNutritionItem(
                                  '지방',
                                  '${state.ingredientAnalysis!.nutritionFacts['조지방']}%',
                                ),
                              const SizedBox(height: 12),
                              if (state.ingredientAnalysis!.nutritionFacts.containsKey('조섬유'))
                                _buildNutritionItem(
                                  '섬유질',
                                  '${state.ingredientAnalysis!.nutritionFacts['조섬유']}%',
                                ),
                              const SizedBox(height: 24),
                            ],
                            // Alert CTA Section
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.notifications,
                                          size: 20,
                                          color: Color(0xFFF59E0B),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '가격 알림 받기',
                                              style: AppTypography.body.copyWith(
                                                color: const Color(0xFF111827),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '목표 가격 이하로 떨어지면 알려드릴게요',
                                              style: AppTypography.small.copyWith(
                                                color: const Color(0xFF6B7280),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: FigmaPrimaryButton(
                                      text: '알림 설정하기',
                                      variant: ButtonVariant.small,
                                      onPressed: () {},
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // Sticky Bottom Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Color(0xFFF7F8FA),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        state.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 24,
                        color: state.isFavorite
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF111827),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: FigmaPrimaryButton(
                  text: '최저가 구매하기',
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.body.copyWith(
              color: const Color(0xFF111827),
            ),
          ),
          Text(
            value,
            style: AppTypography.body.copyWith(
              color: const Color(0xFF2563EB),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
