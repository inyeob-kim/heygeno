import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/services/pet_service.dart';
import '../../../../data/models/pet_summary_dto.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/error_handler.dart';

/// 마이(계정 허브) 화면 상태 — 관리/설정/계정만, 추천·가격 알림 없음
class MyState {
  final bool isLoading;
  final String? error;
  final PetSummaryDto? petSummary;
  final List<PetSummaryDto> pets;

  const MyState({
    this.isLoading = false,
    this.error,
    this.petSummary,
    this.pets = const [],
  });

  MyState copyWith({
    bool? isLoading,
    String? error,
    PetSummaryDto? petSummary,
    List<PetSummaryDto>? pets,
  }) {
    return MyState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      petSummary: petSummary ?? this.petSummary,
      pets: pets ?? this.pets,
    );
  }
}

/// 마이(계정 허브) 화면 컨트롤러
/// 단일 책임: 펫 목록 및 primary 펫 관리. 추천/가격 알림 없음.
class MyController extends StateNotifier<MyState> {
  final PetService _petService;

  MyController(this._petService) : super(MyState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true, error: null, pets: const []);

    try {
      final petsList = await _petService.getAllPetSummaries();
      final sortedPetsList = List<PetSummaryDto>.from(petsList)
        ..sort((a, b) {
          final aIsPrimary = a.isPrimary ?? false;
          final bIsPrimary = b.isPrimary ?? false;
          if (aIsPrimary && !bIsPrimary) return -1;
          if (!aIsPrimary && bIsPrimary) return 1;
          return 0;
        });

      PetSummaryDto? petSummary;
      try {
        petSummary = sortedPetsList.firstWhere((pet) => pet.isPrimary ?? false);
      } catch (_) {
        petSummary = sortedPetsList.isNotEmpty ? sortedPetsList.first : null;
      }

      state = state.copyWith(
        isLoading: false,
        petSummary: petSummary,
        pets: sortedPetsList,
      );
    } catch (e) {
      final failure = e is Exception
          ? handleException(e)
          : ServerFailure('프로필을 불러오는데 실패했습니다: ${e.toString()}');
      state = state.copyWith(
        isLoading: false,
        error: failure.message,
        pets: const [],
      );
    }
  }

  Future<void> refresh() async {
    await _initialize();
  }
}

final myControllerProvider =
    StateNotifierProvider<MyController, MyState>((ref) {
  final petService = ref.watch(petServiceProvider);
  return MyController(petService);
});
