import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../domain/services/mission_service.dart';
import '../../../../data/models/mission_dto.dart';

/// 혜택 화면 상태
class BenefitsState {
  final bool isLoading;
  final String? error;
  final int totalPoints;
  final List<MissionDto> missions;

  const BenefitsState({
    this.isLoading = false,
    this.error,
    this.totalPoints = 0,
    this.missions = const [],
  });

  BenefitsState copyWith({
    bool? isLoading,
    String? error,
    int? totalPoints,
    List<MissionDto>? missions,
  }) {
    return BenefitsState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      totalPoints: totalPoints ?? this.totalPoints,
      missions: missions ?? this.missions,
    );
  }

  /// 완료된 미션 개수
  int get completedCount => missions.where((m) => m.completed).length;

  /// 획득한 포인트
  int get earnedPoints => missions
      .where((m) => m.completed)
      .fold(0, (sum, m) => sum + m.reward);

  /// 획득 가능한 포인트
  int get availablePoints => missions
      .where((m) => !m.completed)
      .fold(0, (sum, m) => sum + m.reward);
}

/// 혜택 화면 컨트롤러
/// 단일 책임: 포인트 및 미션 데이터 관리
class BenefitsController extends StateNotifier<BenefitsState> {
  final MissionService _missionService;

  BenefitsController(this._missionService) : super(BenefitsState()) {
    _initialize();
  }

  /// 초기화
  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 미션 목록과 포인트 잔액을 동시에 로드
      final results = await Future.wait([
        _missionService.getMissions(),
        _missionService.getPointBalance(),
      ]);

      final missions = results[0] as List<MissionDto>;
      final balance = results[1] as int;

      state = state.copyWith(
        isLoading: false,
        totalPoints: balance,
        missions: missions,
      );
    } catch (e) {
      final failure = e is Exception
          ? handleException(e)
          : ServerFailure('혜택 데이터를 불러오는데 실패했습니다: ${e.toString()}');
      state = state.copyWith(
        isLoading: false,
        error: failure.message,
      );
    }
  }

  /// 미션 보상 받기
  Future<void> claimReward(String campaignId) async {
    try {
      await _missionService.claimReward(campaignId);
      // 보상 받기 성공 시 데이터 새로고침
      await _initialize();
    } catch (e) {
      final failure = e is Exception
          ? handleException(e)
          : ServerFailure('보상을 받는데 실패했습니다: ${e.toString()}');
      state = state.copyWith(error: failure.message);
    }
  }

  /// 새로고침
  Future<void> refresh() async {
    await _initialize();
  }
}

final benefitsControllerProvider =
    StateNotifierProvider<BenefitsController, BenefitsState>((ref) {
  final missionService = ref.watch(missionServiceProvider);
  return BenefitsController(missionService);
});
