import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../ui/widgets/app_top_bar.dart';
import '../../../../../ui/widgets/figma_pill_chip.dart';
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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(watchControllerProvider.notifier).loadTrackingProducts();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(watchControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(title: '찜한 사료', showBackButton: false),
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
                color: AppColors.primary, // Emerald Green (DESIGN_GUIDE v2.3)
                borderRadius: BorderRadius.circular(AppRadius.md), // 12px
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

    // 빈 상태 - "+" 카드 표시
    if (state.trackingProducts.isEmpty) {
      return CupertinoScrollbar(
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              // "+" 카드 그리드
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.lg,
                  mainAxisSpacing: AppSpacing.lg,
                  childAspectRatio: 0.65,
                ),
                itemCount: 1, // "+" 카드 하나만 표시
                itemBuilder: (context, index) {
                  return _buildAddProductCard();
        },
              ),
              const SizedBox(height: AppSpacing.xl * 2),
            ],
          ),
        ),
      );
    }

    final sortedProducts = state.sortedProducts;
    
    // sortedProducts가 비어있는 경우 추가 체크 - "+" 카드 표시
    if (sortedProducts.isEmpty) {
      return CupertinoScrollbar(
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              // "+" 카드 그리드
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.lg,
                  mainAxisSpacing: AppSpacing.lg,
                  childAspectRatio: 0.65,
                ),
                itemCount: 1, // "+" 카드 하나만 표시
                itemBuilder: (context, index) {
                  return _buildAddProductCard();
        },
              ),
              const SizedBox(height: AppSpacing.xl * 2),
            ],
          ),
        ),
      );
    }

    return CupertinoScrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),
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
                childAspectRatio: 0.65,
              ),
              itemCount: sortedProducts.length + 1, // 상품 + 추가하기 카드
              itemBuilder: (context, index) {
                // 마지막 항목은 추가하기 카드
                if (index == sortedProducts.length) {
                  return _buildAddProductCard();
                }
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

  /// "+" 카드 위젯 (사료 추가용)
  Widget _buildAddProductCard() {
    return InkWell(
      onTap: () {
        context.go('/market');
      },
      child: ClipRect(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 이미지 영역 (TrackingProductCard와 동일한 구조)
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: const Color(0xFFF7F8FA),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add,
                        size: 40,
                        color: AppColors.textSecondary.withOpacity(0.6),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '사료 추가하기',
                        style: AppTypography.body2.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          color: AppColors.textSecondary.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 텍스트 영역 (TrackingProductCard와 동일한 구조)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 브랜드명 위치 (빈 공간) - 11px 폰트
                  const SizedBox(height: 11),
                  const SizedBox(height: 1),
                  // 제품명 위치 (빈 공간) - 13px * 1.15 * 2줄 = 약 30px
                  SizedBox(
                    height: 13 * 1.15 * 2,
                  ),
                  const SizedBox(height: 2),
                  // 가격 위치 (빈 공간) - 15px 폰트
                  const SizedBox(height: 15),
                  // 알림 상태 위치 (빈 공간) - 최대 높이를 위해 공간 확보
                  const SizedBox(height: 13),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
