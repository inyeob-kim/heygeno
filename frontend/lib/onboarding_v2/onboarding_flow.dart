import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../theme_v2/app_theme.dart';
import '../../app/router/route_paths.dart';
import 'model/onboarding_state.dart';
import '../../features/onboarding/data/repositories/onboarding_repository.dart';
import '../../core/services/device_uid_service.dart';
import '../../core/network/api_client.dart';
import '../../core/network/endpoints.dart';
import 'steps/step01_nickname.dart';
import 'steps/step02_pet_name.dart';
import 'steps/step03_species.dart';
import 'steps/step04_age.dart';
import 'steps/step05_breed.dart';
import 'steps/step06_sex_neutered.dart';
import 'steps/step07_weight.dart';
import 'steps/step08_bcs.dart';
import 'steps/step09_health.dart';
import 'steps/step10_allergy.dart';
import 'steps/step11_photo.dart';

/// Onboarding flow controller matching React OnboardingFlow
class OnboardingFlowV2 extends ConsumerStatefulWidget {
  final bool isAddPetMode;
  
  const OnboardingFlowV2({
    super.key,
    this.isAddPetMode = false,
  });

  @override
  ConsumerState<OnboardingFlowV2> createState() => _OnboardingFlowV2State();
}

class _OnboardingFlowV2State extends ConsumerState<OnboardingFlowV2> {
  late int _currentStep;
  OnboardingStateV2 _data = const OnboardingStateV2();
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    // 펫 추가 모드면 Step 2부터 시작, 아니면 Step 1부터
    _currentStep = widget.isAddPetMode ? 2 : 1;
  }

  void _updateData(OnboardingStateV2 Function(OnboardingStateV2) updater) {
    setState(() {
      _data = updater(_data);
    });
  }

  /// 온보딩 완료 처리
  Future<void> _completeOnboarding() async {
    if (_isCompleting) return;
    
    setState(() {
      _isCompleting = true;
    });

    try {
      // Device UID 생성/확인
      final deviceUid = await DeviceUidService.getOrCreate();

      // API 요청 데이터 생성
      final requestData = _data.toApiRequest(deviceUid);
      // 펫 추가 모드면 닉네임을 빈 문자열로 설정하고 is_add_pet_mode 플래그 추가
      if (widget.isAddPetMode) {
        requestData['nickname'] = '';
        requestData['is_add_pet_mode'] = true;
      } else {
        requestData['is_add_pet_mode'] = false;
      }
      
      debugPrint('[OnboardingFlowV2] 온보딩 완료 요청 (펫 추가 모드: ${widget.isAddPetMode}): $requestData');

      // API 클라이언트 가져오기
      final apiClient = ref.read(apiClientProvider);
      
      // 서버에 데이터 전송
      try {
        final response = await apiClient.post(
          Endpoints.onboardingComplete,
          data: requestData,
        );
        
        debugPrint('[OnboardingFlowV2] 서버 응답: ${response.data}');
      } on DioException catch (e) {
        debugPrint('[OnboardingFlowV2] API 오류: ${e.message}');
        // 에러가 있어도 로컬 완료 처리 (오프라인 지원)
        if (e.response?.statusCode != null && e.response!.statusCode! >= 400) {
          // 400 이상 에러는 사용자에게 알림 (선택사항)
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('서버 오류: ${e.response?.data?['detail'] ?? e.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }

      // 온보딩 완료 플래그 설정
      final repository = OnboardingRepositoryImpl();
      await repository.setOnboardingCompleted(true);

      debugPrint('[OnboardingFlowV2] 온보딩 완료 처리 완료');

      // 홈으로 이동
      if (mounted) {
        context.go(RoutePaths.home);
      }
    } catch (e) {
      debugPrint('[OnboardingFlowV2] 온보딩 완료 중 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('온보딩 완료 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  void _nextStep() {
    setState(() {
      // 고양이도 품종 선택 단계를 거치므로 분기 로직 제거
      _currentStep = _currentStep + 1;
    });
  }

  void _prevStep() {
    setState(() {
      // 펫 추가 모드에서 Step 2에서 뒤로가기를 누르면 홈으로 이동
      if (widget.isAddPetMode && _currentStep == 2) {
        context.go(RoutePaths.home);
        return;
      }
      // 고양이도 품종 선택 단계를 거치므로 분기 로직 제거
      _currentStep = _currentStep - 1;
    });
  }

  int _getTotalSteps() {
    // 펫 추가 모드면 닉네임 스텝 제외, 고양이와 강아지 모두 동일한 스텝 수
    final baseSteps = 12;
    return widget.isAddPetMode ? baseSteps - 1 : baseSteps;
  }

  int _getCurrentStepNumber() {
    // 펫 추가 모드면 Step 번호를 1 감소 (닉네임 스텝 제외)
    int stepNumber = _currentStep;
    if (widget.isAddPetMode) {
      stepNumber = _currentStep - 1;
    }
    return stepNumber;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppThemeV2.light,
      child: Builder(
        builder: (context) {
          final totalSteps = _getTotalSteps();
          final currentStepNumber = _getCurrentStepNumber();

          switch (_currentStep) {
      case 1:
        return Step01Nickname(
          value: _data.nickname,
          onUpdate: (nickname) => _updateData((d) => d.copyWith(nickname: nickname)),
          onNext: _nextStep,
          currentStep: currentStepNumber,
          totalSteps: totalSteps,
        );
      case 2:
        return Step02PetName(
          value: _data.petName,
          onUpdate: (petName) => _updateData((d) => d.copyWith(petName: petName)),
          onNext: _nextStep,
          onBack: _prevStep,
          currentStep: currentStepNumber,
          totalSteps: totalSteps,
        );
      case 3:
        return Step03Species(
          value: _data.species,
          onUpdate: (species) => _updateData((d) => d.copyWith(species: species)),
          onNext: _nextStep,
          onBack: _prevStep,
          currentStep: currentStepNumber,
          totalSteps: totalSteps,
        );
      case 4:
        return Step04Age(
          ageType: _data.ageType,
          birthdate: _data.birthdate,
          approximateAge: _data.approximateAge,
          onUpdate: (updates) => _updateData((d) => d.copyWith(
            ageType: updates['ageType'] as String? ?? d.ageType,
            birthdate: updates['birthdate'] as String? ?? d.birthdate,
            approximateAge: updates['approximateAge'] as String? ?? d.approximateAge,
          )),
          onNext: _nextStep,
          onBack: _prevStep,
          currentStep: currentStepNumber,
          totalSteps: totalSteps,
        );
      case 5:
        return Step05Breed(
          value: _data.breed,
          species: _data.species,
          onUpdate: (breed) => _updateData((d) => d.copyWith(breed: breed)),
          onNext: _nextStep,
          onBack: _prevStep,
          currentStep: currentStepNumber,
          totalSteps: totalSteps,
        );
      case 6:
        return Step06SexNeutered(
          sex: _data.sex,
          neutered: _data.neutered,
          onUpdate: (updates) => _updateData((d) => d.copyWith(
            sex: updates['sex'] as String? ?? d.sex,
            neutered: updates['neutered'] as bool? ?? d.neutered,
          )),
          onNext: _nextStep,
          onBack: _prevStep,
          currentStep: currentStepNumber,
          totalSteps: totalSteps,
        );
      case 7:
        return Step07Weight(
          value: _data.weight,
          onUpdate: (weight) => _updateData((d) => d.copyWith(weight: weight)),
          onNext: _nextStep,
          onBack: _prevStep,
          currentStep: currentStepNumber,
          totalSteps: totalSteps,
        );
      case 8:
        return Step08BCS(
          value: _data.bcs,
          onUpdate: (bcs) => _updateData((d) => d.copyWith(bcs: bcs)),
          onNext: _nextStep,
          onBack: _prevStep,
          currentStep: currentStepNumber,
          totalSteps: totalSteps,
        );
      case 9:
        return Step09Health(
          value: _data.healthConcerns,
          onUpdate: (healthConcerns) => _updateData((d) => d.copyWith(healthConcerns: healthConcerns)),
          onNext: _nextStep,
          onBack: _prevStep,
          currentStep: currentStepNumber,
          totalSteps: totalSteps,
        );
      case 10:
        return Step10Allergy(
          value: _data.foodAllergies,
          otherAllergy: _data.otherAllergy,
          onUpdate: (updates) => _updateData((d) => d.copyWith(
            foodAllergies: updates['foodAllergies'] as List<String>? ?? d.foodAllergies,
            otherAllergy: updates['otherAllergy'] as String? ?? d.otherAllergy,
          )),
          onNext: _nextStep,
          onBack: _prevStep,
          currentStep: currentStepNumber,
          totalSteps: totalSteps,
        );
      case 11:
        return Step11Photo(
          value: _data.photo,
          petName: _data.petName,
          onUpdate: (photo) => _updateData((d) => d.copyWith(photo: photo)),
          onNext: _completeOnboarding,
          onBack: _prevStep,
          currentStep: currentStepNumber,
          totalSteps: totalSteps,
        );
            default:
              return const Scaffold(
                body: Center(child: Text('Unknown step')),
              );
          }
        },
      ),
    );
  }
}
