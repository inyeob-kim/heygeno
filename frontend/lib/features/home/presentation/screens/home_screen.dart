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
import '../widgets/icon_text_row.dart';
import '../widgets/status_signal_card.dart';
import '../widgets/pet_avatar.dart';
import '../widgets/pet_constants.dart';
import '../../../../../ui/widgets/top_bar.dart';

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

  @override
  void initState() {
    super.initState();
    
    // 화면 진입 시 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeControllerProvider.notifier).initialize();
    });
    
    // 스크롤 리스너 추가
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final isAtBottom = currentScroll >= maxScroll - 50; // 50px 여유
    
    if (isAtBottom != _isScrolledToBottom) {
      setState(() {
        _isScrolledToBottom = isAtBottom;
      });
    }
  }

  void _toggleRecommendation() {
    print('[HomeScreen] 🔘 "딱 맞는 사료 보기" 버튼 클릭');
    final state = ref.read(homeControllerProvider);
    final recommendations = state.recommendations;
    final topRecommendation = recommendations?.items.isNotEmpty == true
        ? recommendations!.items[0]
        : null;
    
    print('[HomeScreen] 현재 상태: recommendations=${recommendations?.items.length ?? 0}개, isLoading=${state.isLoadingRecommendations}, expanded=$_isRecommendationExpanded');
    
    // 추천이 없고 로딩 중이 아니면 추천 로드
    if (topRecommendation == null && !state.isLoadingRecommendations) {
      final petSummary = state.petSummary;
      if (petSummary != null) {
        print('[HomeScreen] ✅ 추천 로드 시작: petId=${petSummary.petId}, petName=${petSummary.name}');
        // 추천 로드 시작
        ref.read(homeControllerProvider.notifier).loadRecommendations();
        // 로딩 중이면 펼치지 않음
        return;
      } else {
        print('[HomeScreen] ⚠️ petSummary가 null입니다. 추천을 로드할 수 없습니다.');
      }
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
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent * 0.3,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeControllerProvider);
    
    // ref.listen을 build 내에서 사용하되, 리스너 내부에서 _hasAutoExpanded 플래그로 중복 실행 방지
    // (한 번만 자동 펼치기)
    ref.listen<HomeState>(homeControllerProvider, (previous, next) {
      // 이미 자동 펼침이 완료되었으면 리스너 로직 실행하지 않음
      if (_hasAutoExpanded) return;
      
      final recommendations = next.recommendations;
      final topRecommendation = recommendations?.items.isNotEmpty == true
          ? recommendations!.items[0]
          : null;
      
      // 추천이 로드 완료되고, 아직 펼치지 않았으면 자동 펼치기
      if (topRecommendation != null && 
          !next.isLoadingRecommendations && 
          !_isRecommendationExpanded) {
        _hasAutoExpanded = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isRecommendationExpanded = true;
            });
            // 스크롤 위치 조정
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent * 0.3,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          }
        });
      }
    });

    // 로딩 상태
    if (state.isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
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
        backgroundColor: Colors.white,
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 고정 탭 (알림 아이콘 포함)
            const TopBar(title: '헤이제노'),
            // 스크롤 가능한 콘텐츠
            Expanded(
              child: CupertinoScrollbar(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(), // iOS 스타일 바운스
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.md),
                        // 1️⃣ 펫 선택 + 상태 요약 (카드) - 이미 애니메이션 포함
                        _buildPetSummaryHeader(context, petSummary, state),
                        // 홈 콘텐츠 - 애니메이션 포함
                        _buildHomeContent(context, petSummary, state, topRecommendation),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Container(
                    color: const Color(0xFFF7F8FA),
                    child: const Center(
                      child: Icon(Icons.image_outlined, size: 64, color: Color(0xFF6B7280)),
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
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: AppSpacing.sm), // 요소 간
          Text(
            product.productName,
            style: AppTypography.h2.copyWith(
              color: const Color(0xFF111827),
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
                  color: Color(0xFF111827),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: AppSpacing.sm), // 텍스트/아이콘 간격
              // 최저가 Chip
              if (recommendationItem.isNewLow)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '최저가',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
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
              color: const Color(0xFF6B7280),
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
                        backgroundColor: AppColors.petGreen, // 상태/안심용
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
          backgroundColor: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단: 체크 아이콘 + 점수 (애니메이션)
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 24,
                    color: AppColors.petGreen, // 상태/안심용
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
                          color: Color(0xFF111827),
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
    // 나이 단계 한글 변환
    final ageStageText = PetConstants.getAgeStageText(petSummary.ageStage);
    
    // 건강 고민 1~2개만 표시
    final healthConcerns = petSummary.healthConcerns ?? [];
    final displayConcerns = healthConcerns.take(2).toList();
    
    // 중성화 여부 텍스트
    String? neuteredText;
    if (petSummary.isNeutered != null) {
      neuteredText = petSummary.isNeutered == true ? '중성화 완료' : '중성화 안함';
    }
    
    // 건강 고민 텍스트 생성 (최대 2개, 초과는 "외 N"으로 표시)
    String healthConcernsText = '';
    if (displayConcerns.isNotEmpty) {
      final concernNames = displayConcerns.map((c) => PetConstants.healthConcernNames[c] ?? c).toList();
      if (healthConcerns.length > 2) {
        healthConcernsText = '${concernNames.join('/')} 외 ${healthConcerns.length - 2}';
      } else {
        healthConcernsText = concernNames.join('/');
      }
    }
    
    // 서브텍스트 조합: {weight_kg}kg · {health_concerns} · {neutered}
    final List<String> subTexts = [];
    if (petSummary.weightKg != null) {
      subTexts.add('${petSummary.weightKg.toStringAsFixed(1)}kg');
    }
    if (healthConcernsText.isNotEmpty) {
      subTexts.add(healthConcernsText);
    }
    if (neuteredText != null) {
      subTexts.add(neuteredText);
    }
    final subText = subTexts.join(' · ');
    
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
              child: Row(
                children: [
                  // 왼쪽: 원형 아바타 (iOS 스타일)
                  PetAvatar(species: petSummary.species),
                  const SizedBox(width: AppSpacing.sm),
                  // 가운데: 이름 + 서브텍스트
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          petSummary.name,
                          style: AppTypography.h3.copyWith(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (subText.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            subText,
                            style: AppTypography.small.copyWith(
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ] else if (ageStageText != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            ageStageText,
                            style: AppTypography.small.copyWith(
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // 오른쪽: chevron (iOS 스타일)
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFCBD5E1),
                    size: 18,
                  ),
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
                          color: AppColors.petGreen, // 상태/안심용
                          borderRadius: BorderRadius.circular(AppRadius.md),
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
                    color: AppColors.petGreen, // 상태/안심용
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          // 미등록: '지금 등록하기' 버튼
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                print('[HomeScreen] 🔘 바텀시트 "지금 등록하기" 버튼 클릭');
                Navigator.of(context).pop(); // 바텀시트 닫기
                // 마켓 화면으로 이동 (사료 선택)
                context.go('/market');
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md + 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                side: const BorderSide(color: Color(0xFF16A34A)),
              ),
              child: Text(
                '지금 등록하기',
                style: AppTypography.button.copyWith(
                  color: const Color(0xFF16A34A),
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
    final healthConcerns = petSummary.healthConcerns ?? [];
    
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
        if (healthConcerns.isEmpty) ...[
          Text(
            '특이사항 없음',
            style: AppTypography.body.copyWith(
              color: const Color(0xFF6B7280),
            ),
          ),
        ] else ...[
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: healthConcerns.asMap().entries.map((entry) {
              final index = entry.key;
              final concern = entry.value;
              final concernName = PetConstants.healthConcernNames[concern] ?? concern;
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: (200 + (index * 50)).toInt()),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          concernName,
                          style: AppTypography.small.copyWith(
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  /// 알레르기 요약 섹션 (iOS 스타일)
  Widget _buildAllergiesSection(petSummary) {
    final foodAllergies = petSummary.foodAllergies ?? [];
    final otherAllergies = petSummary.otherAllergies;
    
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
        if (foodAllergies.isEmpty && otherAllergies == null) ...[
          Text(
            '알레르기 없음',
            style: AppTypography.body.copyWith(
              color: const Color(0xFF6B7280),
            ),
          ),
        ] else ...[
          if (foodAllergies.isNotEmpty) ...[
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: foodAllergies.asMap().entries.map((entry) {
                final index = entry.key;
                final allergen = entry.value;
                final allergenName = PetConstants.allergenNames[allergen] ?? allergen;
                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: (200 + (index * 50)).toInt()),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.scale(
                        scale: 0.8 + (0.2 * value),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            allergenName,
                            style: AppTypography.small.copyWith(
                              color: const Color(0xFF111827),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
            if (otherAllergies != null) const SizedBox(height: AppSpacing.sm),
          ],
          if (otherAllergies != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Color(0xFFF97316)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      otherAllergies,
                      style: AppTypography.small.copyWith(
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
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
        if (hasCurrentFood) ...[
          const SizedBox(height: AppSpacing.lg),
          // 가격/소진 상태 신호 카드
          _buildStatusSignalCards(petSummary, state),
          const SizedBox(height: AppSpacing.lg),
          // 추천 카드 (조건 충족 시만 노출)
          if (_shouldShowRecommendationCard(petSummary, state, topRecommendation))
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
        const SizedBox(height: AppSpacing.xl * 4), // 하단 여백
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
  bool _shouldShowRecommendationCard(petSummary, state, topRecommendation) {
    // 현재 급여 사료가 등록되어 있어야 함
    final hasCurrentFood = false; // TODO: 실제 값으로 변경
    
    if (!hasCurrentFood) {
      return false; // 미등록 시 추천 카드 숨김
    }
    
    // 추천 카드 표시 조건:
    // 1. 나이 단계 변경 감지 (TODO: 이전 나이 단계와 비교)
    // 2. 건강 고민 변경 감지 (TODO: 이전 건강 고민과 비교)
    // 3. 안전성 점수 낮음 (TODO: 현재 사료의 안전성 점수 확인)
    // 4. 추천이 이미 로드되어 있고 표시 가능한 경우
    
    // 임시로 추천이 있고 펼쳐진 경우만 표시
    if (topRecommendation != null && _isRecommendationExpanded) {
      return true;
    }
    
    // TODO: 실제 조건 확인 로직 구현
    // 예시:
    // final hasAgeStageChanged = _checkAgeStageChanged(petSummary);
    // final hasHealthConcernsChanged = _checkHealthConcernsChanged(petSummary);
    // final hasLowSafetyScore = _checkLowSafetyScore(petSummary);
    // return hasAgeStageChanged || hasHealthConcernsChanged || hasLowSafetyScore;
    
    return false;
  }

  /// 추천 카드 위젯
  Widget _buildRecommendationCard(
    BuildContext context,
    petSummary,
    state,
    topRecommendation,
  ) {
    if (state.isLoadingRecommendations) {
      return CardContainer(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Lottie.asset(
              'assets/animations/paw_loading.json',
              width: 60,
              height: 60,
              fit: BoxFit.contain,
              repeat: true,
              animate: true,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '${petSummary.name}에게 딱 맞는 사료 찾는 중...',
              style: AppTypography.body.copyWith(
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }
    
    if (topRecommendation == null) {
      return const SizedBox.shrink();
    }
    
    return CardContainer(
      isHomeStyle: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '지금 먹는 사료보다\n${petSummary.name}에게 더 잘 맞는 사료가 있어요',
            style: AppTypography.h3.copyWith(
              color: const Color(0xFF0F172A),
              height: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.lg), // 카드 간
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              onPressed: () {
                // 추천 상세 보기
                _toggleRecommendation();
              },
              color: Colors.transparent,
              padding: EdgeInsets.zero,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.petGreen, // 상태/안심용
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  '비교해보기',
                  style: AppTypography.button.copyWith(
                    color: AppColors.primaryBlue, // 결정/비교용
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
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
                color: const Color(0xFF0F172A),
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
              height: 48,
              child: CupertinoButton(
                onPressed: () {
                  print('[HomeScreen] 🔘 "지금 먹는 사료 등록하기" 버튼 클릭');
                  // 마켓 화면으로 이동 (사료 선택)
                  context.go('/market');
                },
                color: AppColors.petGreen, // 상태/안심용
                borderRadius: BorderRadius.circular(AppRadius.md),
                padding: EdgeInsets.zero,
                child: Text(
                  '지금 먹는 사료 등록하기',
                  style: AppTypography.button.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
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
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
              decoration: BoxDecoration(
                color: AppColors.petGreen.withOpacity(0.1), // 상태/안심용
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.petGreen, // 상태/안심용
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm), // 텍스트/아이콘 간격
                  Text(
                    '현재 급여 중',
                    style: AppTypography.small.copyWith(
                      color: AppColors.petGreen, // 상태/안심용
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md), // 섹션 그룹 간격
            // 사료 정보
            Text(
              '로얄캐닌 미니 어덜트 3kg', // TODO: 실제 데이터
              style: AppTypography.h2.copyWith(
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
            const SizedBox(height: AppSpacing.md), // 섹션 그룹 간격
            // 가격 정보 카드
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.petGreen.withOpacity(0.1), // 상태/안심용
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
                          color: AppColors.petGreen, // 상태/안심용
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
                                color: const Color(0xFF0F172A),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppColors.petGreen, // 상태/안심용
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
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(
                      CupertinoIcons.clock,
                      size: 20,
                      color: Color(0xFFF97316),
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
                                color: const Color(0xFF0F172A),
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
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      side: const BorderSide(
                        color: AppColors.petGreen, // 상태/안심용
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '가격 알림 ON',
                      style: AppTypography.button.copyWith(
                        color: AppColors.petGreen, // 상태/안심용
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
                      backgroundColor: AppColors.petGreen, // 상태/안심용
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md + 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
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
                  backgroundColor: const Color(0xFFEFF6FF),
                  iconColor: const Color(0xFF2563EB),
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
              color: const Color(0xFF0F172A),
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
        child: Column(
          children: [
            Lottie.asset(
              'assets/animations/paw_loading.json',
              width: 60,
              height: 60,
              fit: BoxFit.contain,
              repeat: true,
              animate: true,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '${petSummary.name}에게 딱 맞는 사료 찾는 중...',
              style: AppTypography.body.copyWith(
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
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
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                side: const BorderSide(color: Color(0xFF16A34A)),
              ),
              child: Text(
                '비교해보기',
                style: AppTypography.button.copyWith(
                  color: const Color(0xFF16A34A),
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
            color: const Color(0xFF16A34A), // 초록색
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.petGreen.withOpacity(0.3), // 상태/안심용
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
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
