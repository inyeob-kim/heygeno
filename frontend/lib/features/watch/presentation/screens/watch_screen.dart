import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../ui/widgets/top_bar.dart';
import '../../../../../ui/widgets/figma_pill_chip.dart';
import '../../../../../ui/widgets/figma_empty_state.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/app_radius.dart';
import '../../../../../core/widgets/loading.dart';
import '../controllers/watch_controller.dart';
import '../widgets/tracking_product_card.dart';

/// 실제 API 데이터를 사용하는 Watch Screen (관심 화면)
class WatchScreen extends ConsumerStatefulWidget {
  const WatchScreen({super.key});

  @override
  ConsumerState<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends ConsumerState<WatchScreen> {
  @override
  void initState() {
    super.initState();
    // 화면 진입 시 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(watchControllerProvider.notifier).loadTrackingProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(watchControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const TopBar(title: '찜한 사료'),
            Expanded(
              child: _buildBody(state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(WatchState state) {
    // 로딩 상태
    if (state.isLoading) {
      return const Center(child: LoadingWidget());
    }

    // 에러 상태
    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                state.error!,
                style: AppTypography.body.copyWith(color: AppColors.dangerRed),
              ),
              const SizedBox(height: AppSpacing.lg),
              CupertinoButton(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(AppRadius.md),
                onPressed: () {
                  ref.read(watchControllerProvider.notifier).loadTrackingProducts();
                },
                child: Text(
                  '다시 시도',
                  style: AppTypography.button.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 빈 상태
    if (state.trackingProducts.isEmpty) {
      return FigmaEmptyState(
        emoji: '❤️',
        title: '찜한 사료가 없어요',
        description: '관심 있는 사료를 찜하고 가격 알림을 받아보세요',
        ctaText: '사료 둘러보기',
        onCTA: () {
          context.go('/market');
        },
      );
    }

    final sortedProducts = state.sortedProducts;
    final cheaperCount = state.cheaperCount;
    
    // sortedProducts가 비어있는 경우 추가 체크
    if (sortedProducts.isEmpty) {
      return FigmaEmptyState(
        emoji: '❤️',
        title: '찜한 사료가 없어요',
        description: '관심 있는 사료를 찜하고 가격 알림을 받아보세요',
        ctaText: '사료 둘러보기',
        onCTA: () {
          context.go('/market');
        },
      );
    }

    return CupertinoScrollbar(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),
            // Summary - Numbers First
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${state.trackingProducts.length}',
                      style: AppTypography.h1Mobile.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '총 찜',
                      style: AppTypography.small.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.xl),
                Container(
                  width: 1,
                  height: 48,
                  color: AppColors.divider,
                ),
                const SizedBox(width: AppSpacing.xl),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$cheaperCount',
                            style: AppTypography.h1Mobile.copyWith(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue, // 결정/비교용
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '/ ${state.trackingProducts.length}개',
                            style: AppTypography.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '평균 대비 저렴',
                        style: AppTypography.small.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            // Sorting Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              child: Row(
                children: [
                  FigmaPillChip(
                    label: '저렴한 순',
                    selected: state.sortOption == SortOption.priceLow,
                    onTap: () => ref
                        .read(watchControllerProvider.notifier)
                        .setSortOption(SortOption.priceLow),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FigmaPillChip(
                    label: '가격 변동 낮은 순',
                    selected: state.sortOption == SortOption.priceStable,
                    onTap: () => ref
                        .read(watchControllerProvider.notifier)
                        .setSortOption(SortOption.priceStable),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FigmaPillChip(
                    label: '인기순',
                    selected: state.sortOption == SortOption.popular,
                    onTap: () => ref
                        .read(watchControllerProvider.notifier)
                        .setSortOption(SortOption.popular),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Product Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.lg,
                mainAxisSpacing: AppSpacing.lg,
                childAspectRatio: 0.68,
              ),
              itemCount: sortedProducts.length,
              itemBuilder: (context, index) {
                final product = sortedProducts[index];
                return TrackingProductCard(
                  data: product,
                  onTap: () {
                    // TODO: 상품 상세 화면으로 이동 (productId 필요)
                    // context.push('/products/${product.productId}');
                  },
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl * 2),
          ],
        ),
      ),
    );
  }
}
