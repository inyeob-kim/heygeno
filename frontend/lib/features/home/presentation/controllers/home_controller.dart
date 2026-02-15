import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../../../data/models/recommendation_dto.dart';
import '../../../../data/models/recommendation_extensions.dart';
import '../../../../data/models/pet_summary_dto.dart';
import '../../../../domain/services/pet_service.dart';
import '../../../../domain/services/recommendation_service.dart';
import '../../../../domain/services/user_service.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/providers/pet_id_provider.dart';

/// 홈 화면 상태 타입 (A/B/C 분기)
enum HomeStateType {
  loading, // 로딩 중
  hasPet, // B: primary pet 존재 → 정상 홈
  noPet, // C: pet 없음 → Empty State
  error, // 에러 상태
}

class HomeState {
  final HomeStateType stateType;
  final PetSummaryDto? petSummary;
  final RecommendationResponseDto? recommendations;
  final bool isLoadingRecommendations;
  final String? error;
  // UPDATED: Dynamic recommendation UI to reduce reload fatigue
  final DateTime? lastRecommendedAt;
  final bool hasRecentRecommendation;
  final String? userNickname; // 유저 닉네임
  // 프로필 업데이트 감지
  final bool petProfileUpdated; // 프로필 최근 업데이트 여부
  final DateTime? petProfileUpdatedAt; // 업데이트 시각

  HomeState({
    HomeStateType? stateType,
    this.petSummary,
    this.recommendations,
    this.isLoadingRecommendations = false,
    this.error,
    this.lastRecommendedAt,
    this.hasRecentRecommendation = false,
    this.userNickname,
    this.petProfileUpdated = false,
    this.petProfileUpdatedAt,
  }) : stateType = stateType ?? HomeStateType.loading;

  bool get hasPet => stateType == HomeStateType.hasPet && petSummary != null;
  bool get isNoPet => stateType == HomeStateType.noPet;
  bool get isError => stateType == HomeStateType.error;
  bool get isLoading => stateType == HomeStateType.loading;
  bool get hasRecommendations => recommendations != null && recommendations!.items.isNotEmpty;

  // UPDATED: Dynamic recommendation UI to reduce reload fatigue - 동적 버튼 텍스트
  String get recommendationActionText {
    // 프로필 업데이트된 경우
    if (petProfileUpdated) {
      return "다시 추천 받기";
    }
    
    // 추천이 있는 경우
    if (hasRecommendations) {
      return "다시 추천 받기";
    }
    
    // 추천이 없는 경우
    return "지금 추천받기";
  }

  HomeState copyWith({
    HomeStateType? stateType,
    PetSummaryDto? petSummary,
    RecommendationResponseDto? recommendations,
    bool? isLoadingRecommendations,
    String? error,
    DateTime? lastRecommendedAt,
    bool? hasRecentRecommendation,
    String? userNickname,
    bool? petProfileUpdated,
    DateTime? petProfileUpdatedAt,
  }) {
    return HomeState(
      stateType: stateType ?? this.stateType,
      petSummary: petSummary ?? this.petSummary,
      recommendations: recommendations ?? this.recommendations,
      isLoadingRecommendations: isLoadingRecommendations ?? this.isLoadingRecommendations,
      error: error ?? this.error,
      lastRecommendedAt: lastRecommendedAt ?? this.lastRecommendedAt,
      hasRecentRecommendation: hasRecentRecommendation ?? this.hasRecentRecommendation,
      userNickname: userNickname ?? this.userNickname,
      petProfileUpdated: petProfileUpdated ?? this.petProfileUpdated,
      petProfileUpdatedAt: petProfileUpdatedAt ?? this.petProfileUpdatedAt,
    );
  }
}

class HomeController extends StateNotifier<HomeState> {
  final RecommendationService _recommendationService;
  final PetService _petService;
  final UserService _userService;
  final Ref _ref;

  HomeController(
    this._recommendationService,
    this._petService,
    this._userService,
    this._ref,
  ) : super(HomeState(stateType: HomeStateType.loading));

  /// 홈 화면 초기화 (primary pet 조회만, 추천은 버튼 클릭 시 로드)
  Future<void> initialize() async {
    state = state.copyWith(stateType: HomeStateType.loading);
    print('[HomeController] initialize() 시작');

    try {
      // 1. 먼저 사용자 정보 로드 (사용자가 있어야 pet을 불러올 수 있음)
      String? nickname;
      try {
        print('[HomeController] 사용자 정보 로드 시작');
        final user = await _userService.getCurrentUser();
        nickname = user.nickname;
        print('[HomeController] 사용자 정보 로드 성공: ${user.nickname}');
      } catch (e) {
        print('[HomeController] 사용자 정보 로드 실패: $e');
        // 사용자가 없으면 에러 상태로 설정
        state = state.copyWith(
          stateType: HomeStateType.error,
          error: '사용자 정보를 불러올 수 없습니다. 다시 시도해주세요.',
        );
        return;
      }

      // 2. 사용자가 확인되었으므로 해당 사용자의 Primary Pet 조회
      print('[HomeController] Primary Pet 조회 시작');
      final petSummary = await _petService.getPrimaryPetSummary();
      print('[HomeController] Primary Pet 조회 결과: ${petSummary != null ? "있음 (${petSummary.name})" : "없음"}');

      if (petSummary == null) {
        // C 상태: pet 없음 (사용자는 있음)
        state = state.copyWith(
          stateType: HomeStateType.noPet,
          petSummary: null,
          userNickname: nickname,
        );
        return;
      }

      // 3. 펫 전환 감지 (기존 펫과 다른 펫인 경우)
      final currentPetId = _ref.read(currentPetIdProvider);
      final isPetChanged = currentPetId != null && currentPetId != petSummary.petId;
      
      if (isPetChanged) {
        print('[HomeController] 🔄 펫 전환 감지: $currentPetId -> ${petSummary.petId}');
      }
      
      // 4. Pet ID를 provider에 저장
      _ref.read(currentPetIdProvider.notifier).state = petSummary.petId;

      // 5. B 상태: pet 존재 (추천은 버튼 클릭 시 로드)
      // 펫 전환 시 기존 추천 결과 초기화
      state = state.copyWith(
        stateType: HomeStateType.hasPet,
        petSummary: petSummary,
        isLoadingRecommendations: false,  // 초기에는 로딩하지 않음
        recommendations: isPetChanged ? null : state.recommendations,  // 펫 전환 시 추천 초기화
        hasRecentRecommendation: isPetChanged ? false : state.hasRecentRecommendation,
        lastRecommendedAt: isPetChanged ? null : state.lastRecommendedAt,
        userNickname: nickname,
      );
    } catch (e) {
      final failure = e is Exception
          ? handleException(e)
          : ServerFailure('펫 정보를 불러오는데 실패했습니다. 잠시 후 다시 시도해주세요.');
      state = state.copyWith(
        stateType: HomeStateType.error,
        error: failure.message,
      );
    }
  }

  /// 펫 프로필만 새로고침 (프로필 업데이트 후 호출)
  Future<void> refreshPetSummary() async {
    print('[HomeController] refreshPetSummary() 시작');
    
    try {
      final oldPetSummary = state.petSummary;
      final newPetSummary = await _petService.getPrimaryPetSummary();
      print('[HomeController] 펫 프로필 새로고침 결과: ${newPetSummary != null ? "있음 (${newPetSummary.name})" : "없음"}');
      
      if (newPetSummary == null) {
        state = state.copyWith(
          stateType: HomeStateType.noPet,
          petSummary: null,
        );
        return;
      }

      // 펫 ID 변경 감지 (다른 펫으로 전환된 경우)
      final isPetChanged = oldPetSummary != null && oldPetSummary.petId != newPetSummary.petId;
      
      // 프로필 변경 감지 (같은 펫의 프로필이 변경된 경우)
      bool isProfileUpdated = false;
      if (oldPetSummary != null && !isPetChanged) {
        isProfileUpdated = _petService.hasProfileChanged(oldPetSummary, newPetSummary);
        print('[HomeController] 프로필 변경 감지: $isProfileUpdated');
        if (isProfileUpdated) {
          print('[HomeController] 📋 변경된 항목 확인:');
          print('  - 체중: ${oldPetSummary.weightKg}kg -> ${newPetSummary.weightKg}kg');
          print('  - 중성화: ${oldPetSummary.isNeutered} -> ${newPetSummary.isNeutered}');
          print('  - 건강고민: ${oldPetSummary.healthConcerns} -> ${newPetSummary.healthConcerns}');
          print('  - 알레르기: ${oldPetSummary.foodAllergies} -> ${newPetSummary.foodAllergies}');
        }
      } else if (oldPetSummary == null) {
        // 첫 로드인 경우는 업데이트로 간주하지 않음
        print('[HomeController] 첫 로드: oldPetSummary가 null이므로 변경 감지 스킵');
      }
      
      if (isPetChanged && oldPetSummary != null) {
        print('[HomeController] 🔄 펫 전환 감지: ${oldPetSummary.name} -> ${newPetSummary.name}');
      }

      // Pet ID 업데이트
      _ref.read(currentPetIdProvider.notifier).state = newPetSummary.petId;
      
      // 펫 프로필 업데이트 및 추천 결과 초기화
      // (펫 전환 또는 프로필 변경 시 기존 추천은 부정확할 수 있음)
      state = state.copyWith(
        petSummary: newPetSummary,
        petProfileUpdated: isProfileUpdated,
        petProfileUpdatedAt: isProfileUpdated ? DateTime.now() : state.petProfileUpdatedAt,
        // 펫 전환 또는 프로필 변경 시 기존 추천 무효화 (중요!)
        recommendations: (isPetChanged || isProfileUpdated) ? null : state.recommendations,
        hasRecentRecommendation: (isPetChanged || isProfileUpdated) ? false : state.hasRecentRecommendation,
        lastRecommendedAt: (isPetChanged || isProfileUpdated) ? null : state.lastRecommendedAt,
      );
      print('[HomeController] 펫 프로필 새로고침 완료 (isProfileUpdated=$isProfileUpdated)');
    } catch (e) {
      debugPrint('refreshPetSummary error: $e');
      // 에러가 발생해도 기존 상태 유지
    }
  }


  /// 추천 데이터 로드
  // UPDATED: Dynamic recommendation UI to reduce reload fatigue - 캐싱 정보 처리 추가
  Future<void> _loadRecommendations(String petId, {bool force = false}) async {
    final startTime = DateTime.now();
    print('[HomeController] 📡 추천 데이터 로드 시작: petId=$petId, force=$force');
    state = state.copyWith(isLoadingRecommendations: true); // 로딩 상태 시작
    
    try {
      print('[HomeController] 📞 RecommendationService.getRecommendations() 호출: force=$force (force=true면 RAG 강제 실행)');
      // force=true면 캐시 무시하고 RAG 강제 실행
      final recommendations = await _recommendationService.getRecommendations(
        petId: petId,
        forceRefresh: force,
      );
      final duration = DateTime.now().difference(startTime);
      print('[HomeController] ✅ 추천 데이터 로드 완료: ${recommendations.items.length}개 상품, isCached=${recommendations.isCached}, 소요시간=${duration.inMilliseconds}ms');
      print('[HomeController] 📊 추천 상품 요약:');
      for (var i = 0; i < recommendations.items.length && i < 3; i++) {
        final item = recommendations.items[i];
        print('[HomeController]   ${i + 1}. ${item.product.brandName} ${item.product.productName} (점수: ${item.matchScore.toStringAsFixed(1)}, 안전: ${item.safetyScore.toStringAsFixed(1)}, 적합: ${item.fitnessScore.toStringAsFixed(1)})');
      }
      
      // UPDATED: Dynamic recommendation UI to reduce reload fatigue - 캐싱 정보 기반 상태 업데이트
      // extension을 사용하여 hasRecent 계산
      state = state.copyWith(
        recommendations: recommendations,
        isLoadingRecommendations: false,
        lastRecommendedAt: recommendations.lastRecommendedAt,
        hasRecentRecommendation: recommendations.hasRecentRecommendation,
        petProfileUpdated: false, // ★ 추천 성공 시 플래그 초기화
      );
      print('[HomeController] ✅ 상태 업데이트 완료: isLoadingRecommendations=false, hasRecentRecommendation=${recommendations.hasRecentRecommendation}, lastRecommendedAt=${recommendations.lastRecommendedAt}');
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      print('[HomeController] ❌ 추천 데이터 로드 실패: error=$e, 소요시간=${duration.inMilliseconds}ms');
      print('[HomeController] ❌ StackTrace: $stackTrace');
      final failure = e is Exception
          ? handleException(e)
          : ServerFailure('추천 상품을 불러오는데 실패했습니다. 잠시 후 다시 시도해주세요.');
      state = state.copyWith(
        isLoadingRecommendations: false,
        error: failure.message,
        // 추천 실패해도 홈은 표시 (pet은 있으므로)
      );
      print('[HomeController] ⚠️ 상태 업데이트: isLoadingRecommendations=false, error=${failure.message}');
    }
  }

  /// 추천 로드 (버튼 클릭 시 호출)
  // UPDATED: Dynamic recommendation UI to reduce reload fatigue - force 파라미터 추가
  Future<void> loadRecommendations({bool force = false}) async {
    print('[HomeController] 🎯 loadRecommendations() 호출됨: force=$force');
    final petSummary = state.petSummary;
    if (petSummary == null) {
      print('[HomeController] ⚠️ petSummary가 null입니다. 추천을 로드할 수 없습니다.');
      return;
    }
    
    // 이미 로딩 중이면 중복 호출 방지
    if (state.isLoadingRecommendations) {
      print('[HomeController] ⏸️ 이미 로딩 중입니다. 중복 호출 방지.');
      return;
    }
    
    // UPDATED: Dynamic recommendation UI to reduce reload fatigue - 최근 추천이 있고 force가 false면 스킵 가능
    if (!force && state.hasRecentRecommendation && state.hasRecommendations) {
      print('[HomeController] 💾 최근 추천이 있어서 API 호출 스킵 (force=false)');
      // 상태만 업데이트 (이미 recommendations가 있음)
      return;
    }
    
    print('[HomeController] ▶️ _loadRecommendations() 호출: petId=${petSummary.petId}, force=$force');
    await _loadRecommendations(petSummary.petId, force: force);
  }

  /// 추천 새로고침
  Future<void> refreshRecommendations() async {
    final petSummary = state.petSummary;
    if (petSummary != null) {
      await _loadRecommendations(petSummary.petId);
    }
  }
  
  /// 추천 결과 직접 설정 (애니메이션 화면에서 사용)
  void setRecommendations(RecommendationResponseDto recommendations) {
    // extension을 사용하여 hasRecent 계산
    state = state.copyWith(
      recommendations: recommendations,
      isLoadingRecommendations: false,
      lastRecommendedAt: recommendations.lastRecommendedAt,
      hasRecentRecommendation: recommendations.hasRecentRecommendation,
      petProfileUpdated: false, // ★ 추천 성공 시 플래그 초기화
    );
  }
  
  /// 추천 데이터 제거 (캐시 제거 후 호출)
  void clearRecommendations() {
    state = state.copyWith(
      recommendations: null,
      lastRecommendedAt: null,
      hasRecentRecommendation: false,
    );
  }
}

final homeControllerProvider =
    StateNotifierProvider<HomeController, HomeState>((ref) {
  final recommendationService = ref.watch(recommendationServiceProvider);
  final petService = ref.watch(petServiceProvider);
  final userService = ref.watch(userServiceProvider);
  return HomeController(recommendationService, petService, userService, ref);
});
