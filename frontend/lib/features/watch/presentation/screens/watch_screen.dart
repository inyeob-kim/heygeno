import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../ui/widgets/figma_app_bar.dart';
import '../../../../../ui/widgets/figma_pill_chip.dart';
import '../../../../../ui/widgets/figma_empty_state.dart';
import '../../../../../app/theme/app_typography.dart';
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
            const FigmaAppBar(title: '찜한 사료'),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              state.error!,
              style: AppTypography.body.copyWith(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(watchControllerProvider.notifier).loadTrackingProducts();
              },
              child: const Text('다시 시도'),
            ),
          ],
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

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Summary - Numbers First
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${state.trackingProducts.length}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '총 찜',
                      style: AppTypography.small.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Container(
                  width: 1,
                  height: 48,
                  color: const Color(0xFFE5E7EB),
                ),
                const SizedBox(width: 24),
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
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '/ ${state.trackingProducts.length}개',
                            style: AppTypography.body.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '평균 대비 저렴',
                        style: AppTypography.small.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Sorting Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Row(
                children: [
                  FigmaPillChip(
                    label: '저렴한 순',
                    selected: state.sortOption == SortOption.priceLow,
                    onTap: () => ref
                        .read(watchControllerProvider.notifier)
                        .setSortOption(SortOption.priceLow),
                  ),
                  const SizedBox(width: 8),
                  FigmaPillChip(
                    label: '가격 변동 낮은 순',
                    selected: state.sortOption == SortOption.priceStable,
                    onTap: () => ref
                        .read(watchControllerProvider.notifier)
                        .setSortOption(SortOption.priceStable),
                  ),
                  const SizedBox(width: 8),
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
            const SizedBox(height: 16),
            // Product Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
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
          ],
        ),
      ),
    );
  }
}
