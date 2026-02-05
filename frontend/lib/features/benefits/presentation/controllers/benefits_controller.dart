import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/error_handler.dart';

/// 미션 데이터 모델
class MissionData {
  final int id;
  final String title;
  final String description;
  final int reward;
  final bool completed;
  final int current;
  final int total;

  MissionData({
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
    required this.completed,
    required this.current,
    required this.total,
  });
}

/// 혜택 화면 상태
class BenefitsState {
  final bool isLoading;
  final String? error;
  final int totalPoints;
  final List<MissionData> missions;

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
    List<MissionData>? missions,
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
  BenefitsController() : super(BenefitsState()) {
    _initialize();
  }

  /// 초기화
  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // TODO: 백엔드에 포인트/미션 API 추가 시 실제 데이터 로드
      // 현재는 기본 미션 목록만 표시
      await Future.delayed(const Duration(milliseconds: 500));

      final missions = _generateDefaultMissions();

      state = state.copyWith(
        isLoading: false,
        totalPoints: 0, // TODO: 실제 포인트 API 추가 시 수정
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

  /// 기본 미션 목록 생성
  List<MissionData> _generateDefaultMissions() {
    return [
      MissionData(
        id: 1,
        title: '오늘 추천 사료 찜하기',
        description: '홈에서 추천된 사료를 찜 목록에 추가하세요',
        reward: 50,
        completed: false, // TODO: 실제 추적 데이터 확인
        current: 0,
        total: 1,
      ),
      MissionData(
        id: 2,
        title: '가격 알림 3개 설정',
        description: '관심 사료의 가격 변동을 실시간으로 확인하세요',
        reward: 100,
        completed: false, // TODO: 실제 알림 데이터 확인
        current: 0,
        total: 3,
      ),
      MissionData(
        id: 3,
        title: '펫 프로필 업데이트',
        description: '정확한 체중과 건강 정보를 입력해주세요',
        reward: 30,
        completed: false,
        current: 0,
        total: 1,
      ),
      MissionData(
        id: 4,
        title: '추천 제품 구매',
        description: '맞춤 추천 제품을 구매하고 포인트를 받으세요',
        reward: 200,
        completed: false,
        current: 0,
        total: 1,
      ),
      MissionData(
        id: 5,
        title: '리뷰 작성하기',
        description: '구매한 제품의 리뷰를 남겨주세요',
        reward: 150,
        completed: false,
        current: 0,
        total: 1,
      ),
    ];
  }

  /// 새로고침
  Future<void> refresh() async {
    await _initialize();
  }
}

final benefitsControllerProvider =
    StateNotifierProvider<BenefitsController, BenefitsState>((ref) {
  return BenefitsController();
});
