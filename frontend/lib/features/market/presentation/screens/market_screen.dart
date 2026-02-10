import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../ui/widgets/top_bar.dart';
import '../../../../../ui/widgets/figma_search_bar.dart';
import '../../../../../ui/widgets/figma_section_header.dart';
import '../../../../../ui/widgets/figma_pill_chip.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../core/widgets/loading.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../controllers/market_controller.dart';
import '../widgets/product_card.dart';

/// 실제 API 데이터를 사용하는 Market Screen
class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  @override
  void initState() {
    super.initState();
    // 화면 진입 시 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(marketControllerProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: Column(
            children: [
              // TopBar
              const TopBar(title: '사료마켓'),
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
                child: const FigmaSearchBar(placeholder: '사료 브랜드나 제품명을 검색하세요'),
              ),
              Expanded(
                child: _buildBody(state),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(MarketState state) {
    // 로딩 상태
    if (state.isLoading) {
      return const Center(child: LoadingWidget());
    }

    // 에러 상태
    if (state.error != null && state.allProducts.isEmpty) {
      return EmptyStateWidget(
        title: state.error ?? '오류가 발생했습니다',
        buttonText: '다시 시도',
        onButtonPressed: () => ref.read(marketControllerProvider.notifier).refresh(),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification is ScrollStartNotification) {
          FocusScope.of(context).unfocus();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () => ref.read(marketControllerProvider.notifier).refresh(),
        child: CupertinoScrollbar(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hot Deals Section
                if (state.hotDealProducts.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const FigmaSectionHeader(
                          title: '오늘의 핫딜',
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.hotDealProducts.length,
                      itemBuilder: (context, index) {
                        final product = state.hotDealProducts[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: SizedBox(
                            width: 170,
                            child: ProductCard(
                              data: product,
                              onTap: () {
                                context.push('/products/${product.id}');
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Popular Section
                if (state.popularProducts.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FigmaSectionHeader(
                          title: '실시간 인기 사료',
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.popularProducts.length,
                      itemBuilder: (context, index) {
                        final product = state.popularProducts[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: SizedBox(
                            width: 170,
                            child: ProductCard(
                              data: product,
                              onTap: () {
                                context.push('/products/${product.id}');
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Category Chips
                if (state.categories.isNotEmpty) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: state.categories.map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FigmaPillChip(
                            label: category.label,
                            selected: state.selectedCategoryId == category.id,
                            onTap: () => ref
                                .read(marketControllerProvider.notifier)
                                .selectCategory(category.id),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Full Product Grid
                if (state.allProducts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.68,
                      ),
                      itemCount: state.allProducts.length,
                      itemBuilder: (context, index) {
                        final product = state.allProducts[index];
                        return ProductCard(
                          data: product,
                          onTap: () {
                            context.push('/products/${product.id}');
                          },
                        );
                      },
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: EmptyStateWidget(
                      title: '상품이 없습니다',
                      description: '상품 데이터를 불러올 수 없습니다',
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
