import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../app/theme/app_radius.dart';
import '../../../../../app/theme/app_shadows.dart';
import '../../../../../core/utils/price_formatter.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/loading.dart';
import '../../../../../ui/widgets/figma_app_bar.dart';
import '../../../../../ui/widgets/app_buttons.dart';
import '../controllers/product_detail_controller.dart';
import '../widgets/price_comparison_card.dart';
import '../widgets/match_analysis_card.dart';
import '../widgets/nutrition_facts_section.dart';
import '../widgets/product_summary_card.dart';
import '../widgets/price_line_chart.dart';
import '../widgets/price_alert_settings_section.dart';
import '../widgets/disclaimer_section.dart';
import '../../../watch/presentation/controllers/watch_controller.dart';
import '../../../home/presentation/controllers/home_controller.dart';

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
  int? _lastHandledRevision;  // 마지막으로 처리한 profileRevision
  
  @override
  void initState() {
    super.initState();
    // 화면 진입 시 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(productDetailControllerProvider(widget.productId).notifier);
      controller.loadProduct(widget.productId);
      
      // ✅ 화면 진입 시 놓친 업데이트 복구
      final homeState = ref.read(homeControllerProvider);
      _maybeRecalculate(homeState);
    });
  }
  
  /// 맞춤 점수 재계산 (revision 기반)
  void _maybeRecalculate(HomeState state) {
    final petId = state.petSummary?.petId;
    if (petId == null) {
      print('[ProductDetailScreen] ⚠️ petId가 null이어서 맞춤 점수 재계산 스킵');
      return;
    }

    final revision = state.profileRevision;

    // 이미 처리한 revision이면 무시
    if (_lastHandledRevision == revision) {
      print('[ProductDetailScreen] ℹ️ 이미 처리한 revision ($revision) - 스킵');
      return;
    }

    _lastHandledRevision = revision;

    print('[ProductDetailScreen] ✅ 맞춤 점수 재계산 시작');
    print('[ProductDetailScreen]   - productId: ${widget.productId}');
    print('[ProductDetailScreen]   - petId: $petId');
    print('[ProductDetailScreen]   - revision: $revision');

    final controller = ref.read(
      productDetailControllerProvider(widget.productId).notifier
    );
    controller.loadMatchScore(widget.productId, petId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productDetailControllerProvider(widget.productId));
    final homeState = ref.watch(homeControllerProvider);
    
    // ✅ 화면 열린 상태에서 업데이트 감지
    ref.listen<HomeState>(
      homeControllerProvider,
      (previousState, currentState) {
        _maybeRecalculate(currentState);
      },
    );
    
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
        backgroundColor: AppColors.surface,
        body: const Center(child: LoadingWidget()),
      );
    }

    // 에러 상태
    if (state.error != null && state.product == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
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
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Column(
            children: [
              FigmaAppBar(
                title: '제품 상세',
                onBack: () => context.pop(),
              ),
              const Expanded(
                child: Center(child: LoadingWidget()),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Hero - 큰 이미지
                      Stack(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 320,
                            child: Container(
                              color: AppColors.surfaceLight,
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
                            top: AppSpacing.lg,
                            right: AppSpacing.lg,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  await ref
                                      .read(productDetailControllerProvider(widget.productId).notifier)
                                      .toggleFavorite();
                                  ref.read(watchControllerProvider.notifier).loadTrackingProducts();
                                },
                                borderRadius: BorderRadius.circular(AppRadius.card),
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(AppRadius.card),
                                    boxShadow: AppShadows.card,
                                  ),
                                  child: Icon(
                                    state.isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 24,
                                    color: state.isFavorite
                                        ? AppColors.drop
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.xl),
                      // 상단 제품 요약
                      ProductSummaryCard(
                        product: product,
                        currentPrice: state.currentPrice,
                        averagePrice: state.averagePrice,
                        isFavorite: state.isFavorite,
                        onFavoriteTap: () async {
                          await ref
                              .read(productDetailControllerProvider(widget.productId).notifier)
                              .toggleFavorite();
                          ref.read(watchControllerProvider.notifier).loadTrackingProducts();
                        },
                      ),
                      Divider(color: AppColors.border.withOpacity(0.3), thickness: 4, height: 1),
                      // 가격 비교
                      PriceComparisonCard(
                        currentPrice: state.currentPrice,
                        averagePrice: state.averagePrice,
                      ),
                      Divider(color: AppColors.border.withOpacity(0.3), thickness: 4, height: 1),
                      // 가격 추이 섹션
                      _buildPriceGraphSection(state),
                      Divider(color: AppColors.border.withOpacity(0.3), thickness: 4, height: 1),
                      // 가격 알림 설정 섹션
                      PriceAlertSettingsSection(
                        onLowestPriceAlertChanged: (value) {
                          // TODO: 최저가 알림 설정 처리
                        },
                        onCustomPriceAlertChanged: (value) {
                          // TODO: 원하는 가격 알림 설정 처리
                        },
                      ),
                      Divider(color: AppColors.border.withOpacity(0.3), thickness: 4, height: 1),
                      // 맞춤 분석 섹션
                      if (state.matchScore != null)
                        MatchAnalysisCard(
                          matchScore: state.matchScore!,
                          petName: homeState.petSummary?.name,
                        )
                      else if (state.isLoadingMatchScore)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          width: double.infinity,
                          color: AppColors.surface,
                          child: Center(
                            child: Lottie.asset(
                              'assets/animations/loading_dots.json',
                              width: 500,
                              height: 500,
                              fit: BoxFit.contain,
                              repeat: true,
                              animate: true,
                            ),
                          ),
                        ),
                      if (state.matchScore != null)
                        Divider(color: AppColors.border.withOpacity(0.3), thickness: 4, height: 1),
                      // 영양 성분 섹션
                      if (state.ingredientAnalysis != null &&
                          state.ingredientAnalysis!.nutritionFacts.isNotEmpty) ...[
                        NutritionFactsSection(
                          nutritionFacts: state.ingredientAnalysis!.nutritionFacts,
                        ),
                        Divider(color: AppColors.border.withOpacity(0.3), thickness: 4, height: 1),
                      ],
                      // 면책 조항 및 안내 문구
                      DisclaimerSection(
                        petName: homeState.petSummary?.name,
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
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: AppColors.border,
              width: 1,
            ),
          ),
          boxShadow: AppShadows.bottomSheet,
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
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.button),
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
                          ? AppColors.drop
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppPrimaryButton(
                  text: '구매하러가기',
                  onPressed: () async {
                    final purchaseUrl = state.purchaseUrl;
                    if (purchaseUrl != null && purchaseUrl.isNotEmpty) {
                      await _launchPurchaseUrl(purchaseUrl);
                    } else {
                      // TODO: 구매 링크가 없을 때 처리
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('구매 링크를 불러올 수 없습니다'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  height: 56,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 가격 추이 섹션
  Widget _buildPriceGraphSection(ProductDetailState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      width: double.infinity,
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '가격 추이',
            style: AppTypography.body.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            '최근 가격 흐름을 한눈에 확인하세요',
            style: AppTypography.small.copyWith(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          // 가격 라인 차트
          PriceLineChart(
            prices: _getPriceHistory(state), // 최근 7일 가격 데이터
            minPrice: state.minPrice,
            maxPrice: state.maxPrice,
          ),
          SizedBox(height: AppSpacing.lg),
          // 가격 정보 카드
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 역대 최저가
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '역대 최저가',
                      style: AppTypography.small.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      state.minPrice != null
                          ? PriceFormatter.formatWithCurrency(state.minPrice!)
                          : '정보 없음',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // 평균가
              if (state.averagePrice != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '평균가',
                        style: AppTypography.small.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        PriceFormatter.formatWithCurrency(state.averagePrice!),
                        style: AppTypography.body.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              // 역대 최고가
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '역대 최고가',
                      style: AppTypography.small.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      state.maxPrice != null
                          ? PriceFormatter.formatWithCurrency(state.maxPrice!)
                          : '정보 없음',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 가격 히스토리 데이터 생성 (임시 - 실제 API 데이터로 대체 필요)
  List<int> _getPriceHistory(ProductDetailState state) {
    // TODO: 실제 가격 히스토리 API 데이터로 대체
    // 현재는 임시 데이터 사용
    if (state.currentPrice != null && state.averagePrice != null) {
      final current = state.currentPrice!;
      final avg = state.averagePrice!;
      // 최근 7일 가격 데이터 시뮬레이션
      return [
        (avg * 1.1).round(), // 7일 전
        (avg * 1.05).round(), // 6일 전
        (avg * 1.02).round(), // 5일 전
        (avg * 0.98).round(), // 4일 전
        (avg * 0.95).round(), // 3일 전
        (avg * 0.92).round(), // 2일 전
        current, // 오늘
      ];
    }
    // 기본 데이터
    return [65000, 58000, 62000, 55000, 60000, 52000, 48000];
  }

  /// 외부 앱으로 구매 링크 열기
  Future<void> _launchPurchaseUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('구매 링크를 열 수 없습니다'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('구매 링크 열기 실패: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
