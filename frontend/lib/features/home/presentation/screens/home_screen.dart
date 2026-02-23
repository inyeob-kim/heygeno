import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../ui/widgets/price_delta.dart';
import '../../../../../design_system/components/app_card.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/app_radius.dart';
// Design System
import '../../../../../design_system/tokens/index.dart' as DesignTokens;
import '../../../../../design_system/components/index.dart';
import '../../../../../design_system/typography/index.dart' as DesignTypography;
// i18n
import 'package:pet_food_app/l10n/app_localizations.dart';
import '../../../../../app/router/route_paths.dart';
import '../../../../../core/utils/price_formatter.dart';
import '../../../../../utils/formatters.dart';
import '../../../../../core/widgets/loading.dart';
import 'package:lottie/lottie.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../domain/services/onboarding_service.dart';
import '../controllers/home_controller.dart';
import '../../../../../ui/widgets/app_top_bar.dart';
import '../../../../../ui/widgets/pet_selector.dart';
import '../../../../../core/constants/pet_constants.dart';
import '../widgets/status_signal_card.dart';
import '../widgets/campaign_modal.dart';
import '../widgets/home_campaign_banner.dart';
import '../../../../../data/models/recommendation_dto.dart';
import '../../../../../data/models/campaign_dto.dart';
import '../../../../../ui/widgets/health_concern_chips.dart';
import '../../../../../ui/widgets/allergy_list.dart';
import '../../../../../core/providers/modal_visibility_provider.dart';
import '../../../recommendation/presentation/screens/recommendation_adjust_screen.dart';
import '../../../benefits/presentation/controllers/benefits_controller.dart';

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
  CampaignDto? _currentCampaign; // 현재 표시할 캠페인
  bool _hasClosedModal = false; // 모달을 닫았는지 여부
  bool _hasClosedBanner = false; // 배너를 닫았는지 여부

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
    
    // UPDATED: "지금 추천받기" 또는 "다시 추천 받기" 버튼 클릭 시 항상 조건 조정 화면으로 이동
    // Always navigate to recommendation adjust screen when button is clicked
    if (!state.isLoadingRecommendations) {
      final petSummary = state.petSummary;
      if (petSummary != null) {
        print('[HomeScreen] ✅ 조건 조정 화면으로 이동: petId=${petSummary.petId}, petName=${petSummary.name}');
        
        // 기존 추천이 있으면 초기값으로 사용
        RecommendationAdjustParams? initialParams;
        if (recommendations != null && recommendations!.items.isNotEmpty) {
          final topItem = recommendations!.items.first;
          if (topItem.dailyAmountG != null) {
            initialParams = RecommendationAdjustParams(
              minDailyAmount: (topItem.dailyAmountG! * 0.8).round(),
              maxDailyAmount: (topItem.dailyAmountG! * 1.2).round(),
              maxMonthlyBudget: topItem.currentPrice * 30, // 일일 가격 * 30일
              emphasizedConcerns: [],
            );
            initialParams.baseDailyAmount = topItem.dailyAmountG;
            initialParams.baseMonthlyBudget = topItem.currentPrice * 30;
          }
        }
        
        // 조건 조정 화면으로 push
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecommendationAdjustScreen(
              petSummary: petSummary,
              initialParams: initialParams,
            ),
          ),
        ).then((result) {
          // 조건 조정 화면에서 뒤로 가기만 한 경우 (result가 null)
          // 애니메이션 화면으로 이동하는 것은 RecommendationAdjustScreen에서 처리
          if (result == null) {
            print('[HomeScreen] 조건 조정 화면에서 뒤로 가기');
            return;
          }
        });
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
      
      // 캠페인 로드 완료 시 첫 번째 캠페인 표시 (모달을 닫지 않았을 때만)
      if (next.homeModalCampaigns != null && 
          next.homeModalCampaigns!.isNotEmpty &&
          _currentCampaign == null &&
          !_hasClosedModal) {
        // 이전 상태와 비교하여 새로 로드된 경우에만 표시
        final wasEmpty = previous?.homeModalCampaigns == null || 
                        previous!.homeModalCampaigns!.isEmpty;
        if (wasEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (_currentCampaign == null && !_hasClosedModal) {
              setState(() {
                _currentCampaign = next.homeModalCampaigns!.first;
              });
              // 모달 표시 시 바텀탭 숨기기
              ref.read(modalVisibilityProvider.notifier).state = true;
              print('[HomeScreen] 캠페인 모달 표시: ${_currentCampaign?.key}');
            }
          });
        }
      }
      
      // 배너 캠페인 로드 완료 시 - ref.listen에서는 아무것도 하지 않음
      // build 메서드에서 조건부로 표시
    });
    
    // build 메서드에서도 확인 (초기 로드 시)
    if (state.homeModalCampaigns != null && 
        state.homeModalCampaigns!.isNotEmpty &&
        _currentCampaign == null &&
        !_hasClosedModal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_currentCampaign == null && !_hasClosedModal) {
          setState(() {
            _currentCampaign = state.homeModalCampaigns!.first;
          });
          // 모달 표시 시 바텀탭 숨기기
          ref.read(modalVisibilityProvider.notifier).state = true;
          print('[HomeScreen] 캠페인 모달 표시 (build): ${_currentCampaign?.key}');
        }
      });
    }
    
    // 배너도 확인 (초기 로드 시)
    // build 메서드에서는 상태 변수를 변경하지 않고, 조건부 렌더링만 수행

    // 위젯 트리 구조 통일: 모든 상태에서 동일한 Scaffold 구조 사용
    // _scrollController를 항상 사용하여 unmount/mount 시 안전성 확보
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
          children: [
            // 상단 고정 탭 (알림 아이콘 포함)
            AppTopBar(
              // TODO: flutter gen-l10n 실행 후 주석 해제
              // title: state.userNickname != null 
              //     ? AppLocalizations.of(context)!.screenHomeTitle(state.userNickname!)
              //     : AppLocalizations.of(context)!.appName,
              title: state.userNickname != null 
                  ? AppLocalizations.of(context)!.screen_home_title(state.userNickname ?? '')
                  : AppLocalizations.of(context)!.appName,
              showBackButton: false,
              titleWidget: const PetSelector(),
              actions: [
                // 더보기 (My Screen) 버튼
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  color: AppColors.textPrimary,
                  tooltip: AppLocalizations.of(context)!.tab_more,
                  onPressed: () {
                    context.push(RoutePaths.me);
                  },
                ),
                SizedBox(width: DesignTokens.Spacing.sm),
              ],
            ),
            // 스크롤 가능한 콘텐츠 (항상 동일한 구조)
            Expanded(
              child: CupertinoScrollbar(
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  // 모달이 떠있을 때는 스크롤 비활성화
                  physics: _currentCampaign != null 
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(), // iOS 스타일 바운스
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: AppSpacing.lg, // 16px
                      right: AppSpacing.lg, // 16px
                      top: AppSpacing.lg, // 16px
                      bottom: AppSpacing.xl * 2, // 48px
                    ),
                    child: _buildBodyContent(context, state),
                  ),
                ),
              ),
            ),
          ],
            ),
          ),
        ),
        // 캠페인 모달 배경 오버레이 및 모달
        if (_currentCampaign != null)
          Stack(
            children: [
              // 어두운 배경 오버레이 (blur 효과)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentCampaign = null;
                    _hasClosedModal = true;
                  });
                  // 모달 닫기 시 바텀탭 다시 표시
                  ref.read(modalVisibilityProvider.notifier).state = false;
                  print('[HomeScreen] 모달 닫기 (배경 클릭)');
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ),
              // 모달
              CampaignModal(
                campaign: _currentCampaign!,
                onClose: () {
                  setState(() {
                    _currentCampaign = null;
                    _hasClosedModal = true;
                  });
                  // 모달 닫기 시 바텀탭 다시 표시
                  ref.read(modalVisibilityProvider.notifier).state = false;
                  print('[HomeScreen] 모달 닫기 (닫기 버튼)');
                },
              ),
            ],
          ),
      ],
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
            // TODO: flutter gen-l10n 실행 후 주석 해제
            // title: state.error ?? AppLocalizations.of(context)!.errorOccurred,
            // buttonText: AppLocalizations.of(context)!.actionTryAgain,
            title: state.error ?? AppLocalizations.of(context)!.error_occurred,
            buttonText: AppLocalizations.of(context)!.action_tryAgain,
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
        // Hero Section (Rover 스타일)
        _buildHeroSection(context, petSummary),
        const SizedBox(height: AppSpacing.lg),
        // 1️⃣ 펫 선택 + 상태 요약 (카드) - 이미 애니메이션 포함
        _buildPetSummaryHeader(context, petSummary, state),
        // 배너 (펫 카드 아래)
        // 상태 변수 대신 state에서 직접 가져오기 (더 안전)
        if (!_hasClosedBanner &&
            state.homeBannerCampaigns != null &&
            state.homeBannerCampaigns!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md), // 펫 카드와 배너 사이 간격
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: _buildCampaignBanner(context, state.homeBannerCampaigns!.first),
          ),
          const SizedBox(height: AppSpacing.lg), // 배너와 다음 콘텐츠 사이 간격
        ],
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
        
        // EmptyState 컴포넌트 사용
        // TODO: flutter gen-l10n 실행 후 주석 해제
        // final l10n = AppLocalizations.of(context)!;
        return EmptyState(
          icon: Icons.favorite_border,
          // TODO: flutter gen-l10n 실행 후 교체
          // title: isOnboardingCompleted
          //     ? l10n.emptyNoPetProfileTitleFailed
          //     : l10n.emptyNoPetProfileTitle,
          // message: isOnboardingCompleted
          //     ? l10n.emptyNoPetProfileSubtitleFailed
          //     : l10n.emptyNoPetProfileSubtitle,
          // buttonText: isOnboardingCompleted 
          //     ? l10n.actionReloadProfile 
          //     : l10n.actionCreateProfile,
          title: isOnboardingCompleted
              ? AppLocalizations.of(context)!.empty_noPetProfile_title_failed
              : AppLocalizations.of(context)!.empty_noPetProfile_title,
          message: isOnboardingCompleted
              ? AppLocalizations.of(context)!.empty_noPetProfile_subtitle_failed
              : AppLocalizations.of(context)!.empty_noPetProfile_subtitle,
          buttonText: isOnboardingCompleted 
              ? AppLocalizations.of(context)!.action_reloadProfile 
              : AppLocalizations.of(context)!.action_createProfile,
          onButtonPressed: () {
            if (isOnboardingCompleted) {
              // 프로필 다시 불러오기
              ref.read(homeControllerProvider.notifier).initialize();
            } else {
              // 프로필 만들기 (온보딩으로 이동)
              context.push(RoutePaths.petProfile);
            }
          },
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
    return AppCard(
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
                  child: Text(
                    // TODO: flutter gen-l10n 실행 후 주석 해제
                    // AppLocalizations.of(context)!.priceLowestPrice,
                    AppLocalizations.of(context)!.price_lowestPrice,
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
            // TODO: flutter gen-l10n 실행 후 주석 해제
            // AppLocalizations.of(context)!.priceCheaperThanAverage(priceDiffPercent),
            AppLocalizations.of(context)!.price_cheaperThanAverage(priceDiffPercent),
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
    
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            // TODO: flutter gen-l10n 실행 후 주석 해제
            // AppLocalizations.of(context)!.sectionWhyThisProduct,
            AppLocalizations.of(context)!.section_whyThisProduct,
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
              _buildAnimatedBulletPoint('${Formatters.weightLb(petSummary.weightKg)} 체중에 적합'),
              const SizedBox(height: AppSpacing.sm),
              _buildAnimatedBulletPoint(AppLocalizations.of(context)!.message_suitableForAgeStage(petSummary.ageStage ?? AppLocalizations.of(context)!.ageStage_adult)),
              if (petSummary.healthConcerns.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _buildAnimatedBulletPoint(AppLocalizations.of(context)!.product_considersHealthConcerns),
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
                        ? AppLocalizations.of(context)!.empty_noPetProfile_title_failed
                        : AppLocalizations.of(context)!.empty_noPetProfile_title,
                    style: AppTypography.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  // 설명
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    isOnboardingCompleted
                        ? AppLocalizations.of(context)!.empty_noPetProfile_subtitle_failed
                        : AppLocalizations.of(context)!.empty_noPetProfile_subtitle,
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
                            ? AppLocalizations.of(context)!.action_reloadProfile
                            : AppLocalizations.of(context)!.action_createProfile,
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
                          await ref.read(onboardingServiceProvider).resetOnboarding();
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
                          AppLocalizations.of(context)!.action_signUpAgain,
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
        return AppCard(
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



  /// 캠페인 배너 빌드 (CampaignDto를 파싱하여 HomeCampaignBanner에 전달)
  Widget _buildCampaignBanner(BuildContext context, CampaignDto campaign) {
    final content = campaign.content;
    final title = content['title'] as String? ?? '';
    final description = content['description'] as String? ?? '';
    final imageUrl = content['image_url'] as String?;
    final cta = content['cta'] as Map<String, dynamic>?;
    final ctaText = cta?['text'] as String? ?? AppLocalizations.of(context)!.action_participate;
    final ctaDeeplink = cta?['deeplink'] as String?;

    // message는 description을 사용 (없으면 빈 문자열)
    final message = description.isNotEmpty ? description : '';

    return HomeCampaignBanner(
      title: title,
      message: message,
      ctaText: ctaText,
      imageUrl: imageUrl,
      onTap: () {
        if (ctaDeeplink != null && ctaDeeplink.isNotEmpty) {
          context.push(ctaDeeplink);
        }
      },
      onClose: () {
        if (mounted) {
          setState(() {
            _hasClosedBanner = true;
          });
          print('[HomeScreen] 배너 닫기');
        }
      },
    );
  }

  /// Hero Section (Rover 스타일)
  Widget _buildHeroSection(BuildContext context, petSummary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hey ${petSummary.name}! 🐾',
          style: DesignTypography.TextStyles.h1Mobile,
        ),
        SizedBox(height: DesignTokens.Spacing.sm),
        Text(
          'Ready to find food that fits ${petSummary.name}?',
          style: DesignTypography.TextStyles.bodySecondary,
        ),
      ],
    );
  }

  /// Rewards Summary Card
  Widget _buildRewardsSummaryCard(BuildContext context) {
    final benefitsState = ref.watch(benefitsControllerProvider);
    final points = benefitsState.totalPoints;
    final missions = benefitsState.missions;
    final availableMissionsCount = missions.where((m) => !m.completed).length;
    
    return AppCard(
      onTap: () {
        context.push(RoutePaths.benefits);
      },
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.card_giftcard,
              size: 24,
              color: Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.section_rewards,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (availableMissionsCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$availableMissionsCount',
                          style: AppTypography.small.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.rewards_summaryPoints(points),
                      style: AppTypography.h3.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.rewards_summaryMissions(availableMissionsCount),
                        style: AppTypography.small.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Chevron
          const Icon(
            Icons.chevron_right,
            size: 20,
            color: AppColors.iconMuted,
          ),
        ],
      ),
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
            child: AppCard(
              onTap: () {
                print('[HomeScreen] 🔘 펫 프로필 카드 클릭: ${petSummary.name}');
                context.push('/pet-profile-detail', extra: petSummary);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Row(
                      children: [
                        // 왼쪽: 큰 원형 이미지 (Rover 스타일)
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.divider,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              petSummary.species == 'DOG' ? '🐶' : '🐈',
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                        ),
                        const SizedBox(width: DesignTokens.Spacing.base),
                        // 가운데: 이름 + 한 줄 요약
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                petSummary.name,
                                style: DesignTypography.TextStyles.h3,
                              ),
                              const SizedBox(height: DesignTokens.Spacing.xs),
                              // 한 줄 요약: Senior • 30.2 lb • Neutered
                              Text(
                                _formatPetSummaryOneLine(petSummary),
                                style: DesignTypography.TextStyles.bodySecondary,
                              ),
                            ],
                          ),
                        ),
                        // 오른쪽: chevron
                        Icon(
                          Icons.chevron_right,
                          color: AppColors.border,
                          size: 20,
                        ),
                      ],
                    ),
                    // 건강 고민 섹션 (최대 2개 + 'more')
                    if (petSummary.healthConcerns.isNotEmpty) ...[
                      const SizedBox(height: DesignTokens.Spacing.base),
                      Wrap(
                        spacing: DesignTokens.Spacing.sm,
                        runSpacing: DesignTokens.Spacing.sm,
                        children: [
                          ...petSummary.healthConcerns.take(2).map<Widget>((concern) {
                            final concernName = PetConstants.getHealthConcernName(context, concern);
                            return AppBadge(
                              label: concernName,
                              variant: BadgeVariant.primary,
                            );
                          }),
                          if (petSummary.healthConcerns.length > 2)
                            AppBadge(
                              label: '+${petSummary.healthConcerns.length - 2} more',
                              variant: BadgeVariant.primary,
                            ),
                        ],
                      ),
                    ],
                    // 알레르기 섹션 (Avoid 배지)
                    if (petSummary.foodAllergies.isNotEmpty || petSummary.otherAllergies != null) ...[
                      const SizedBox(height: DesignTokens.Spacing.base),
                      Row(
                        children: [
                          AppBadge(
                            label: 'Avoid',
                            variant: BadgeVariant.error,
                          ),
                          const SizedBox(width: DesignTokens.Spacing.sm),
                          Expanded(
                            child: Text(
                              _formatAllergies(petSummary),
                              style: DesignTypography.TextStyles.bodySecondary,
                            ),
                          ),
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

  /// 펫 한 줄 요약 포맷 (Rover 스타일)
  String _formatPetSummaryOneLine(petSummary) {
    final parts = <String>[];
    
    if (petSummary.ageStage != null) {
      final ageStage = petSummary.ageStage!;
      if (ageStage == 'PUPPY') {
        parts.add('Puppy');
      } else if (ageStage == 'ADULT') {
        parts.add('Adult');
      } else if (ageStage == 'SENIOR') {
        parts.add('Senior');
      }
    }
    
    if (petSummary.weightKg > 0) {
      parts.add(Formatters.weightLb(petSummary.weightKg));
    }
    
    if (petSummary.isNeutered == true) {
      parts.add('Neutered');
    }
    
    return parts.join(' • ');
  }

  /// 알레르기 포맷
  String _formatAllergies(petSummary) {
    final allergies = <String>[];
    
    if (petSummary.foodAllergies.isNotEmpty) {
      // List<dynamic>을 List<String>으로 안전하게 변환
      final foodAllergiesList = List<String>.from(
        petSummary.foodAllergies.map((e) => e.toString()),
      );
      
      allergies.addAll(
        foodAllergiesList.map((allergen) {
          return PetConstants.getAllergenName(context, allergen);
        }),
      );
    }
    
    if (petSummary.otherAllergies != null && petSummary.otherAllergies!.isNotEmpty) {
      allergies.add(petSummary.otherAllergies!);
    }
    
    return allergies.join(', ');
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
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: ui.Radius.circular(20)),
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
                      _buildCurrentFoodSection(hasCurrentFood),
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
                            AppLocalizations.of(context)!.action_getRecommendationsAgain,
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
  Widget _buildCurrentFoodSection(bool hasCurrentFood) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.pet_currentFoodSection,
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (hasCurrentFood) ...[
          // 등록됨: 상품명 표시 + '변경하기'
          // TODO: 실제 현재 급여 사료 데이터 표시
          Row(
            children: [
              Expanded(
                child: Text(
                  '', // TODO: 실제 데이터로 교체
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
                  AppLocalizations.of(context)!.action_change,
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
                context.go(RoutePaths.market);
              },
              color: AppColors.primary, // #2563EB
              borderRadius: BorderRadius.circular(AppRadius.md), // rounded-xl (12px)
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              child: Text(
                AppLocalizations.of(context)!.action_registerNow,
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
          AppLocalizations.of(context)!.section_healthConcerns,
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
          AppLocalizations.of(context)!.section_allergies,
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
        // Rewards Summary Card (추천 카드 아래)
        const SizedBox(height: AppSpacing.lg),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - value)),
                child: _buildRewardsSummaryCard(context),
              ),
            );
          },
        ),
        if (hasCurrentFood) ...[
          const SizedBox(height: AppSpacing.lg),
          // 가격/소진 상태 신호 카드
          _buildStatusSignalCards(petSummary, state),
        ],
        
        const SizedBox(height: AppSpacing.lg),
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
        // Alerts preview (최대 2개) + "See all alerts" 링크
        const SizedBox(height: AppSpacing.lg),
        _buildAlertsPreview(context, state),
        SizedBox(height: DesignTokens.Spacing.screen), // 하단 여백
      ],
    );
  }

  /// Alerts preview 섹션 (최대 2개)
  Widget _buildAlertsPreview(BuildContext context, state) {
    // TODO: 실제 알림 데이터 연동
    // 임시로 빈 상태 또는 샘플 데이터 표시
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Alerts',
              style: DesignTypography.TextStyles.h3,
            ),
            TextButton(
              onPressed: () {
                context.go(RoutePaths.alerts);
              },
              child: Text(
                'See all alerts',
                style: DesignTypography.TextStyles.bodySecondary.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.Spacing.base),
        // TODO: 실제 알림 데이터 표시
        Text(
          'No alerts yet. Start tracking products to get price drop and stock alerts.',
          style: DesignTypography.TextStyles.bodySecondary,
        ),
      ],
    );
  }

  /// 상태 설명 문구
  Widget _buildStatusDescription(petSummary, state, bool hasCurrentFood) {
    final descriptionText = hasCurrentFood
        ? AppLocalizations.of(context)!.pet_managingPriceAndStatus
        : AppLocalizations.of(context)!.pet_registerCurrentFoodDescription;
    
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
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasCurrentFood 
                  ? AppLocalizations.of(context)!.pet_currentVsRecommendation 
                  : AppLocalizations.of(context)!.pet_findPerfectFood,
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
                    AppLocalizations.of(context)!.error_failedToLoad,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    state.error ?? AppLocalizations.of(context)!.error_somethingWentWrong,
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
                        AppLocalizations.of(context)!.action_tryAgain,
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
      return AppCard(
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
                AppLocalizations.of(context)!.home_findingPerfectFood(petSummary.name),
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
    
    // Rover 스타일: Recommendation CTA Card
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Find ${petName}\'s best match',
            style: DesignTypography.TextStyles.h3,
          ),
          SizedBox(height: DesignTokens.Spacing.sm),
          Text(
            'Personalized for allergies, age, and health needs.',
            style: DesignTypography.TextStyles.bodySecondary,
          ),
          SizedBox(height: DesignTokens.Spacing.base),
          
          // 빈 추천 결과 처리
          if (isEmptyResult) ...[
            _buildEmptyRecommendationState(context, recommendations?.message),
          ] else ...[
            // 추천 결과 미리보기 (있는 경우)
            if (hasRecommendations && topRecommendation != null) ...[
              _buildRecommendedProductCard(context, topRecommendation),
              SizedBox(height: DesignTokens.Spacing.base),
            ],
            
            // 액션 버튼
            PrimaryButton(
              text: state.hasRecommendationsForAction
                  ? 'Get recommendations again'
                  : 'Get recommendations',
              onPressed: () {
                _toggleRecommendation();
              },
              icon: !state.hasRecommendationsForAction
                  ? Icons.auto_awesome 
                  : Icons.refresh,
            ),
          ],
        ],
      ),
    );
  }

  /// 빈 추천 결과 Empty State
  Widget _buildEmptyRecommendationState(BuildContext context, String? message) {
    // TODO: flutter gen-l10n 실행 후 주석 해제
    // final l10n = AppLocalizations.of(context)!;
    return EmptyState(
      icon: Icons.search_off,
      // TODO: flutter gen-l10n 실행 후 주석 해제
      // title: l10n.emptyNoRecommendationsTitle,
      // message: message ?? l10n.emptyNoRecommendationsSubtitle,
      title: AppLocalizations.of(context)!.empty_noRecommendations_title,
      message: message ?? AppLocalizations.of(context)!.empty_noRecommendations_subtitle,
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
                    Formatters.currency(item.currentPrice / 100.0), // cents to dollars
                    style: DesignTypography.TextStyles.data.copyWith(
                      color: AppColors.primary,
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
      // Rover 스타일: Current Food CTA Card
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What\'s ${petSummary.name} eating right now?',
              style: DesignTypography.TextStyles.h3,
            ),
            SizedBox(height: DesignTokens.Spacing.sm),
            Text(
              'We\'ll compare ingredients and track the best price.',
              style: DesignTypography.TextStyles.bodySecondary,
            ),
            SizedBox(height: DesignTokens.Spacing.base),
            PrimaryButton(
              text: 'Add current food',
              onPressed: () {
                print('[HomeScreen] 🔘 "Add current food" 버튼 클릭');
                context.go(RoutePaths.market);
              },
            ),
          ],
        ),
      );
    }
    
    // 상태 A: 등록되어 있을 때
    return AppCard(
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
                AppLocalizations.of(context)!.pet_currentlyFeeding,
                style: AppTypography.caption.copyWith(
                  color: Colors.white, // 흰색 텍스트
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md), // 섹션 그룹 간격
            // 사료 정보 (실제 데이터로 교체 필요)
            // TODO: 현재 급여 사료 API 연동 후 실제 값으로 변경
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
                              AppLocalizations.of(context)!.price_currentLowest,
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
                          AppLocalizations.of(context)!.price_estimatedDepletion,
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
                      AppLocalizations.of(context)!.alert_priceAlertOn,
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
                      AppLocalizations.of(context)!.action_buyNow,
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
                  title: AppLocalizations.of(context)!.signal_currentFoodLowestPrice,
                  subtitle: AppLocalizations.of(context)!.signal_lowestIn30Days,
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
                  subtitle: AppLocalizations.of(context)!.signal_depletionWarning,
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
                  title: AppLocalizations.of(context)!.signal_healthConcern(petSummary.name, 'joint concerns'),
                  subtitle: AppLocalizations.of(context)!.signal_healthConcernSubtitle,
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
      return AppCard(
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
                AppLocalizations.of(context)!.home_findingPerfectFood(petSummary.name),
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
    
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg + AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.message_betterFoodAvailable(petSummary.name),
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
                AppLocalizations.of(context)!.action_compare,
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
    return AppCard(
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
                AppLocalizations.of(context)!.section_monthlyBenefits,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600, // 강조 낮춤
                  color: const Color(0xFF64748B), // 색상 낮춤
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md), // 섹션 그룹 간격
          _buildBenefitItem(AppLocalizations.of(context)!.benefit_firstPurchase),
          const SizedBox(height: AppSpacing.md), // 섹션 그룹 간격
          _buildBenefitItem(AppLocalizations.of(context)!.benefit_priceAlertMaintained),
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
