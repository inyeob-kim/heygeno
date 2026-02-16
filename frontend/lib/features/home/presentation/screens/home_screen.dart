import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../ui/widgets/price_delta.dart';
import '../../../../../ui/widgets/card_container.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/app_radius.dart';
import '../../../../../app/router/route_paths.dart';
import '../../../../../core/utils/price_formatter.dart';
import '../../../../../core/widgets/loading.dart';
import 'package:lottie/lottie.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../domain/services/onboarding_service.dart';
import '../../../../../features/onboarding/data/repositories/onboarding_repository.dart';
import '../controllers/home_controller.dart';
import '../../../../../ui/widgets/app_top_bar.dart';
import '../../../../../data/repositories/product_repository.dart';
import '../../../../../core/constants/pet_constants.dart';
import '../widgets/icon_text_row.dart';
import '../widgets/status_signal_card.dart';
import '../../../../../data/models/pet_summary_extensions.dart';
import '../../../../../data/models/recommendation_dto.dart';
import '../../../../../ui/widgets/pet_info_row.dart';
import '../../../../../ui/widgets/health_concern_chips.dart';
import '../../../../../ui/widgets/allergy_list.dart';

/// Toss-style 판단 UI Home Screen
/// 실제 API 데이터를 사용하여 Pet 프로필 및 추천 상품 표시
/// 
/// ⚠️ 이 화면은 AppSpacing 규칙을 따릅니다.
/// 모든 간격은 AppSpacing 클래스를 통해서만 사용해야 합니다.
/// 숫자 리터럴 SizedBox(height: n) 사용 금지.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolledToBottom = false;
  bool _isRecommendationExpanded = false; // 추천 결과 펼침 여부
  bool _hasAutoExpanded = false; // 자동 펼침 여부 (한 번만)
  DateTime? _lastRefreshTime; // 마지막 새로고침 시간

  @override
  void initState() {
    super.initState();
    
    // 화면 진입 시 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(homeControllerProvider.notifier).initialize();
      }
    });
    
    // 스크롤 리스너 추가
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 다른 화면에서 돌아올 때 펫 프로필 새로고침 (너무 자주 호출되지 않도록 제한)
    final now = DateTime.now();
    if (_lastRefreshTime == null || 
        now.difference(_lastRefreshTime!).inSeconds > 2) {
      _lastRefreshTime = now;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final state = ref.read(homeControllerProvider);
          // 펫이 있는 상태에서만 새로고침 (초기 로딩 중이 아닐 때)
          if (state.hasPet) {
            ref.read(homeControllerProvider.notifier).refreshPetSummary();
          }
        }
      });
    }
  }


  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    
    try {
      final isAtBottom = _scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 50;
      
      if (isAtBottom != _isScrolledToBottom) {
        setState(() => _isScrolledToBottom = isAtBottom);
      }
    } catch (_) {
      // ScrollController가 dispose된 경우 무시
    }
  }

  /// 추천 자동 펼치기 처리
  void _handleAutoExpandRecommendation(HomeState state) {
    if (_hasAutoExpanded || !state.hasPet) return;
    
    final topRecommendation = state.recommendations?.items.firstOrNull;
    if (topRecommendation == null || 
        state.isLoadingRecommendations || 
        _isRecommendationExpanded) return;
    
    _hasAutoExpanded = true;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      
      setState(() => _isRecommendationExpanded = true);
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        try {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent * 0.3,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } catch (_) {}
      });
    });
  }

  // UPDATED: Dynamic recommendation card with freshness logic - 동적 추천 토글
  void _toggleRecommendation({bool forceRefresh = false}) {
    print('[HomeScreen] 🔘 "딱 맞는 사료 보기" 버튼 클릭: forceRefresh=$forceRefresh');
    final state = ref.read(homeControllerProvider);
    final recommendations = state.recommendations;
    final topRecommendation = recommendations?.items.isNotEmpty == true
        ? recommendations!.items[0]
        : null;
    
    print('[HomeScreen] 현재 상태: recommendations=${recommendations?.items.length ?? 0}개, isLoading=${state.isLoadingRecommendations}, expanded=$_isRecommendationExpanded, hasRecent=${state.hasRecentRecommendation}');
    
    // UPDATED: Dynamic recommendation card with freshness logic - 최근 추천이 있으면 바로 표시, 없으면 로드
    if (topRecommendation == null && !state.isLoadingRecommendations) {
      final petSummary = state.petSummary;
      if (petSummary != null) {
        print('[HomeScreen] ✅ 추천 로드 시작: petId=${petSummary.petId}, petName=${petSummary.name}');
        // 추천 로드 시작 (force 파라미터 전달)
        ref.read(homeControllerProvider.notifier).loadRecommendations(force: forceRefresh);
        // 로딩 중이면 펼치지 않음
        return;
      } else {
        print('[HomeScreen] ⚠️ petSummary가 null입니다. 추천을 로드할 수 없습니다.');
      }
    }
    
    // 최근 추천이 있고 펼쳐지지 않았으면 바로 펼치기 (로딩 없이)
    if (state.hasRecentRecommendation && topRecommendation != null && !_isRecommendationExpanded) {
      print('[HomeScreen] 💾 최근 추천이 있어서 바로 표시 (API 호출 없음)');
      setState(() {
        _isRecommendationExpanded = true;
      });
      // 펼칠 때 스크롤 애니메이션
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        try {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent * 0.3,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } catch (e) {
          print('[HomeScreen] 스크롤 애니메이션 실패: $e');
        }
      });
      return;
    }
    
    // 추천이 있거나 이미 펼쳐진 상태면 토글
    if (topRecommendation != null || _isRecommendationExpanded) {
      print('[HomeScreen] 🔄 추천 결과 토글: ${_isRecommendationExpanded ? "접기" : "펼치기"}');
      setState(() {
        _isRecommendationExpanded = !_isRecommendationExpanded;
      });
      
      // 펼칠 때 스크롤 위치 조정
      if (_isRecommendationExpanded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollController.hasClients) {
            try {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent * 0.3,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            } catch (e) {
              // ScrollController가 dispose된 경우 무시
            }
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeControllerProvider);
    
    // ref.listen은 부수 효과(네비게이션, 다이얼로그 등)만 처리
    // setState는 ref.watch로만 처리 (위젯 트리 재구성 중 setState 호출 방지)
    ref.listen<HomeState>(homeControllerProvider, (previous, next) {
      // 펫이 변경된 경우 플래그만 리셋 (setState 호출하지 않음)
      if (previous?.petSummary?.petId != next.petSummary?.petId) {
        _hasAutoExpanded = false;
        _isRecommendationExpanded = false;
      }
    });

    // 위젯 트리 구조 통일: 모든 상태에서 동일한 Scaffold 구조 사용
    // _scrollController를 항상 사용하여 unmount/mount 시 안전성 확보
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 고정 탭 (알림 아이콘 포함)
            AppTopBar(
              title: state.userNickname != null 
                  ? '안녕하세요, ${state.userNickname}님!'
                  : '헤이제노',
              showBackButton: false,
              actions: [
                // 전체 캐시 제거 버튼
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.textPrimary,
                  tooltip: '전체 캐시 제거',
                  onPressed: () async {
                    print('[HomeScreen] 🗑️ 전체 캐시 제거 버튼 클릭');
                    
                    // 확인 다이얼로그 표시
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('전체 캐시 제거'),
                        content: const Text('모든 추천 캐시를 제거하시겠습니까?\n다음 추천 요청 시 새로 계산됩니다.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.drop,
                            ),
                            child: const Text('제거'),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirmed != true) return;
                    
                    try {
                      final repository = ref.read(productRepositoryProvider);
                      final result = await repository.clearAllRecommendationCache();
                      
                      // 홈 화면 상태에서 추천 데이터 제거 (캐시가 없으므로)
                      ref.read(homeControllerProvider.notifier).clearRecommendations();
                      
                      if (mounted) {
                        final deletedRuns = result['deleted_runs'] as int? ?? 0;
                        final redisKeysDeleted = result['redis_keys_deleted'] as int? ?? 0;
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '전체 캐시가 제거되었습니다.\n(PostgreSQL: $deletedRuns개, Redis: $redisKeysDeleted개)',
                            ),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                      
                      print('[HomeScreen] ✅ 전체 캐시 제거 완료: $result');
                    } catch (e) {
                      print('[HomeScreen] ❌ 전체 캐시 제거 실패: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('캐시 제거 실패: ${e.toString()}'),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
            // 스크롤 가능한 콘텐츠 (항상 동일한 구조)
            Expanded(
              child: CupertinoScrollbar(
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(), // iOS 스타일 바운스
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      MediaQuery.of(context).size.width >= 640 ? 24 : 16, // 반응형: sm:px-6 (24px), 기본: px-4 (16px)
                      28,
                      MediaQuery.of(context).size.width >= 640 ? 24 : 16,
                      80,
                    ),
                    child: _buildBodyContent(context, state),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 상태에 따른 본문 콘텐츠 빌드
  Widget _buildBodyContent(BuildContext context, HomeState state) {
    // 로딩 상태
    if (state.isLoading) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: const Center(child: LoadingWidget()),
      );
    }

    // Pet 없음 상태
    if (state.isNoPet) {
      return _buildNoPetStateContent(context);
    }

    // 에러 상태
    if (state.isError) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: EmptyStateWidget(
            title: state.error ?? '오류가 발생했습니다',
            buttonText: '다시 시도',
            onButtonPressed: () => ref.read(homeControllerProvider.notifier).initialize(),
          ),
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
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: const Center(child: LoadingWidget()),
      );
    }

    // 정상 상태: 펫 정보와 추천 표시
    // 추천 자동 펼치기 처리 (build 메서드 내에서 안전하게 호출)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleAutoExpandRecommendation(state);
    });
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        // 1️⃣ 펫 선택 + 상태 요약 (카드) - 이미 애니메이션 포함
        _buildPetSummaryHeader(context, petSummary, state),
        // 홈 콘텐츠 - 애니메이션 포함
        _buildHomeContent(context, petSummary, state, topRecommendation),
      ],
    );
  }
  
  /// Pet 없음 상태 콘텐츠 (위젯 트리 구조 통일을 위해 별도 메서드로 분리)
  Widget _buildNoPetStateContent(BuildContext context) {
    return FutureBuilder<bool>(
      future: ref.read(onboardingServiceProvider).isOnboardingCompleted(),
      builder: (context, snapshot) {
        final isOnboardingCompleted = snapshot.data ?? false;
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 100),
            // 아이콘
            Icon(
              Icons.favorite_border,
              size: 64,
              color: AppColors.iconMuted,
            ),
            const SizedBox(height: AppSpacing.lg),
            // 제목
            Text(
              isOnboardingCompleted
                  ? '프로필을 불러올 수 없습니다'
                  : '프로필을 만들어주세요',
              style: AppTypography.titleMedium,
              textAlign: TextAlign.center,
            ),
            // 설명
            const SizedBox(height: AppSpacing.sm),
            Text(
              isOnboardingCompleted
                  ? '프로필 정보를 다시 불러오는 중입니다'
                  : '반려동물 정보를 입력하면 맞춤 추천을 받을 수 있어요',
              style: AppTypography.body2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            // 프로필 다시 불러오기 버튼
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  if (isOnboardingCompleted) {
                    // 프로필 다시 불러오기
                    ref.read(homeControllerProvider.notifier).initialize();
                  } else {
                    // 프로필 만들기 (온보딩으로 이동)
                    context.push(RoutePaths.petProfile);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, // Blue (#2563EB) - HeyGeno Landing
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button), // 12px (rounded-xl)
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ).copyWith(
                  elevation: MaterialStateProperty.resolveWith<double>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.hovered)) {
                        return 8; // shadow-lg hover:shadow-xl 효과
                      }
                      return 4; // shadow-lg 기본
                    },
                  ),
                ),
                child: Text(
                  isOnboardingCompleted ? '다시 불러오기' : '프로필 만들기',
                  style: AppTypography.button,
                ),
              ),
            ),
          ],
        );
      },
    );
  }




  /// 추천 사료 요약 블록
  Widget _buildProductSummary(
    BuildContext context,
    product,
    int currentPrice,
    int avgPrice,
    int priceDiffPercent,
    recommendationItem,
  ) {
    return CardContainer(
      isHomeStyle: true,
      onTap: () => context.push('/products/${product.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg), // 16px (rounded-2xl)
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Container(
                    color: const Color(0xFFF7F8FA),
                    child: const Center(
                      child: Icon(Icons.image_outlined, size: 64, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md), // 섹션 그룹 간격
          // 브랜드 + 제품명
          Text(
            product.brandName,
            style: AppTypography.small.copyWith(
              color: AppColors.textSecondary, // #475569 (HeyGeno Landing)
            ),
          ),
          const SizedBox(height: AppSpacing.sm), // 요소 간
          Text(
            product.productName,
            style: AppTypography.h2.copyWith(
              color: AppColors.textPrimary, // #0F172A (HeyGeno Landing)
            ),
          ),
          const SizedBox(height: AppSpacing.md), // 섹션 그룹 간격
          // 가격 Row: 가격 + 최저가 Chip + 할인 Chip
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                PriceFormatter.formatWithCurrency(currentPrice),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: AppSpacing.sm), // 텍스트/아이콘 간격
              // 최저가 Chip
              if (recommendationItem.isNewLow)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
                  decoration: BoxDecoration(
                    color: AppColors.divider, // 중성 회색 배경
                    borderRadius: BorderRadius.circular(AppRadius.pill), // rounded-full
                  ),
                  child: const Text(
                    '최저가',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary, // 중성 회색 텍스트
                    ),
                  ),
                ),
              if (recommendationItem.isNewLow && priceDiffPercent > 0)
                const SizedBox(width: AppSpacing.sm), // 텍스트/아이콘 간격
              // 할인 Chip
              if (priceDiffPercent > 0)
                PriceDelta(
                  currentPrice: currentPrice,
                  avgPrice: avgPrice,
                  size: PriceDeltaSize.medium,
                ),
            ],
          ),
          // 평균 대비 텍스트 (가격 Row 바로 아래)
          const SizedBox(height: AppSpacing.sm), // 텍스트/아이콘 간격
          Text(
            '최근 평균 대비 $priceDiffPercent% 저렴해요',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// "왜 이 제품?" 설명 섹션
  Widget _buildWhyThisProduct(petSummary, recommendationItem) {
    // LLM 생성 설명 우선 사용, 없으면 기술적 이유 표시
    final explanation = recommendationItem.explanation;
    final matchReasons = recommendationItem.matchReasons ?? [];
    
    return CardContainer(
      isHomeStyle: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '왜 이 제품일까요?',
            style: AppTypography.body.copyWith(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md), // 섹션 그룹 간격
            // LLM 생성 설명이 있으면 표시
            if (explanation != null && explanation.isNotEmpty) ...[
              Text(
                explanation,
                style: AppTypography.body.copyWith(
                  color: const Color(0xFF111827),
                  height: 1.5,
                ),
              ),
            ] else if (matchReasons.isNotEmpty) ...[
              // 기술적 이유를 애니메이션과 함께 bullet point로 표시
              ...matchReasons.asMap().entries.map((entry) {
                final index = entry.key as int;
                final reason = entry.value;
                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  curve: Curves.easeOut,
                  builder: (context, opacity, child) {
                    return Opacity(
                      opacity: opacity,
                      child: Transform.translate(
                        offset: Offset(0, 10 * (1 - opacity)),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _buildAnimatedBulletPoint(reason),
                        ),
                      ),
                    );
                  },
                );
              }),
            ] else ...[
              // Fallback 설명
              _buildAnimatedBulletPoint('${petSummary.weightKg.toStringAsFixed(1)}kg 체중에 적합'),
              const SizedBox(height: AppSpacing.sm),
              _buildAnimatedBulletPoint('${petSummary.ageStage ?? '성견'} 단계에 맞는 사료'),
              if (petSummary.healthConcerns.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _buildAnimatedBulletPoint('건강 고민을 고려한 사료'),
              ],
            ],
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
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl + AppSpacing.sm),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 아이콘
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: AppColors.iconMuted,
                  ),
                  const SizedBox(height: AppSpacing.lg), // 섹션 간
                  // 제목
                  Text(
                    isOnboardingCompleted
                        ? '프로필을 불러올 수 없습니다'
                        : '프로필을 만들어주세요',
                    style: AppTypography.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  // 설명
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    isOnboardingCompleted
                        ? '프로필 정보를 다시 불러오는 중입니다'
                        : '반려동물 정보를 입력하면 맞춤 추천을 받을 수 있어요',
                    style: AppTypography.body2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg), // 섹션 간
                  // 프로필 다시 불러오기 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        if (isOnboardingCompleted) {
                          // 프로필 다시 불러오기
                          ref.read(homeControllerProvider.notifier).initialize();
                        } else {
                          // 프로필 만들기 (온보딩으로 이동)
                          context.go(RoutePaths.onboarding);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.status, // 상태 전용 (Green) - DESIGN_GUIDE v4.1
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isOnboardingCompleted
                            ? '프로필 다시 불러오기'
                            : '프로필 만들기',
                        style: AppTypography.button,
                      ),
                    ),
                  ),
                  // 다시 회원가입 하기 버튼 (임시)
                  if (isOnboardingCompleted) ...[
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () async {
                          // 온보딩 완료 상태 초기화
                          final repository = OnboardingRepositoryImpl();
                          await repository.clearAll();
                          // 온보딩 화면으로 이동
                          if (context.mounted) {
                            context.go(RoutePaths.onboarding);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: BorderSide(
                            color: AppColors.divider,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        child: Text(
                          '다시 회원가입 하기',
                          style: AppTypography.button.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 적합도 카드 (스크롤 유도 앵커)
  Widget _buildMatchScoreCard(petSummary, int matchScore, recommendationItem) {
    final matchReasons = (recommendationItem.matchReasons ?? []) as List<String>;
    // matchReasons에서 주요 이유 2-3개 추출 (긴 설명은 제외)
    final shortReasons = matchReasons
        .where((String reason) => reason.length < 30)
        .take(3)
        .toList();
    final summaryText = shortReasons.isNotEmpty
        ? shortReasons.join(' · ')
        : '${petSummary.name}에게 적합한 사료';

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: matchScore / 100.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return CardContainer(
          isHomeStyle: true,
          backgroundColor: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단: 체크 아이콘 + 점수 (애니메이션)
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 24,
                    color: AppColors.status, // 상태 전용 (Green) - DESIGN_GUIDE v4.1
                  ),
                  const SizedBox(width: AppSpacing.sm), // 텍스트/아이콘 간격
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: matchScore),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, animatedScore, child) {
                      return Text(
                        '$animatedScore%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md), // 섹션 그룹 간격
              // 하단: "{petName}에게 잘 맞을 확률이에요"
              Text(
                '${petSummary.name}에게 잘 맞을 확률이에요',
                style: AppTypography.body.copyWith(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm), // 요소 간
              // 설명: matchReasons 기반
              Text(
                summaryText,
                style: AppTypography.small.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }



  /// 1️⃣ 펫 선택 + 상태 요약 (카드 스타일) - iOS 스타일
  Widget _buildPetSummaryHeader(BuildContext context, petSummary, state) {
    
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: CardContainer(
              isHomeStyle: true,
              onTap: () {
                print('[HomeScreen] 🔘 펫 프로필 카드 클릭: ${petSummary.name}');
                context.push('/pet-profile-detail', extra: petSummary);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Row(
                      children: [
                        // 왼쪽: 아이콘 컨테이너 (design.mdc 준수)
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.divider, // 중성 회색 배경
                            borderRadius: BorderRadius.circular(AppRadius.lg), // rounded-2xl (16px)
                          ),
                          child: Center(
                            child: Text(
                              petSummary.species == 'DOG' ? '🐶' : '🐈',
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        // 가운데: 이름 + 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          petSummary.name,
                          style: AppTypography.h3.copyWith(
                                  color: AppColors.textPrimary, // #0F172A
                                  fontWeight: FontWeight.w700, // font-bold
                          ),
                        ),
                              const SizedBox(height: AppSpacing.xs),
                              // 상세 정보 (공통 위젯 사용)
                              PetInfoRow(petSummary: petSummary),
                            ],
                          ),
                        ),
                        // 오른쪽: chevron
                        Icon(
                    Icons.chevron_right,
                          color: AppColors.border, // #E5E7EB
                          size: 20,
                  ),
                ],
              ),
                    // 건강 고민 섹션
                    if (petSummary.healthConcerns.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                      Container(
                        height: 1,
                        color: AppColors.divider.withOpacity(0.3),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          ...petSummary.healthConcerns.take(3).map<Widget>((concern) {
                            final concernName = PetConstants.healthConcernNames[concern] ?? concern;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.divider,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                concernName,
                                style: AppTypography.badge.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                    // 알레르기 섹션
                    if (petSummary.foodAllergies.isNotEmpty || petSummary.otherAllergies != null) ...[
                      if (petSummary.healthConcerns.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          height: 1,
                          color: AppColors.divider.withOpacity(0.3),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ] else ...[
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          height: 1,
                          color: AppColors.divider.withOpacity(0.3),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          // 음식 알레르기 chips
                          if (petSummary.foodAllergies.isNotEmpty)
                            ...petSummary.foodAllergies.take(3).map<Widget>((allergen) {
                              final allergenName = PetConstants.allergenNames[allergen] ?? allergen;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.dangerRed.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                  border: Border.all(
                                    color: AppColors.dangerRed.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  allergenName,
                                  style: AppTypography.badge.copyWith(
                                    color: AppColors.dangerRed,
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ],
                  ],
                ),
            ),
          ),
        );
      },
    );
  }

  /// 펫 요약 바텀시트 표시
  void _showPetSummaryBottomSheet(BuildContext context, petSummary, state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPetSummaryBottomSheet(context, petSummary, state),
    );
  }

  /// 펫 요약 바텀시트 위젯 (iOS 스타일)
  Widget _buildPetSummaryBottomSheet(BuildContext context, petSummary, state) {
    // TODO: 현재 급여 사료 API 연동 후 실제 값으로 변경
    final hasCurrentFood = false; // 임시로 false
    final currentFoodName = '로얄캐닌 미니 어덜트 3kg'; // TODO: 실제 데이터
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 핸들 바
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 제목
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg + AppSpacing.xs, vertical: AppSpacing.lg),
                child: Row(
                  children: [
                    Text(
                      petSummary.name,
                      style: AppTypography.h2.copyWith(
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const Spacer(),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 0,
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              // 내용
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg + AppSpacing.xs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. 현재 급여 사료
                      _buildCurrentFoodSection(hasCurrentFood, currentFoodName),
                      const SizedBox(height: AppSpacing.lg),
                      // 2. 건강 고민 요약
                      _buildHealthConcernsSection(petSummary),
                      const SizedBox(height: AppSpacing.lg),
                      // 3. 알레르기 요약
                      _buildAllergiesSection(petSummary),
                      const SizedBox(height: AppSpacing.lg), // 섹션 간
                      // 4. CTA 버튼: 사료 다시 추천받기 (iOS 스타일)
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            // 추천 로드
                            ref.read(homeControllerProvider.notifier).loadRecommendations();
                          },
                          color: AppColors.status, // 상태 전용 (Green) - DESIGN_GUIDE v4.1
                          borderRadius: BorderRadius.circular(AppRadius.md), // 12px
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          child: Text(
                            '사료 다시 추천받기',
                            style: AppTypography.button.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg), // 섹션 간
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 현재 급여 사료 섹션
  Widget _buildCurrentFoodSection(bool hasCurrentFood, String currentFoodName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '현재 급여 사료',
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (hasCurrentFood) ...[
          // 등록됨: 상품명 표시 + '변경하기'
          Row(
            children: [
              Expanded(
                child: Text(
                  currentFoodName,
                  style: AppTypography.body.copyWith(
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: 현재 급여 사료 변경 화면으로 이동
                },
                child: Text(
                  '변경하기',
                  style: AppTypography.body.copyWith(
                    color: AppColors.status, // 상태 전용 (Green) - DESIGN_GUIDE v4.1
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          // 미등록: '지금 등록하기' 버튼
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              onPressed: () {
                print('[HomeScreen] 🔘 바텀시트 "지금 등록하기" 버튼 클릭');
                Navigator.of(context).pop(); // 바텀시트 닫기
                // 마켓 화면으로 이동 (사료 선택)
                context.go('/market');
              },
              color: AppColors.primary, // #2563EB
              borderRadius: BorderRadius.circular(AppRadius.md), // rounded-xl (12px)
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              child: Text(
                '지금 등록하기',
                style: AppTypography.button.copyWith(
                  fontSize: 16, // text-base sm:text-lg
                  fontWeight: FontWeight.w600, // font-semibold
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// 건강 고민 요약 섹션 (iOS 스타일)
  Widget _buildHealthConcernsSection(petSummary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '건강 고민',
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // 건강 고민 배지 (공통 위젯 사용)
        HealthConcernChips(healthConcerns: petSummary.healthConcerns),
      ],
    );
  }

  /// 알레르기 요약 섹션 (iOS 스타일)
  Widget _buildAllergiesSection(petSummary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '알레르기',
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // 알레르기 목록 (공통 위젯 사용)
        AllergyList(petSummary: petSummary),
      ],
    );
  }

  /// 홈 화면 콘텐츠 (조건부 렌더링) - iOS 스타일 애니메이션
  Widget _buildHomeContent(BuildContext context, petSummary, state, topRecommendation) {
    // TODO: 현재 급여 사료 API 연동 후 실제 값으로 변경
    final hasCurrentFood = false; // 임시로 false
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        // 1. 현재 급여 사료 관련 카드 (메인) - 페이드인 애니메이션
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - value)),
                child: _buildCurrentFoodCard(petSummary, state, hasCurrentFood: hasCurrentFood),
              ),
            );
          },
        ),
        // UPDATED: Always show recommendation card regardless of hasCurrentFood
        // Dynamic content based on current food registration status
        const SizedBox(height: AppSpacing.lg),
        // 추천 카드 (항상 표시)
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.scale(
                scale: 0.95 + (0.05 * value),
                child: _buildRecommendationCard(context, petSummary, state, topRecommendation),
              ),
            );
          },
        ),
        if (hasCurrentFood) ...[
          const SizedBox(height: AppSpacing.lg),
          // 가격/소진 상태 신호 카드
          _buildStatusSignalCards(petSummary, state),
        ],
        
        const SizedBox(height: AppSpacing.md),
        // 2. 상태 설명 텍스트 - 페이드인 애니메이션
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: _buildStatusDescription(petSummary, state, hasCurrentFood),
            );
          },
        ),
        
        const SizedBox(height: AppSpacing.lg),
        // 3. 혜택 카드 (보조) - 페이드인 애니메이션
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - value)),
                child: _buildBenefitsSection(),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.xxxl), // 하단 여백 (48px)
      ],
    );
  }

  /// 상태 설명 문구
  Widget _buildStatusDescription(petSummary, state, bool hasCurrentFood) {
    final descriptionText = hasCurrentFood
        ? '현재 급여 사료를 기준으로 가격과 상태를 관리하고 있어요'
        : '지금 먹는 사료를 등록하면 가격과 소진 시점을 알려드릴 수 있어요';
    
    return Text(
      descriptionText,
      style: AppTypography.small.copyWith(
        color: const Color(0xFF64748B),
        fontSize: 14,
      ),
    );
  }

  /// 추천 카드 표시 여부 판단
  // UPDATED: Always show recommendation card regardless of hasCurrentFood
  // Goal: Reduce entry barrier, show core value immediately
  bool _shouldShowRecommendationCard(petSummary, state, topRecommendation) {
    // 항상 추천 카드 표시 (hasCurrentFood 조건 제거)
    return true;
  }

  /// 추천 카드 위젯
  // UPDATED: Always show recommendation card regardless of hasCurrentFood
  // Dynamic content based on current food registration status
  // Goal: Reduce entry barrier, show core value immediately
  // DESIGN_GUIDE: CardContainer 사용, Shadow 없음, Border로 구분, h3 타이틀
  Widget _buildRecommendationCard(
    BuildContext context,
    petSummary,
    state,
    topRecommendation,
  ) {
    // TODO: 현재 급여 사료 API 연동 후 실제 값으로 변경
    final hasCurrentFood = false; // 임시로 false
    
    // 에러 상태 처리 (추천 로드 중 에러 발생)
    if (state.error != null && !state.isLoadingRecommendations) {
      return CardContainer(
        isHomeStyle: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasCurrentFood 
                  ? "현재 사료 vs 맞춤 추천 비교" 
                  : "우리 애에게 딱 맞는 사료 찾아보기",
              style: AppTypography.h3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.iconMuted,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    "추천을 불러오는데 실패했어요",
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    state.error ?? "잠시 후 다시 시도해주세요.",
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      onPressed: () {
                        ref.read(homeControllerProvider.notifier).loadRecommendations(force: true);
                      },
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.md,
                      ),
                      child: Text(
                        "다시 시도",
                        style: AppTypography.button.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    // 로딩 중일 때
    if (state.isLoadingRecommendations) {
      return CardContainer(
        isHomeStyle: true,
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/loading_dots.json',
                width: 500,
                height: 500,
                fit: BoxFit.contain,
                repeat: true,
                animate: true,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '${petSummary.name}에게 딱 맞는 사료 찾는 중...',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    final recommendations = state.recommendations;
    // 현재 펫의 추천 결과인지 확인 (펫 ID가 일치하는 경우만 표시)
    final isCurrentPetRecommendation = recommendations?.petId == petSummary.petId;
    final hasRecommendations = isCurrentPetRecommendation && recommendations != null && recommendations.items.isNotEmpty;
    final isEmptyResult = isCurrentPetRecommendation && recommendations != null && recommendations.items.isEmpty && !state.isLoadingRecommendations;
    final petName = petSummary.name;
    final topRecommendation = hasRecommendations ? recommendations!.items[0] : null;
    
    // DESIGN_GUIDE: CardContainer 사용, isHomeStyle: true, Shadow 없음
    return CardContainer(
      isHomeStyle: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DESIGN_GUIDE: 카드 타이틀은 h3 사용
          Text(
            "$petName에게 딱 맞는 사료 찾아보기",
            style: AppTypography.h3.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          // 빈 추천 결과 처리 (로딩 완료 후 결과가 없는 경우)
          if (isEmptyResult) ...[
            _buildEmptyRecommendationState(context, recommendations?.message),
          ] else ...[
            // 추천 결과 표시 (조건부)
            if (hasRecommendations && topRecommendation != null) ...[
              _buildRecommendedProductCard(context, topRecommendation),
              const SizedBox(height: AppSpacing.md),
            ] else ...[
              // 안내 문구 표시
              Text(
                "알레르기, 나이, 건강 고민만 알려주세요!\n바로 맞춤 사료 추천해드릴게요.",
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            
            // 액션 버튼
              SizedBox(
                width: double.infinity,
              child: ElevatedButton.icon(
                  onPressed: () {
                    // 추천 애니메이션 화면으로 이동
                    final petSummary = state.petSummary;
                    if (petSummary != null) {
                      context.push(
                        RoutePaths.recommendationAnimation,
                        extra: petSummary,
                      );
                    }
                  },
                icon: Icon(
                  state.recommendationActionText == "지금 추천받기" 
                      ? Icons.auto_awesome 
                      : Icons.refresh,
                  color: Colors.white,
                  ),
                label: Text(
                  state.recommendationActionText,
                        style: AppTypography.button.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                  ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 빈 추천 결과 Empty State
  Widget _buildEmptyRecommendationState(BuildContext context, String? message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.iconMuted,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            "추천 상품을 찾지 못했어요",
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message ?? "현재 조건에 맞는 추천 상품이 없습니다.",
            style: AppTypography.body2.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 추천 상품 미리보기 카드
  Widget _buildRecommendedProductCard(
    BuildContext context,
    RecommendationItemDto item,
  ) {
    return InkWell(
      onTap: () {
        // 상품 상세 화면으로 이동 (TODO: route 추가 필요)
        // context.push('/products/${item.product.id}');
              },
              borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            // 이미지 플레이스홀더
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(
                Icons.image_not_supported,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.brandName,
                    style: AppTypography.small.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs / 2),
                  Text(
                    item.product.productName,
                    style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    PriceFormatter.formatWithCurrency(item.currentPrice),
                    style: AppTypography.h3.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
            ),
          ),
        ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 2️⃣ 현재 급여 사료 카드 (홈의 중심, 60% 비중)
  Widget _buildCurrentFoodCard(petSummary, state, {bool? hasCurrentFood}) {
    // TODO: 현재 급여 사료 API 연동
    final hasCurrentFoodValue = hasCurrentFood ?? false; // 기본값 false
    
    if (!hasCurrentFoodValue) {
      // 상태 B: 현재 사료 미등록
      return CardContainer(
        isHomeStyle: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${petSummary.name}가\n지금 먹고 있는 사료를 알려주세요',
              style: AppTypography.h2.copyWith(
                color: AppColors.textPrimary,
                fontSize: 24,
                height: 1.4,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            IconTextRow(
                  icon: Icons.arrow_downward,
                  text: '가격 내려가면 알림',
                  iconColor: AppColors.petGreen, // 상태/안심용
                ),
                const SizedBox(height: AppSpacing.md),
                IconTextRow(
                  icon: Icons.access_time,
                  text: '떨어지기 전에 알림',
                  iconColor: AppColors.petGreen, // 상태/안심용
                ),
            const SizedBox(height: AppSpacing.lg), // 버튼 위 여백
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  print('[HomeScreen] 🔘 "지금 먹는 사료 등록하기" 버튼 클릭');
                  // 마켓 화면으로 이동 (사료 선택)
                  context.go('/market');
                },
                icon: Icon(
                  Icons.add_circle_outline,
                  color: Colors.white,
                ),
                label: Text(
                  '지금 먹는 사료 등록하기',
                  style: AppTypography.button.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // 상태 A: 등록되어 있을 때
    return CardContainer(
      isHomeStyle: true,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 배지
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // DESIGN_GUIDE v2.2: Chip padding
              decoration: BoxDecoration(
                color: AppColors.petGreen, // 상태/안심용
                borderRadius: BorderRadius.circular(AppRadius.pill), // 완전 둥근 CTA
              ),
              child: Text(
                '현재 급여 중',
                style: AppTypography.caption.copyWith(
                  color: Colors.white, // 흰색 텍스트
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md), // 섹션 그룹 간격
            // 사료 정보
            Text(
              '로얄캐닌 미니 어덜트 3kg', // TODO: 실제 데이터
              style: AppTypography.h2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
            const SizedBox(height: AppSpacing.md), // 섹션 그룹 간격
            // 가격 정보 카드
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.statusLight, // 상태 전용 배경 - DESIGN_GUIDE v4.1
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(
                          Icons.attach_money,
                          size: 20,
                          color: AppColors.status, // 상태 전용 (Green) - DESIGN_GUIDE v4.1
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm), // 텍스트/아이콘 간격
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '현재 최저가',
                              style: AppTypography.small.copyWith(
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm), // 요소 간
                            Text(
                              '38,900원', // TODO: 실제 데이터
                              style: AppTypography.h3.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppColors.status, // 상태 전용 (Green) - DESIGN_GUIDE v4.1
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.arrow_down,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: AppSpacing.sm), // 요소 간
                            Text(
                              '-12%',
                              style: AppTypography.small.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm), // 텍스트/아이콘 간격
                  Text(
                    '30일 평균 대비',
                    style: AppTypography.small.copyWith(
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md), // 섹션 그룹 간격
            // 소진 예상
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg), // 16px
              decoration: BoxDecoration(
                color: AppColors.statusLight, // 상태 전용 배경 - DESIGN_GUIDE v4.1
                borderRadius: BorderRadius.circular(AppRadius.md), // 12px
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      CupertinoIcons.clock,
                      size: 20,
                      color: AppColors.status, // 상태 전용 (Green) - DESIGN_GUIDE v4.1
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm), // 텍스트/아이콘 간격
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '예상 소진까지',
                          style: AppTypography.small.copyWith(
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm), // 요소 간
                        Row(
                          children: [
                            Text(
                              '9일',
                              style: AppTypography.h3.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm), // 텍스트/아이콘 간격
                            Text(
                              '(정확도: 보통)', // TODO: 실제 데이터
                              style: AppTypography.small.copyWith(
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg), // 버튼 위 여백
            // CTA 버튼 2개
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: 가격 알림 설정
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md + 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md), // 12px
                      ),
                      side: const BorderSide(
                        color: AppColors.status, // 상태 전용 (Green) - DESIGN_GUIDE v4.1
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '가격 알림 ON',
                      style: AppTypography.button.copyWith(
                        color: AppColors.status, // 상태 전용 (Green) - DESIGN_GUIDE v4.1
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm), // 요소 간
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: 구매 페이지로 이동
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryCoral, // Warm Terracotta (DESIGN_GUIDE v2.2)
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24), // DESIGN_GUIDE v2.2
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md), // 12px
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      '구매하러 가기',
                      style: AppTypography.button.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
    );
  }

  /// 3️⃣ 상태 신호 카드 (조건부 노출) - iOS 스타일
  Widget _buildStatusSignalCards(petSummary, state) {
    final signals = <Widget>[];
    
    // 예시 1: 가격 신호 (조건부)
    final shouldShowPriceSignal = false; // TODO: 실제 조건 확인
    if (shouldShowPriceSignal) {
      signals.add(
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - value)),
                child: StatusSignalCard(
                  icon: Icons.arrow_downward,
                  title: '지금 먹는 사료가',
                  subtitle: '최근 30일 중 가장 싸요',
                  backgroundColor: AppColors.divider, // 중성 회색 배경
                  iconColor: AppColors.textSecondary, // 중성 회색 아이콘
                ),
              ),
            );
          },
        ),
      );
    }
    
    // 예시 2: 소진 신호 (조건부)
    final shouldShowDepletionSignal = false; // TODO: 실제 조건 확인
    if (shouldShowDepletionSignal) {
      signals.add(
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - value)),
                child: StatusSignalCard(
                  icon: Icons.access_time,
                  title: '3일 뒤면 사료가',
                  subtitle: '떨어질 수 있어요',
                  backgroundColor: const Color(0xFFFFF7ED),
                  iconColor: const Color(0xFFF97316),
                ),
              ),
            );
          },
        ),
      );
    }
    
    // 예시 3: 건강 신호 (조건부)
    final shouldShowHealthSignal = false; // TODO: 실제 조건 확인
    if (shouldShowHealthSignal) {
      signals.add(
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - value)),
                child: StatusSignalCard(
                  icon: Icons.warning_amber_rounded,
                  title: '이 사료, ${petSummary.name} 관절 고민엔',
                  subtitle: '조금 아쉬울 수 있어요',
                  backgroundColor: const Color(0xFFFEF2F2),
                  iconColor: const Color(0xFFDC2626),
                ),
              ),
            );
          },
        ),
      );
    }
    
    if (signals.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: signals,
    );
  }

  /// 기능 아이템 빌더
  Widget _buildFeatureItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
        const SizedBox(width: AppSpacing.sm), // 텍스트/아이콘 간격
        Expanded(
          child: Text(
            text,
            style: AppTypography.body.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// 4️⃣ 추천 영역 (조건부)
  bool _shouldShowRecommendation(state, topRecommendation) {
    // 추천이 필요한 순간에만 등장
    // - 나이 단계 변경
    // - 건강 고민 추가
    // - 현재 사료가 평균 이하 점수
    // - 보호자가 직접 눌렀을 때
    return _isRecommendationExpanded && topRecommendation != null;
  }

  Widget _buildConditionalRecommendation(
    BuildContext context,
    petSummary,
    state,
    topRecommendation,
  ) {
    if (state.isLoadingRecommendations) {
      return CardContainer(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/loading_dots.json',
                width: 500,
                height: 500,
                fit: BoxFit.contain,
                repeat: true,
                animate: true,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '${petSummary.name}에게 딱 맞는 사료 찾는 중...',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    if (topRecommendation == null) {
      return const SizedBox.shrink();
    }
    
    return CardContainer(
      padding: const EdgeInsets.all(AppSpacing.lg + AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '지금 먹는 사료보다\n${petSummary.name}에게 더 잘 맞는 사료가 있어요',
            style: AppTypography.h3.copyWith(
              color: const Color(0xFF111827),
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.lg), // 카드 간
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // 추천 상세 보기
                _toggleRecommendation();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md + 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md), // 12px
                ),
                side: BorderSide(color: AppColors.primary), // Emerald Green (DESIGN_GUIDE v2.3)
              ),
              child: Text(
                '비교해보기',
                style: AppTypography.button.copyWith(
                  color: AppColors.primary, // Blue (#1D4ED8) - DESIGN_GUIDE v4.1 (Calm Blue 통일)
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 5️⃣ 혜택 / 포인트 (보조)
  Widget _buildBenefitsSection() {
    return CardContainer(
      isHomeStyle: true,
      backgroundColor: const Color(0xFFF8FAFC), // 색상 낮춤
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  size: 20,
                  color: Color(0xFF64748B), // 색상 낮춤
                ),
              ),
              const SizedBox(width: AppSpacing.sm), // 텍스트/아이콘 간격
              Text(
                '이번 달 혜택',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600, // 강조 낮춤
                  color: const Color(0xFF64748B), // 색상 낮춤
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md), // 섹션 그룹 간격
          _buildBenefitItem('첫 구매 1,000P'),
          const SizedBox(height: AppSpacing.md), // 섹션 그룹 간격
          _buildBenefitItem('가격 알림 유지 시 +200P'),
        ],
      ),
    );
  }

  /// 혜택 아이템 빌더
  Widget _buildBenefitItem(String text) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF94A3B8), // 색상 낮춤
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            size: 12,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: AppSpacing.sm), // 텍스트/아이콘 간격
        Expanded(
          child: Text(
            text,
            style: AppTypography.small.copyWith(
              color: const Color(0xFF64748B), // 색상 낮춤
              fontWeight: FontWeight.w500, // 강조 낮춤
            ),
          ),
        ),
      ],
    );
  }


  /// 애니메이션 불릿 포인트 위젯 (개선된 버전)
  Widget _buildAnimatedBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: AppSpacing.xs + 2, right: AppSpacing.md),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.petGreen, // 상태/안심용
            shape: BoxShape.circle,
            // DESIGN_GUIDE: Shadow 제거, Border로 구분
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: AppTypography.body.copyWith(
              color: const Color(0xFF111827),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
