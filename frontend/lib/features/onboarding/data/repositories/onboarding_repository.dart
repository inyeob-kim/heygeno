import 'dart:convert';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/storage/storage_keys.dart';
import '../models/pet_profile_draft.dart';
import '../models/onboarding_step.dart';

/// 온보딩 데이터 저장소 인터페이스
abstract class OnboardingRepository {
  Future<bool> isOnboardingCompleted();
  Future<void> setOnboardingCompleted(bool completed);
  Future<OnboardingStep?> getLastStep();
  Future<void> saveLastStep(OnboardingStep step);
  Future<String?> getDraftNickname();
  Future<void> saveDraftNickname(String nickname);
  Future<PetProfileDraft?> getDraftProfile();
  Future<void> saveDraftProfile(PetProfileDraft profile);
  Future<void> clearAll();
}

/// 온보딩 데이터 저장소 구현
class OnboardingRepositoryImpl implements OnboardingRepository {
  @override
  Future<bool> isOnboardingCompleted() async {
    final value = await SecureStorage.read(StorageKeys.onboardingCompleted);
    return value == 'true';
  }

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    await SecureStorage.write(
      StorageKeys.onboardingCompleted,
      completed.toString(),
    );
  }

  @override
  Future<OnboardingStep?> getLastStep() async {
    final stepValue = await SecureStorage.read(StorageKeys.onboardingStep);
    if (stepValue == null) return null;

    final stepNumber = int.tryParse(stepValue);
    if (stepNumber == null) return null;

    try {
      return OnboardingStep.values.firstWhere(
        (step) => step.stepNumber == stepNumber,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveLastStep(OnboardingStep step) async {
    await SecureStorage.write(
      StorageKeys.onboardingStep,
      step.stepNumber.toString(),
    );
  }

  @override
  Future<String?> getDraftNickname() async {
    return await SecureStorage.read(StorageKeys.draftNickname);
  }

  @override
  Future<void> saveDraftNickname(String nickname) async {
    await SecureStorage.write(StorageKeys.draftNickname, nickname);
  }

  @override
  Future<PetProfileDraft?> getDraftProfile() async {
    final jsonString = await SecureStorage.read(StorageKeys.draftPetProfile);
    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return PetProfileDraft.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveDraftProfile(PetProfileDraft profile) async {
    final jsonString = jsonEncode(profile.toJson());
    await SecureStorage.write(StorageKeys.draftPetProfile, jsonString);
  }

  @override
  Future<void> clearAll() async {
    await SecureStorage.delete(StorageKeys.onboardingCompleted);
    await SecureStorage.delete(StorageKeys.onboardingStep);
    await SecureStorage.delete(StorageKeys.draftNickname);
    await SecureStorage.delete(StorageKeys.draftPetProfile);
  }
}
