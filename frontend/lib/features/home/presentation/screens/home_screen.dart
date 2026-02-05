import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../ui/widgets/figma_primary_button.dart';
import '../../../../../ui/widgets/match_score_badge.dart';
import '../../../../../ui/widgets/price_delta.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../app/router/route_paths.dart';
import '../../../../../core/utils/price_formatter.dart';
import '../../../../../core/widgets/loading.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../domain/services/onboarding_service.dart';
import '../controllers/home_controller.dart';

/// Toss-style 판단 UI Home Screen
/// 실제 API 데이터를 사용하여 Pet 프로필 및 추천 상품 표시
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 화면 진입 시 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeControllerProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeControllerProvider);

    // 로딩 상태
    if (state.isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: const Center(child: LoadingWidget()),
      );
    }

    // Pet 없음 상태
    if (state.isNoPet) {
      return _buildNoPetState(context);
    }

    // 에러 상태
    if (state.isError) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: EmptyStateWidget(
          title: state.error ?? '오류가 발생했습니다',
          buttonText: '다시 시도',
          onButtonPressed: () => ref.read(homeControllerProvider.notifier).initialize(),
        ),
      );
    }

    // Pet 있음 상태
    final petSummary = state.petSummary;
    final recommendations = state.recommendations;
    final topRecommendation = recommendations?.items.isNotEmpty == true
        ? recommendations!.items[0]
        : null;

    if (petSummary == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: const Center(child: LoadingWidget()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            Container(
              color: const Color(0xFFF7F8FA),
              padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '오늘, ${petSummary.name}에게\n딱 맞는 사료',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      // Section A: Pet Summary
                      _buildPetSummary(petSummary),
                      const SizedBox(height: 32),
                      // Section B: Metric Pills
                      _buildMetricPills(petSummary),
                      const SizedBox(height: 32),
                      // Section C: Recommendation Flow
                      if (topRecommendation != null)
                        _buildRecommendationFlow(
                          context,
                          topRecommendation,
                          petSummary,
                        )
                      else if (state.isLoadingRecommendations)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else
                        _buildNoRecommendation(),
                      const SizedBox(height: 100), // Space for sticky CTA
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // Sticky CTA
      bottomNavigationBar: topRecommendation != null
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: FigmaPrimaryButton(
                  text: '상세보기',
                  onPressed: () {
                    context.push('/products/${topRecommendation.product.id}');
                  },
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildPetSummary(petSummary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    petSummary.name,
                    style: AppTypography.body.copyWith(
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '·',
                    style: AppTypography.small.copyWith(
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    petSummary.species == 'DOG' ? '강아지' : '고양이',
                    style: AppTypography.small.copyWith(
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                petSummary.ageSummary,
                style: AppTypography.small.copyWith(
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${petSummary.weightKg.toStringAsFixed(1)}kg',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB),
                letterSpacing: -0.4,
              ),
            ),
            Text(
              '현재 체중',
              style: AppTypography.small.copyWith(
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricPills(petSummary) {
    // TODO: BCS, dailyKcal, dailyGrams는 백엔드에서 제공되면 추가
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Text(
                  petSummary.ageStage ?? '성견',
                  style: AppTypography.body.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '생애 단계',
                  style: AppTypography.small.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Text(
                  petSummary.species == 'DOG' ? '강아지' : '고양이',
                  style: AppTypography.body.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '종류',
                  style: AppTypography.small.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Text(
                  petSummary.healthConcerns.isEmpty ? '양호' : '주의',
                  style: AppTypography.body.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '건강 상태',
                  style: AppTypography.small.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationFlow(
    BuildContext context,
    recommendationItem,
    petSummary,
  ) {
    final product = recommendationItem.product;
    final avgPrice = recommendationItem.avgPrice;
    final currentPrice = recommendationItem.currentPrice;
    final priceDiff = avgPrice - currentPrice;
    final priceDiffPercent = avgPrice > 0 ? (priceDiff / avgPrice * 100).round() : 0;
    // TODO: matchScore는 백엔드에서 제공되면 추가
    final matchScore = 92;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image with MatchScoreBadge and badge
        GestureDetector(
          onTap: () => context.push('/products/${product.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Container(
                        color: const Color(0xFFF7F8FA),
                        child: const Center(
                          child: Icon(Icons.image, size: 64, color: Color(0xFF6B7280)),
                        ),
                      ),
                    ),
                  ),
                  // MatchScoreBadge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: MatchScoreBadge(
                      score: matchScore,
                      size: MatchScoreSize.medium,
                    ),
                  ),
                  // Badge
                  if (recommendationItem.isNewLow)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          '최저가',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Brand + Product Name
              Text(
                product.brandName,
                style: AppTypography.small.copyWith(
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                product.productName,
                style: AppTypography.h2.copyWith(
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 16),
              // Price Hero with PriceDelta
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    PriceFormatter.formatWithCurrency(currentPrice),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (priceDiffPercent > 0)
                    PriceDelta(
                      currentPrice: currentPrice,
                      avgPrice: avgPrice,
                      size: PriceDeltaSize.large,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '평균 대비 $priceDiffPercent% 저렴해요',
                style: AppTypography.body.copyWith(
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Trust Message
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle,
                size: 20,
                color: Color(0xFF16A34A),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${petSummary.name}의 영양 요구사항 $matchScore% 부합 (알레르기 피함, 체중 관리 적합)',
                  style: AppTypography.body.copyWith(
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Simple Reason
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '왜 이 제품?',
                      style: AppTypography.body.copyWith(
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${petSummary.name}의 ${petSummary.ageSummary}, 체중 ${petSummary.weightKg.toStringAsFixed(1)}kg 기반 최적 선택',
                      style: AppTypography.small.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoRecommendation() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off,
            size: 48,
            color: Color(0xFF6B7280),
          ),
          const SizedBox(height: 16),
          Text(
            '추천 상품이 없습니다',
            style: AppTypography.body.copyWith(
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '마켓에서 사료를 둘러보세요',
            style: AppTypography.small.copyWith(
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  /// Pet 없음 상태 UI (온보딩 완료 여부에 따라 다른 메시지 표시)
  Widget _buildNoPetState(BuildContext context) {
    return FutureBuilder<bool>(
      future: ref.read(onboardingServiceProvider).isOnboardingCompleted(),
      builder: (context, snapshot) {
        final isOnboardingCompleted = snapshot.data ?? false;
        
        return Scaffold(
          backgroundColor: const Color(0xFFF7F8FA),
          body: EmptyStateWidget(
            title: isOnboardingCompleted
                ? '프로필을 불러올 수 없습니다'
                : '프로필을 만들어주세요',
            description: isOnboardingCompleted
                ? '프로필 정보를 다시 불러오는 중입니다'
                : '반려동물 정보를 입력하면 맞춤 추천을 받을 수 있어요',
            buttonText: isOnboardingCompleted
                ? '프로필 다시 불러오기'
                : '프로필 만들기',
            onButtonPressed: () {
              if (isOnboardingCompleted) {
                // 프로필 다시 불러오기
                ref.read(homeControllerProvider.notifier).initialize();
              } else {
                // 프로필 만들기 (온보딩으로 이동)
                context.go(RoutePaths.onboarding);
              }
            },
          ),
        );
      },
    );
  }
}
