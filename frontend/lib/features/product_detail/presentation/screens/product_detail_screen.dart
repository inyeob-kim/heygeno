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
import '../widgets/ingredient_analysis_section.dart';
import '../widgets/product_summary_card.dart';
import '../widgets/price_line_chart.dart';
import '../widgets/price_alert_settings_section.dart';
import '../widgets/disclaimer_section.dart';
import '../../../watch/presentation/controllers/watch_controller.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../providers/match_score_provider.dart';
import '../../../../core/providers/active_pet_context_provider.dart';

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
  bool _isClaimsExpanded = false; // 기능성 클레임 접기/펼치기 상태
  
  @override
  void initState() {
    super.initState();
    // 화면 진입 시 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // HomeController가 초기화되지 않았으면 초기화
      final homeState = ref.read(homeControllerProvider);
      if (homeState.isLoading) {
        print('[ProductDetailScreen] 🔄 HomeController 초기화 시작');
        await ref.read(homeControllerProvider.notifier).initialize();
        print('[ProductDetailScreen] ✅ HomeController 초기화 완료');
      }
      
      final controller = ref.read(productDetailControllerProvider(widget.productId).notifier);
      await controller.loadProduct(widget.productId);
      
      // ✅ matchScore는 matchScoreProvider가 activePetContext 변경을 자동으로 감지하여 처리
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productDetailControllerProvider(widget.productId));
    final homeState = ref.watch(homeControllerProvider); // petName 표시용
    final activePetContext = ref.watch(activePetContextProvider); // matchScore용
    
    // ✅ activePetContext 기반 matchScore provider 사용
    // activePetContext가 변경되면 자동으로 무효화·재계산됨
    AsyncValue<MatchScoreResult> matchScoreAsync;
    if (activePetContext.petId == null) {
      // 펫이 없는 경우 에러 상태
      print('[ProductDetailScreen] ⚠️ petId가 null - 에러 상태 반환');
      matchScoreAsync = const AsyncValue.data(MatchScoreResult.error('no_pet'));
    } else {
      final key = (
        productId: widget.productId,
        petId: activePetContext.petId!,
        revision: activePetContext.profileRevision,
      );
      print('[ProductDetailScreen] 🔑 MatchScoreQueryKey 생성: ${key.toDebugString()}');
      matchScoreAsync = ref.watch(matchScoreProvider(key));
    }
    
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
                      // 맞춤 분석 섹션 (항상 표시) - 새로운 provider 사용
                      matchScoreAsync.when(
                        data: (result) {
                          if (result.isSuccess && result.matchScore != null) {
                            return MatchAnalysisCard(
                              matchScore: result.matchScore!,
                              petName: activePetContext.petSummary?.name ?? homeState.petSummary?.name,
                            );
                          } else {
                            // 에러 상태
                            final petName = activePetContext.petSummary?.name ?? homeState.petSummary?.name;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                              width: double.infinity,
                              color: AppColors.surface,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    petName != null
                                        ? '$petName 맞춤 점수'
                                        : '맞춤 점수',
                                    style: AppTypography.body.copyWith(
                                      color: AppColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    activePetContext.petId == null
                                        ? '펫 정보를 등록하면 맞춤 점수를 확인할 수 있습니다.'
                                        : result.errorType == 'no_ingredient_info'
                                            ? '이 상품의 성분 분석 정보가 아직 준비되지 않아 맞춤 점수를 제공할 수 없습니다.'
                                            : '맞춤 점수를 계산할 수 없습니다.',
                                    style: AppTypography.body.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        loading: () => Container(
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
                        error: (error, stackTrace) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          width: double.infinity,
                          color: AppColors.surface,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (activePetContext.petSummary?.name ?? homeState.petSummary?.name) != null
                                    ? '${activePetContext.petSummary?.name ?? homeState.petSummary?.name} 맞춤 점수'
                                    : '맞춤 점수',
                                style: AppTypography.body.copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                '맞춤 점수를 불러오는 중 오류가 발생했습니다.',
                                style: AppTypography.body.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(color: AppColors.border.withOpacity(0.3), thickness: 4, height: 1),
                      // 성분 분석 섹션 (주요 원료, 알레르기 성분) - 항상 표시
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        width: double.infinity,
                        color: AppColors.surface,
                        child: state.ingredientAnalysis != null &&
                                (state.ingredientAnalysis!.mainIngredients.isNotEmpty ||
                                 state.ingredientAnalysis!.allergens?.isNotEmpty == true ||
                                 state.ingredientAnalysis!.description != null)
                            ? IngredientAnalysisSection(
                                data: state.ingredientAnalysis,
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '성분 분석',
                                    style: AppTypography.body.copyWith(
                                      color: AppColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    '성분 정보가 없습니다.',
                                    style: AppTypography.body.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      Divider(color: AppColors.border.withOpacity(0.3), thickness: 4, height: 1),
                      // 기능성 클레임 섹션
                      if (state.claims.isNotEmpty) ...[
                        _buildClaimsSection(state.claims),
                        Divider(color: AppColors.border.withOpacity(0.3), thickness: 4, height: 1),
                      ],
                      // 면책 조항 및 안내 문구
                      DisclaimerSection(
                        petName: activePetContext.petSummary?.name ?? homeState.petSummary?.name,
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

  // 가격 히스토리 데이터 가져오기 (실제 API 데이터 사용)
  List<int> _getPriceHistory(ProductDetailState state) {
    if (state.priceHistory.isNotEmpty) {
      return state.priceHistory.map((h) => h.price).toList();
    }
    // 가격 히스토리가 없으면 현재 가격만 반환
    if (state.currentPrice != null) {
      return [state.currentPrice!];
    }
    return [];
  }

  // 기능성 클레임 섹션
  Widget _buildClaimsSection(List<ClaimItem> claims) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      width: double.infinity,
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 (클릭 가능)
          GestureDetector(
            onTap: () {
              setState(() {
                _isClaimsExpanded = !_isClaimsExpanded;
              });
            },
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '기능성 클레임',
                        style: AppTypography.body.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (!_isClaimsExpanded) ...[
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          '이 제품이 지원하는 기능성 정보입니다',
                          style: AppTypography.small.copyWith(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                AnimatedRotation(
                  turns: _isClaimsExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          // 접기/펼치기 콘텐츠
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: AppSpacing.xs),
                Text(
                  '이 제품이 지원하는 기능성 정보입니다',
                  style: AppTypography.small.copyWith(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                ...claims.map((claim) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(
                        color: AppColors.border.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                claim.claimDisplayName ?? claim.claimCode,
                                style: AppTypography.body.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Text(
                                '증거 수준 ${claim.evidenceLevel}%',
                                style: AppTypography.small.copyWith(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (claim.note != null && claim.note!.isNotEmpty) ...[
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            claim.note!,
                            style: AppTypography.small.copyWith(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )).toList(),
              ],
            ),
            crossFadeState: _isClaimsExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
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
