import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../ui/widgets/app_scaffold.dart';
import '../../../../../ui/widgets/app_header.dart';
import '../../../../../ui/widgets/card_container.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../core/widgets/loading.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../feed/ui/components/food_recommendation_card.dart';
import '../../../feed/ui/components/price_history_mini.dart';
import '../../../feed/ui/components/alert_rule_tile.dart';
import '../controllers/home_controller.dart';
import '../widgets/product_card.dart';
import '../widgets/today_empty_state.dart';

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
      ref.read(homeControllerProvider.notifier).loadRecommendations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeControllerProvider);

    return AppScaffold(
      appBar: const AppHeader(title: '오늘'),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, HomeState state) {
    if (state.isLoading) {
      return const LoadingWidget();
    }

    // 에러 상태 (서버/네트워크 오류)
    if (state.isError && state.error != null) {
      return EmptyStateWidget(
        title: '오류가 발생했습니다',
        description: state.error!,
        icon: Icons.error_outline,
        buttonText: '다시 시도',
        onButtonPressed: () {
          ref.read(homeControllerProvider.notifier).loadRecommendations();
        },
      );
    }

    // 프로필 없음 또는 데이터 없음 (중립 EmptyState)
    if (state.isNoProfile || !state.hasData) {
      return TodayEmptyState(
        onBrowseProducts: () {
          // TODO: 대표 사료 둘러보기 화면 연결
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('사료 둘러보기 기능 준비중')),
          );
        },
      );
    }

    final items = state.recommendations!.items;
    
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(homeControllerProvider.notifier).loadRecommendations();
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePaddingHorizontal),
        children: [
          // 샘플: 사료 추천 카드
          FoodRecommendationCard(
            brand: '로얄캐닌',
            name: '미니 어덜트 강아지 사료 3kg',
            currentPrice: 45000,
            diffPercent: -12.5,
            verdictLabel: '지금 사도 됨',
            isAlertOn: false,
            onToggleAlert: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('알림 설정 준비중')),
              );
            },
          ),
          const SizedBox(height: AppSpacing.gridGap),
          
          // 샘플: 가격 히스토리 미니
          PriceHistoryMini(
            lowest: 42000,
            avg: 48000,
            current: 45000,
          ),
          const SizedBox(height: AppSpacing.gridGap),
          
          // 샘플: 알림 규칙 타일
          CardContainer(
            child: Column(
              children: [
                AlertRuleTile(
                  title: '평균가 이하 알림',
                  description: '14일 평균가보다 낮아지면 알림',
                  enabled: true,
                  onChanged: (value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('알림 ${value ? "켜짐" : "꺼짐"}')),
                    );
                  },
                ),
                const Divider(height: 1),
                AlertRuleTile(
                  title: '최저가 갱신 알림',
                  description: '새로운 최저가가 기록되면 알림',
                  enabled: false,
                  onChanged: (value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('알림 ${value ? "켜짐" : "꺼짐"}')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.gridGap),
          
          // 우리 아이 추천 섹션
          _SectionCard(
            title: '우리 아이 추천',
            child: Column(
              children: items
                  .take(5)
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppSpacing.gridGap,
                      ),
                      child: ProductCard(item: item),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.gridGap),
          
          // 오늘 사도 되는 사료 섹션
          _SectionCard(
            title: '오늘 사도 되는 사료',
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Text(
                '준비중',
                style: AppTypography.body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // H3: 18px, letter-spacing: -0.2px
          Text(title, style: AppTypography.h3),
          const SizedBox(height: AppSpacing.gridGap),
          child,
        ],
      ),
    );
  }
}
