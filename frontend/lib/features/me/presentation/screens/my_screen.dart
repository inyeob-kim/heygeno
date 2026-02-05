import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../ui/widgets/figma_app_bar.dart';
import '../../../../../ui/widgets/match_score_badge.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../app/router/route_paths.dart';
import '../../../../../core/utils/price_formatter.dart';
import '../../../../../core/widgets/loading.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../controllers/my_controller.dart';

/// 실제 API 데이터를 사용하는 My Screen
class MyScreen extends ConsumerStatefulWidget {
  const MyScreen({super.key});

  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen> {
  @override
  void initState() {
    super.initState();
    // 화면 진입 시 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myControllerProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myControllerProvider);

    // 로딩 상태
    if (state.isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(child: LoadingWidget()),
      );
    }

    // 에러 상태
    if (state.error != null && state.petSummary == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: EmptyStateWidget(
          title: state.error ?? '오류가 발생했습니다',
          buttonText: '다시 시도',
          onButtonPressed: () => ref.read(myControllerProvider.notifier).refresh(),
        ),
      );
    }

    final petSummary = state.petSummary;
    final settings = [
      SettingData(
        icon: Icons.notifications,
        label: '알림 설정',
        hasToggle: true,
      ),
      SettingData(
        icon: Icons.lock,
        label: '개인정보 보호',
        hasChevron: true,
      ),
      SettingData(
        icon: Icons.help_outline,
        label: '도움말',
        hasChevron: true,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const FigmaAppBar(title: '마이'),
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      // Greeting
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  petSummary != null
                                      ? '안녕하세요, ${petSummary!.name}님'
                                      : '안녕하세요',
                                  style: AppTypography.h2.copyWith(
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '오늘도 건강한 하루 보내세요',
                                  style: AppTypography.small.copyWith(
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F8FA),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 20,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Health Summary Pill
                      if (petSummary != null) _buildHealthSummary(petSummary),
                      const SizedBox(height: 32),
                      // NEW: Recent Recommendation History
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '최근 추천 히스토리',
                            style: AppTypography.body.copyWith(
                              color: const Color(0xFF111827),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              '전체보기',
                              style: AppTypography.small.copyWith(
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (state.recentRecommendations.isNotEmpty)
                        ..._buildRecentRecommendations(state.recentRecommendations),
                      const SizedBox(height: 32),
                      // Profile Info List
                      if (petSummary != null) ...[
                        Text(
                          '프로필 정보',
                          style: AppTypography.small.copyWith(
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoItem(
                          '종류',
                          petSummary!.species == 'DOG' ? '강아지' : '고양이',
                        ),
                        const SizedBox(height: 4),
                        _buildInfoItem('나이', petSummary!.ageSummary),
                        const SizedBox(height: 4),
                        _buildInfoItem(
                          '체중',
                          '${petSummary!.weightKg.toStringAsFixed(1)}kg',
                        ),
                      ],
                      const SizedBox(height: 32),
                      // Notification Settings
                      Text(
                        '설정',
                        style: AppTypography.small.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...settings.map((setting) => _buildSettingItem(setting)),
                      const SizedBox(height: 32),
                      // Point Summary Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFEFF6FF),
                              Color(0xFFF7F8FA),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '사용 가능 포인트',
                                  style: AppTypography.body.copyWith(
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                                Text(
                                  '${state.totalPoints.toLocaleString()}P',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '다음 구매 시 할인받으세요',
                              style: AppTypography.small.copyWith(
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  '혜택 보기',
                                  style: AppTypography.body.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Logout
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            // TODO: 로그아웃 기능 구현
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.logout,
                                  size: 20,
                                  color: Color(0xFFEF4444),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '로그아웃',
                                  style: AppTypography.body.copyWith(
                                    color: const Color(0xFFEF4444),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthSummary(petSummary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF16A34A).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${petSummary.name}의 건강 리포트',
                  style: AppTypography.body.copyWith(
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: Color(0xFF6B7280),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                '🐕',
                style: TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${petSummary.species == 'DOG' ? '강아지' : '고양이'}, ${petSummary.ageSummary}',
                      style: AppTypography.body.copyWith(
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '체중 ${petSummary.weightKg.toStringAsFixed(1)}kg',
                      style: AppTypography.small.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '건강 상태',
                      style: AppTypography.small.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      petSummary.healthConcerns.isEmpty ? '양호' : '주의',
                      style: AppTypography.small.copyWith(
                        color: petSummary.healthConcerns.isEmpty
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFF59E0B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: petSummary.healthConcerns.isEmpty ? 0.85 : 0.6,
                    child: Container(
                      decoration: BoxDecoration(
                        color: petSummary.healthConcerns.isEmpty
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(4),
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

  List<Widget> _buildRecentRecommendations(List<RecentRecommendationData> recommendations) {
    return recommendations.map((recommendation) {
      return GestureDetector(
        onTap: () {
          context.push('/products/${recommendation.productId}');
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.image_outlined,
                  size: 32,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation.recommendedAt != null
                          ? '${recommendation.recommendedAt!.year}.${recommendation.recommendedAt!.month.toString().padLeft(2, '0')}.${recommendation.recommendedAt!.day.toString().padLeft(2, '0')}'
                          : '최근',
                      style: AppTypography.small.copyWith(
                        fontSize: 11,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recommendation.productName,
                      style: AppTypography.small.copyWith(
                        color: const Color(0xFF111827),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (recommendation.matchScore != null)
                          MatchScoreBadge(
                            score: recommendation.matchScore!,
                            size: MatchScoreSize.small,
                          ),
                        if (recommendation.matchScore != null)
                          const SizedBox(width: 8),
                        if (recommendation.price != null)
                          Text(
                            PriceFormatter.formatWithCurrency(recommendation.price!),
                            style: AppTypography.small.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: Color(0xFF6B7280),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildInfoItem(String label, String value) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTypography.body.copyWith(
                  color: const Color(0xFF6B7280),
                ),
              ),
              Text(
                value,
                style: AppTypography.body.copyWith(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(SettingData setting) {
    Color iconBgColor;
    Color iconColor;
    
    if (setting.icon == Icons.notifications) {
      iconBgColor = const Color(0xFFFEF3C7);
      iconColor = const Color(0xFFF59E0B);
    } else {
      iconBgColor = const Color(0xFFF7F8FA);
      iconColor = const Color(0xFF6B7280);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  setting.icon,
                  size: 20,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  setting.label,
                  style: AppTypography.body.copyWith(
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              if (setting.hasToggle)
                Container(
                  width: 44,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: CircleAvatar(
                        radius: 8,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                )
              else if (setting.hasChevron)
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Color(0xFF6B7280),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingData {
  final IconData icon;
  final String label;
  final String? value;
  final bool hasToggle;
  final bool hasChevron;

  SettingData({
    required this.icon,
    required this.label,
    this.value,
    this.hasToggle = false,
    this.hasChevron = false,
  });
}

extension IntExtension on int {
  String toLocaleString() {
    return toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
}
