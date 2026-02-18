import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../../../data/models/recommendation_dto.dart';
import '../../../../data/models/recommendation_extensions.dart';
import '../../../../data/models/pet_summary_dto.dart';
import '../../../../data/models/campaign_dto.dart';
import '../../../../domain/services/pet_service.dart';
import '../../../../domain/services/recommendation_service.dart';
import '../../../../domain/services/user_service.dart';
import '../../../../domain/services/campaign_service.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/providers/pet_id_provider.dart';
import '../../../../core/providers/active_pet_context_provider.dart';

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
    // 프로필 업데이트 감지 (revision 기반)
    final int profileRevision; // 프로필 변경 버전 (증가할수록 최신)
    // 캠페인
    final List<CampaignDto>? homeModalCampaigns; // 홈 모달 캠페인 목록
    final List<CampaignDto>? homeBannerCampaigns; // 홈 배너 캠페인 목록
    final bool isLoadingCampaigns; // 캠페인 로딩 중

  HomeState({
    HomeStateType? stateType,
    this.petSummary,
    this.recommendations,
    this.isLoadingRecommendations = false,
    this.error,
    this.lastRecommendedAt,
    this.hasRecentRecommendation = false,
    this.userNickname,
    this.profileRevision = 0,
    this.homeModalCampaigns,
    this.homeBannerCampaigns,
    this.isLoadingCampaigns = false,
  }) : stateType = stateType ?? HomeStateType.loading;

  bool get hasPet => stateType == HomeStateType.hasPet && petSummary != null;
  bool get isNoPet => stateType == HomeStateType.noPet;
  bool get isError => stateType == HomeStateType.error;
  bool get isLoading => stateType == HomeStateType.loading;
  bool get hasRecommendations => recommendations != null && recommendations!.items.isNotEmpty;

  // UPDATED: Dynamic recommendation UI to reduce reload fatigue - 동적 버튼 텍스트
  String get recommendationActionText {
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
    int? profileRevision,
    List<CampaignDto>? homeModalCampaigns,
    List<CampaignDto>? homeBannerCampaigns,
    bool? isLoadingCampaigns,
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
      profileRevision: profileRevision ?? this.profileRevision,
      homeModalCampaigns: homeModalCampaigns ?? this.homeModalCampaigns,
      homeBannerCampaigns: homeBannerCampaigns ?? this.homeBannerCampaigns,
      isLoadingCampaigns: isLoadingCampaigns ?? this.isLoadingCampaigns,
    );
  }
}

class HomeController extends StateNotifier<HomeState> {
  final RecommendationService _recommendationService;
  final PetService _petService;
  final UserService _userService;
  final CampaignService _campaignService;
  final Ref _ref;

  HomeController(
    this._recommendationService,
    this._petService,
    this._userService,
    this._campaignService,
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
      final activeContext = _ref.read(activePetContextProvider);
      final isPetChanged = (currentPetId != null && currentPetId != petSummary.petId) ||
                          (activeContext.petId != null && activeContext.petId != petSummary.petId);
      
      if (isPetChanged) {
        print('[HomeController] 🔄 펫 전환 감지: $currentPetId -> ${petSummary.petId}');
      }
      
      // 4. Pet ID를 provider에 저장 (하위 호환성)
      _ref.read(currentPetIdProvider.notifier).state = petSummary.petId;

      // 4-1. ActivePetContext 업데이트 (전역 단일 상태)
      _ref.read(activePetContextProvider.notifier).setPet(
        petId: petSummary.petId,
        petSummary: petSummary,
        initialRevision: isPetChanged ? 0 : state.profileRevision,
      );

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
        profileRevision: isPetChanged ? 0 : state.profileRevision, // ActivePetContext와 동기화
      );
      
      // 홈 모달 및 배너 캠페인 로드
      _loadHomeModalCampaigns();
      _loadHomeBannerCampaigns();
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
    print('[HomeController] 🔄 refreshPetSummary() 시작');
    
    try {
      // 1. 서버에서 항상 최신 petSummary 받아오기
      final newSummary = await _petService.getPrimaryPetSummary();
      
      if (newSummary == null) {
        print('[HomeController] ⚠️ 펫 프로필이 없음 - noPet 상태로 변경');
        state = state.copyWith(
          stateType: HomeStateType.noPet,
          petSummary: null,
        );
        _ref.read(activePetContextProvider.notifier).clearPet();
        return;
      }
      
      print('[HomeController] 📡 API 호출 완료');
      print('[HomeController]   - 새 summary: weight=${newSummary.weightKg}kg, concerns=${newSummary.healthConcerns.length}개, allergies=${newSummary.foodAllergies.length}개');
      print('[HomeController]   - 새 summary 상세: weight=${newSummary.weightKg}, concerns=${newSummary.healthConcerns}, allergies=${newSummary.foodAllergies}');
      
      // 2. updatePetSummary() 전에 현재 상태 읽기 (비교용 - 이전 상태 캡처)
      final beforeUpdate = _ref.read(activePetContextProvider);
      final oldActiveSummary = beforeUpdate.petSummary;
      final oldPetId = beforeUpdate.petId;
      final oldRevision = beforeUpdate.profileRevision;
      
      // activePetContext.petSummary가 null이면 HomeState.petSummary를 사용 (대체 비교 기준)
      final oldSummary = oldActiveSummary ?? state.petSummary;
      
      print('[HomeController] 📊 업데이트 전 상태:');
      print('[HomeController]   - activePetContext.petId: $oldPetId');
      print('[HomeController]   - activePetContext.revision: $oldRevision');
      print('[HomeController]   - activePetContext.petSummary: ${oldActiveSummary != null ? "있음" : "null"}');
      print('[HomeController]   - HomeState.petSummary: ${state.petSummary != null ? "있음" : "null"}');
      if (oldSummary != null) {
        print('[HomeController]   - 이전 summary (비교용): weight=${oldSummary.weightKg}kg, concerns=${oldSummary.healthConcerns}, allergies=${oldSummary.foodAllergies}');
      } else {
        print('[HomeController]   - 이전 summary (비교용): null');
      }
      
      // 3. 먼저 summary를 무조건 업데이트 (null 방지 + 변경 추적 가능)
      print('[HomeController] 🔄 updatePetSummary() 호출 - petSummary 먼저 업데이트');
      _ref.read(activePetContextProvider.notifier).updatePetSummary(newSummary);
      
      // 4. 펫 ID 변경 감지 (다른 펫으로 전환된 경우)
      final isPetChanged = oldPetId != null && oldPetId != newSummary.petId;
      if (isPetChanged) {
        print('[HomeController] 🔄 펫 전환 감지: $oldPetId -> ${newSummary.petId}');
      }
      
      // 5. 프로필 변경 감지: 이전 summary(oldSummary)와 새 summary(newSummary) 비교
      bool isProfileChanged = false;
      
      if (isPetChanged) {
        print('[HomeController] ℹ️ 펫 전환이므로 프로필 변경 감지 스킵');
      } else if (oldSummary != null && oldSummary.petId == newSummary.petId) {
        // 같은 펫의 프로필이 변경되었는지 확인 (oldSummary가 있는 경우)
        print('[HomeController] 🔍 프로필 변경 감지 시작 (같은 펫: ${newSummary.petId}, oldSummary 있음)');
        isProfileChanged = _hasProfileChanged(oldSummary, newSummary);
        
        if (isProfileChanged) {
          print('[HomeController] 🔥 프로필 변경 감지됨! → revision 증가 필요');
        } else {
          print('[HomeController] ✅ 프로필 변경 없음 (모든 필드 동일)');
        }
      } else if (oldSummary == null && oldPetId != null && oldPetId == newSummary.petId) {
        // oldSummary가 null이지만 oldPetId가 있고 newSummary.petId와 같다면
        // → 프로필 업데이트 후 refreshPetSummary()가 호출된 경우로 간주
        print('[HomeController] 🔍 프로필 변경 감지 시작 (같은 펫: ${newSummary.petId}, oldSummary null이지만 oldPetId 있음)');
        print('[HomeController]   - oldSummary가 null이지만 oldPetId($oldPetId)와 newPetId(${newSummary.petId})가 같음');
        print('[HomeController]   - 프로필 업데이트 후 refreshPetSummary() 호출로 간주 → revision 증가');
        isProfileChanged = true;
      } else if (oldSummary == null && oldPetId == null) {
        // oldSummary도 null이고 oldPetId도 null → 첫 설정
        print('[HomeController] ⚠️ 이전 summary와 petId가 모두 null → 첫 설정으로 간주 (revision 증가 스킵)');
      } else if (oldSummary != null && oldSummary.petId != newSummary.petId) {
        print('[HomeController] ⚠️ petId 불일치: ${oldSummary.petId} != ${newSummary.petId}');
      } else {
        print('[HomeController] ⚠️ 예상치 못한 상태: oldSummary=${oldSummary != null ? "있음" : "null"}, oldPetId=$oldPetId, newPetId=${newSummary.petId}');
      }
      
      // 7. 프로필 변경이 감지되면 반드시 updateProfile() 호출하여 revision 증가
      if (isProfileChanged) {
        print('[HomeController] 🔥 프로필 변경 감지됨! revision 증가 트리거');
        print('[HomeController]   - 이전 revision: $oldRevision');
        _ref.read(activePetContextProvider.notifier).updateProfile(
          petId: newSummary.petId,
          petSummary: newSummary,
        );
        final afterRevision = _ref.read(activePetContextProvider).profileRevision;
        print('[HomeController]   - 새 revision: $afterRevision');
        print('[HomeController]   - revision 증가: $oldRevision → $afterRevision');
      }
      
      // 8. Pet ID 업데이트 (하위 호환성)
      print('[HomeController] 🔄 currentPetIdProvider 업데이트: ${newSummary.petId}');
      _ref.read(currentPetIdProvider.notifier).state = newSummary.petId;
      
      // 9. ActivePetContext 최종 업데이트 (petId 등 나머지 상태 동기화)
      if (isPetChanged) {
        print('[HomeController] 🔄 ActivePetContext.setPet() 호출 (펫 전환)');
        _ref.read(activePetContextProvider.notifier).setPet(
          petId: newSummary.petId,
          petSummary: newSummary,
          initialRevision: 0,
        );
      } else {
        // 프로필 변경이 있으면 이미 updateProfile()에서 처리되었으므로 setPet()은 revision만 동기화
        print('[HomeController] ℹ️ ActivePetContext.setPet() 호출 (프로필 변경: ${isProfileChanged ? "있음" : "없음"})');
        _ref.read(activePetContextProvider.notifier).setPet(
          petId: newSummary.petId,
          petSummary: newSummary,
          initialRevision: _ref.read(activePetContextProvider).profileRevision,
        );
      }
      
      // 10. HomeState 업데이트 (activePetContext와 동기화)
      final shouldIncrementRevision = isPetChanged || isProfileChanged;
      final finalContext = _ref.read(activePetContextProvider);
      final newRevision = finalContext.profileRevision;
      
      print('[HomeController] 📝 HomeState 업데이트 시작');
      print('[HomeController]   - isPetChanged: $isPetChanged');
      print('[HomeController]   - isProfileChanged: $isProfileChanged');
      print('[HomeController]   - profileRevision: ${state.profileRevision} -> $newRevision');
      
      state = state.copyWith(
        petSummary: newSummary,
        profileRevision: newRevision,
        // 펫 전환 또는 프로필 변경 시 기존 추천 무효화 (중요!)
        recommendations: shouldIncrementRevision ? null : state.recommendations,
        hasRecentRecommendation: shouldIncrementRevision ? false : state.hasRecentRecommendation,
        lastRecommendedAt: shouldIncrementRevision ? null : state.lastRecommendedAt,
      );
      
      print('[HomeController] ✅ 펫 프로필 새로고침 완료');
      print('[HomeController]   - 최종 petId: ${state.petSummary?.petId}');
      print('[HomeController]   - 최종 petName: ${state.petSummary?.name}');
      print('[HomeController]   - 최종 profileRevision: ${state.profileRevision}');
      print('[HomeController]   - 최종 activePetContext.revision: $newRevision');
    } catch (e) {
      debugPrint('refreshPetSummary error: $e');
      // 에러가 발생해도 기존 상태 유지
    }
  }


  /// 프로필 변경 감지 (weight_kg, health_concerns, food_allergies 등 비교)
  /// 
  /// DeepCollectionEquality 대신 직접 비교 (순서 무관하게 리스트 비교)
  bool _hasProfileChanged(PetSummaryDto oldPet, PetSummaryDto newPet) {
    // 체중 비교 (0.1kg 이상 차이)
    if ((oldPet.weightKg - newPet.weightKg).abs() > 0.1) {
      print('[HomeController]   - 체중 변경 감지: ${oldPet.weightKg}kg -> ${newPet.weightKg}kg');
      return true;
    }
    
    // 건강 고민 리스트 비교 (순서 무관하게 비교)
    if (!_listEqualsUnordered(oldPet.healthConcerns, newPet.healthConcerns)) {
      print('[HomeController]   - 건강고민 변경 감지: ${oldPet.healthConcerns} -> ${newPet.healthConcerns}');
      return true;
    }
    
    // 음식 알레르기 리스트 비교 (순서 무관하게 비교)
    if (!_listEqualsUnordered(oldPet.foodAllergies, newPet.foodAllergies)) {
      print('[HomeController]   - 알레르기 변경 감지: ${oldPet.foodAllergies} -> ${newPet.foodAllergies}');
      return true;
    }
    
    // 중성화 여부 비교
    if (oldPet.isNeutered != newPet.isNeutered) {
      print('[HomeController]   - 중성화 변경 감지: ${oldPet.isNeutered} -> ${newPet.isNeutered}');
      return true;
    }
    
    // 나이 단계 비교
    if (oldPet.ageStage != newPet.ageStage) {
      print('[HomeController]   - 나이 단계 변경 감지: ${oldPet.ageStage} -> ${newPet.ageStage}');
      return true;
    }
    
    // 나이 개월 비교 (6개월 단위 변화 감지)
    final oldAgeMonths = oldPet.ageMonths;
    final newAgeMonths = newPet.ageMonths;
    if (oldAgeMonths != null && newAgeMonths != null) {
      final oldAgeStage = oldAgeMonths ~/ 6;
      final newAgeStage = newAgeMonths ~/ 6;
      if (oldAgeStage != newAgeStage) {
        print('[HomeController]   - 나이 개월 변경 감지: ${oldAgeMonths}개월 -> ${newAgeMonths}개월 (단계: $oldAgeStage -> $newAgeStage)');
        return true;
      }
    } else if (oldAgeMonths != newAgeMonths) {
      print('[HomeController]   - 나이 개월 변경 감지: $oldAgeMonths -> $newAgeMonths');
      return true;
    }
    
    // 품종 코드 비교
    if (oldPet.breedCode != newPet.breedCode) {
      print('[HomeController]   - 품종 변경 감지: ${oldPet.breedCode} -> ${newPet.breedCode}');
      return true;
    }
    
    // 종 비교
    if (oldPet.species != newPet.species) {
      print('[HomeController]   - 종 변경 감지: ${oldPet.species} -> ${newPet.species}');
      return true;
    }
    
    // 기타 알레르기 텍스트 비교
    if (oldPet.otherAllergies?.trim() != newPet.otherAllergies?.trim()) {
      print('[HomeController]   - 기타 알레르기 변경 감지: ${oldPet.otherAllergies} -> ${newPet.otherAllergies}');
      return true;
    }
    
    return false;
  }

  /// 리스트 비교 헬퍼 (순서 무관하게 비교)
  bool _listEqualsUnordered(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final aSet = a.toSet();
    final bSet = b.toSet();
    return aSet.length == bSet.length && aSet.every((item) => bSet.contains(item));
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

  /// 홈 모달 캠페인 로드
  Future<void> _loadHomeModalCampaigns() async {
    try {
      state = state.copyWith(isLoadingCampaigns: true);
      final campaigns = await _campaignService.getHomeModalCampaigns();
      state = state.copyWith(
        homeModalCampaigns: campaigns,
        isLoadingCampaigns: false,
      );
      print('[HomeController] 홈 모달 캠페인 로드 완료: ${campaigns.length}개');
    } catch (e) {
      print('[HomeController] 홈 모달 캠페인 로드 실패: $e');
      state = state.copyWith(isLoadingCampaigns: false);
      // 에러가 발생해도 홈 화면은 정상 동작하도록 함
    }
  }

  /// 홈 배너 캠페인 로드
  Future<void> _loadHomeBannerCampaigns() async {
    try {
      final campaigns = await _campaignService.getHomeBannerCampaigns();
      state = state.copyWith(
        homeBannerCampaigns: campaigns,
      );
      print('[HomeController] 홈 배너 캠페인 로드 완료: ${campaigns.length}개');
    } catch (e) {
      print('[HomeController] 홈 배너 캠페인 로드 실패: $e');
      // 에러가 발생해도 홈 화면은 정상 동작하도록 함
    }
  }
}

final homeControllerProvider =
    StateNotifierProvider<HomeController, HomeState>((ref) {
  final recommendationService = ref.watch(recommendationServiceProvider);
  final petService = ref.watch(petServiceProvider);
  final userService = ref.watch(userServiceProvider);
  final campaignService = ref.watch(campaignServiceProvider);
  return HomeController(recommendationService, petService, userService, campaignService, ref);
});
