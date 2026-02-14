import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../ui/widgets/app_top_bar.dart';
import '../../../../../ui/widgets/figma_search_bar.dart';
import '../../../../../ui/widgets/figma_section_header.dart';
import '../../../../../ui/widgets/figma_pill_chip.dart';
import '../../../../../core/widgets/loading.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../controllers/market_controller.dart';
import '../widgets/product_card.dart';
import '../../../watch/presentation/controllers/watch_controller.dart';
import '../../../home/presentation/controllers/home_controller.dart';

/// 실제 API 데이터를 사용하는 Market Screen
class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isTopBarVisible = true;
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(marketControllerProvider.notifier).refresh();
    });
    
    // 스크롤 리스너 추가
    _scrollController.addListener(_onScroll);
    
    // 검색어 변경 리스너 추가
    _searchController.addListener(_onSearchChanged);
  }
  
  void _onSearchChanged() {
    final query = _searchController.text;
    ref.read(marketControllerProvider.notifier).setSearchQuery(query);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final currentOffset = _scrollController.offset;
    
    // 스크롤 방향 감지
    if (currentOffset > _lastScrollOffset && currentOffset > 50) {
      // 아래로 스크롤 (50px 이상)
      if (_isTopBarVisible) {
        setState(() {
          _isTopBarVisible = false;
        });
      }
    } else if (currentOffset < _lastScrollOffset || currentOffset <= 0) {
      // 위로 스크롤 또는 맨 위
      if (!_isTopBarVisible) {
        setState(() {
          _isTopBarVisible = true;
        });
      }
    }
    
    _lastScrollOffset = currentOffset;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketControllerProvider);
    final homeState = ref.watch(homeControllerProvider);
    
    // WatchController 변경 시 MarketController의 찜 상태 업데이트
    ref.listen<WatchState>(watchControllerProvider, (previous, next) {
      if (previous?.trackedProductIds != next.trackedProductIds) {
        ref.read(marketControllerProvider.notifier).updateTrackingStatus();
      }
    });
    
    // 현재 펫 ID 가져오기
    final currentPetId = homeState.petSummary?.petId;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // TopBar
            AnimatedSlide(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              offset: _isTopBarVisible ? Offset.zero : const Offset(0, -1),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isTopBarVisible ? 1.0 : 0.0,
                child: AppTopBar(title: '사료마켓', showBackButton: false),
              ),
            ),
            Expanded(
              child: _buildBody(state, currentPetId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(MarketState state, String? currentPetId) {
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
        // 검색바 입력 중에는 포커스 해제하지 않음
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () => ref.read(marketControllerProvider.notifier).refresh(),
        child: CupertinoScrollbar(
          controller: _scrollController,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar (스크롤 가능한 영역 안으로 이동)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 28, 18, 16), // DESIGN_GUIDE v2.2: 페이지 Wrap Padding
                  child: FigmaSearchBar(
                    placeholder: '사료 브랜드나 제품명을 검색하세요',
                    controller: _searchController,
                  ),
                ),
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
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.hotDealProducts.length,
                      itemBuilder: (context, index) {
                        final product = state.hotDealProducts[index];
                        final isTracked = state.trackedProductIds.contains(product.id);
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: SizedBox(
                            width: 170,
                            child: ProductCard(
                              product: product,
                              isTracked: isTracked,
                              onTap: () {
                                context.push('/products/${product.id}');
                              },
                              onHeartTap: currentPetId != null
                                  ? () => _handleHeartTap(product.id, isTracked, currentPetId)
                                  : null,
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
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.popularProducts.length,
                      itemBuilder: (context, index) {
                        final product = state.popularProducts[index];
                        final isTracked = state.trackedProductIds.contains(product.id);
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: SizedBox(
                            width: 170,
                            child: ProductCard(
                              product: product,
                              isTracked: isTracked,
                              onTap: () {
                                context.push('/products/${product.id}');
                              },
                              onHeartTap: currentPetId != null
                                  ? () => _handleHeartTap(product.id, isTracked, currentPetId)
                                  : null,
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
                        childAspectRatio: 0.65,
                      ),
                      itemCount: state.allProducts.length,
                      itemBuilder: (context, index) {
                        final product = state.allProducts[index];
                        final isTracked = state.trackedProductIds.contains(product.id);
                        return ProductCard(
                          product: product,
                          isTracked: isTracked,
                          onTap: () {
                            context.push('/products/${product.id}');
                          },
                          onHeartTap: currentPetId != null
                              ? () => _handleHeartTap(product.id, isTracked, currentPetId)
                              : null,
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

  /// 하트 클릭 핸들러
  Future<void> _handleHeartTap(String productId, bool isTracked, String petId) async {
    final watchController = ref.read(watchControllerProvider.notifier);
    
    if (isTracked) {
      // 찜 취소
      final success = await watchController.removeTracking(productId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('찜 목록에서 제거되었습니다'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } else {
      // 찜 추가
      final success = await watchController.addTracking(productId, petId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('찜 목록에 추가되었습니다'),
            duration: Duration(seconds: 1),
          ),
        );
      } else if (!success && mounted) {
        final watchState = ref.read(watchControllerProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(watchState.error ?? '찜 추가에 실패했습니다'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
