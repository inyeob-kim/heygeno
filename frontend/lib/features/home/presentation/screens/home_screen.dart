import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../ui/widgets/app_scaffold.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/router/route_paths.dart';
import '../../../../../core/widgets/loading.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../ui/widgets/app_buttons.dart';
import '../controllers/home_controller.dart';
import '../widgets/pet_card.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/progress_hint_card.dart';
import '../widgets/today_empty_state.dart';
import '../../../../core/widgets/debug_panel.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeControllerProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeControllerProvider);

    return AppScaffold(
      appBar: _buildAppBar(state),
      body: Column(
        children: [
          Expanded(child: _buildBody(context, state)),
          // 디버그 패널 (디버그 빌드에서만)
          const DebugPanel(),
        ],
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar(HomeState state) {
    if (state.hasPet && state.petSummary != null) {
      return AppBar(
        title: Text(
          '오늘, ${state.petSummary!.name}에게 딱 맞는 사료 🐾',
          style: AppTypography.h2,
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      );
    }
    return AppBar(
      title: Text('오늘', style: AppTypography.h2),
      elevation: 0,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildBody(BuildContext context, HomeState state) {
    // A) 로딩 중
    if (state.isLoading) {
      return const LoadingWidget();
    }

    // B) Primary Pet 존재 → 정상 홈
    if (state.hasPet) {
      return _buildHomeWithPet(context, state);
    }

    // C) Pet 없음 → Empty State
    if (state.isNoPet) {
      return _buildEmptyState(context);
    }

    // 에러 상태
    if (state.isError) {
      return EmptyStateWidget(
        title: '오류가 발생했습니다',
        description: state.error ?? '알 수 없는 오류',
        icon: Icons.error_outline,
        buttonText: '다시 시도',
        onButtonPressed: () {
          ref.read(homeControllerProvider.notifier).initialize();
        },
      );
    }

    return const SizedBox.shrink();
  }

  /// B 상태: Pet이 있는 정상 홈
  Widget _buildHomeWithPet(BuildContext context, HomeState state) {
    final petSummary = state.petSummary!;
    final topRecommendation = state.recommendations?.items.isNotEmpty == true
        ? state.recommendations!.items.first
        : null;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(homeControllerProvider.notifier).refreshRecommendations();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('방금 업데이트됨'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: ListView(
        padding: EdgeInsets.only(
          left: AppSpacing.pagePaddingHorizontal,
          right: AppSpacing.pagePaddingHorizontal,
          top: AppSpacing.pagePaddingHorizontal,
          bottom: AppSpacing.pagePaddingHorizontal + 80, // 디버그 패널 공간
        ),
        children: [
          // 내 아이 카드
          PetCard(pet: petSummary),
          const SizedBox(height: AppSpacing.gridGap),

          // 진행 힌트 카드 (로딩 중일 때만)
          if (state.isLoadingRecommendations) ...[
            const ProgressHintCard(),
            const SizedBox(height: AppSpacing.gridGap),
          ],

          // 추천 Top1 카드
          RecommendationCard(
            topRecommendation: topRecommendation,
            isLoading: state.isLoadingRecommendations,
            petName: petSummary.name,
          ),
          const SizedBox(height: AppSpacing.xl),

          // 메인 CTA: 맞춤 사료 보러가기
          AppPrimaryButton(
            text: '${petSummary.name} 맞춤 사료 보러가기',
            onPressed: () {
              if (topRecommendation != null) {
                context.push(
                  RoutePaths.productDetailPath(topRecommendation.product.id),
                );
              } else {
                // 추천이 없으면 추천 목록 화면으로 (TODO)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('추천 목록 화면 준비중')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// C 상태: Pet 없음 Empty State
  Widget _buildEmptyState(BuildContext context) {
    return TodayEmptyState(
      onAddProfile: () {
        context.push(RoutePaths.petProfile);
      },
    );
  }
}
