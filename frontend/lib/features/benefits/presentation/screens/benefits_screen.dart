import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../ui/widgets/figma_app_bar.dart';
import '../../../../../ui/widgets/figma_primary_button.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../core/widgets/loading.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../controllers/benefits_controller.dart';

/// 실제 API 데이터를 사용하는 Benefits Screen
class BenefitsScreen extends ConsumerStatefulWidget {
  const BenefitsScreen({super.key});

  @override
  ConsumerState<BenefitsScreen> createState() => _BenefitsScreenState();
}

class _BenefitsScreenState extends ConsumerState<BenefitsScreen> {
  @override
  void initState() {
    super.initState();
    // 화면 진입 시 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(benefitsControllerProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(benefitsControllerProvider);

    // 로딩 상태
    if (state.isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(child: LoadingWidget()),
      );
    }

    // 에러 상태
    if (state.error != null && state.missions.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: EmptyStateWidget(
          title: state.error ?? '오류가 발생했습니다',
          buttonText: '다시 시도',
          onButtonPressed: () => ref.read(benefitsControllerProvider.notifier).refresh(),
        ),
      );
    }

    final totalPoints = state.totalPoints;
    final earnedPoints = state.earnedPoints;
    final availablePoints = state.availablePoints;
    final missions = state.missions;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const FigmaAppBar(title: '혜택'),
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      // Hero Point Section
                      Row(
                        children: [
                          const Icon(
                            Icons.card_giftcard,
                            size: 24,
                            color: Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '내 포인트',
                            style: AppTypography.body.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${totalPoints.toLocaleString()}P',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${availablePoints.toLocaleString()}P 더 받을 수 있어요',
                        style: AppTypography.body.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Mission List
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '미션 완료하고 포인트 받기',
                            style: AppTypography.body.copyWith(
                              color: const Color(0xFF111827),
                            ),
                          ),
                          Text(
                            '${state.completedCount}/${missions.length}',
                            style: AppTypography.small.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...missions.map((mission) => _buildMissionCard(mission)),
                      const SizedBox(height: 32),
                      // Points Usage
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '포인트 사용 방법',
                              style: AppTypography.body.copyWith(
                                color: const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '100P = 100원 할인 (다음 구매 시 자동 적용)',
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionCard(MissionData mission) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: mission.completed
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(18),
        border: mission.completed
            ? Border.all(
                color: const Color(0xFF16A34A).withOpacity(0.2),
                width: 1,
              )
            : null,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: mission.completed
                      ? const Color(0xFF16A34A)
                      : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  mission.completed ? Icons.check_circle : Icons.flag,
                  size: 20,
                  color: mission.completed
                      ? Colors.white
                      : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.title,
                      style: AppTypography.body.copyWith(
                        color: mission.completed
                            ? const Color(0xFF6B7280)
                            : const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mission.description,
                      style: AppTypography.small.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '+${mission.reward}P',
                          style: AppTypography.body.copyWith(
                            color: mission.completed
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF2563EB),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (!mission.completed) ...[
                          const SizedBox(width: 8),
                          Text(
                            '· ${mission.current}/${mission.total} 완료',
                            style: AppTypography.small.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!mission.completed) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FigmaPrimaryButton(
                text: '시작하기',
                variant: ButtonVariant.small,
                onPressed: () {},
              ),
            ),
          ],
        ],
      ),
    );
  }
}

extension IntExtension on int {
  String toLocaleString() {
    return toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
}
