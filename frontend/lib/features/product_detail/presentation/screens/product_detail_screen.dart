import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../core/utils/price_formatter.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/loading.dart';
import '../../../../../ui/widgets/figma_app_bar.dart';
import '../../../../../ui/widgets/app_buttons.dart';
import '../../../../../ui/widgets/price_delta.dart';
import '../controllers/product_detail_controller.dart';
import '../../../watch/presentation/controllers/watch_controller.dart';

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
    
    // 에러 메시지 표시
    ref.listen<String?>(productDetailControllerProvider(widget.productId).select((s) => s.error), (previous, next) {
      if (next != null && next.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

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
                              color: AppColors.background,
                              child: const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 64,
                                  color: AppColors.textSecondary,
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
                                onTap: () async {
                                  await ref
                                      .read(productDetailControllerProvider(widget.productId).notifier)
                                      .toggleFavorite();
                                  // WatchController 갱신
                                  ref.read(watchControllerProvider.notifier).loadTrackingProducts();
                                },
                                borderRadius: BorderRadius.circular(16), // rounded-2xl
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(16), // rounded-2xl
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    state.isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 24,
                                    color: state.isFavorite
                                        ? const Color(0xFFEF4444) // Red
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            // Product Info
                            Text(
                              product.brandName.toUpperCase(),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                letterSpacing: 0.05,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              product.productName,
                              style: AppTypography.h2.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                height: 1.25,
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
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.5,
                                    height: 1.2,
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
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            // Price Comparison Message
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(16), // rounded-2xl
                                border: Border.all(
                                  color: const Color(0xFFEF4444).withOpacity(0.2),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12), // rounded-xl
                                    ),
                                    child: const Icon(
                                      Icons.trending_down,
                                      size: 20,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '💰 평균 대비 ${state.averagePrice != null && state.currentPrice != null && state.averagePrice! > state.currentPrice! ? ((state.averagePrice! - state.currentPrice!) / state.averagePrice! * 100).round() : 0}% 저렴해요. 지금이 구매 타이밍입니다!',
                                      style: AppTypography.body.copyWith(
                                        color: const Color(0xFFEF4444),
                                        fontSize: 14,
                                        height: 1.5,
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
                              style: AppTypography.h3.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16), // rounded-2xl
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
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
                                                          ? AppColors.primary // Primary Blue #2563EB
                                                          : const Color(0xFFE5E7EB),
                                                      borderRadius: const BorderRadius.vertical(
                                                        top: Radius.circular(4),
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
                                  const SizedBox(height: AppSpacing.lg),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '최저 ${state.minPrice != null ? PriceFormatter.formatWithCurrency(state.minPrice!) : "정보 없음"}',
                                        style: AppTypography.small.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (state.averagePrice != null)
                                        Text(
                                          '평균 ${PriceFormatter.formatWithCurrency(state.averagePrice!)}',
                                          style: AppTypography.small.copyWith(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      Text(
                                        '최고 ${state.maxPrice != null ? PriceFormatter.formatWithCurrency(state.maxPrice!) : "정보 없음"}',
                                        style: AppTypography.small.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
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
                              style: AppTypography.h3.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Match Score with Bar
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.statusLight, // Light Green 배경
                                borderRadius: BorderRadius.circular(16), // rounded-2xl
                                border: Border.all(
                                  color: AppColors.status.withOpacity(0.2),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '맞춤 점수',
                                        style: AppTypography.body.copyWith(
                                          color: AppColors.textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '92%', // TODO: 실제 맞춤 점수 API 추가 시 수정
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.status, // Green
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: AppColors.status.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: 0.92, // TODO: 실제 맞춤 점수 API 추가 시 수정
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.status, // Green
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            // Match Reasons List (임시로 제거 - 추후 API에서 제공되면 추가)
                            // TODO: 추천 API에서 matchReasons 제공 시 추가
                            // Nutritional Analysis
                            if (state.ingredientAnalysis != null &&
                                state.ingredientAnalysis!.nutritionFacts.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Text(
                                '영양 성분',
                                style: AppTypography.h3.copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
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
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7), // Amber 배경
                                borderRadius: BorderRadius.circular(16), // rounded-2xl
                                border: Border.all(
                                  color: const Color(0xFFF59E0B).withOpacity(0.2),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16), // rounded-2xl
                                        ),
                                        child: const Icon(
                                          Icons.notifications,
                                          size: 24,
                                          color: Color(0xFFF59E0B), // Amber
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
                                                color: AppColors.textPrimary,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '목표 가격 이하로 떨어지면 알려드릴게요',
                                              style: AppTypography.small.copyWith(
                                                color: AppColors.textSecondary,
                                                fontSize: 14,
                                                height: 1.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: AppPrimaryButton(
                                        text: '알림 설정하기',
                                        onPressed: () {},
                                        height: 40,
                                      ),
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
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: AppColors.border,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    await ref
                        .read(productDetailControllerProvider(widget.productId).notifier)
                        .toggleFavorite();
                    // WatchController 갱신
                    ref.read(watchControllerProvider.notifier).loadTrackingProducts();
                  },
                  borderRadius: BorderRadius.circular(12), // rounded-xl
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12), // rounded-xl
                      border: Border.all(
                        color: AppColors.border,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      state.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 24,
                      color: state.isFavorite
                          ? const Color(0xFFEF4444) // Red
                          : AppColors.textSecondary, // 중성 회색
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppPrimaryButton(
                  text: '최저가 구매하기',
                  onPressed: () {},
                  height: 56,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // rounded-xl
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.body.copyWith(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: AppTypography.body.copyWith(
              color: AppColors.primary, // Primary Blue #2563EB
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
