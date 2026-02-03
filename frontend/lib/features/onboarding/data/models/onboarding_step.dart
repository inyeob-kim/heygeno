/// 온보딩 단계 enum (9단계로 세분화)
enum OnboardingStep {
  nickname(1, 'nickname'),           // 닉네임
  petName(2, 'petName'),             // 아이 이름
  species(3, 'species'),             // 종 선택
  age(4, 'age'),                     // 나이
  breed(5, 'breed'),                 // 품종 (강아지만)
  sexNeutered(6, 'sexNeutered'),     // 성별 + 중성화
  weight(7, 'weight'),               // 몸무게
  bodyCondition(8, 'bodyCondition'), // 체형
  healthAllergies(9, 'healthAllergies'), // 건강 + 알레르기
  photo(10, 'photo');                // 사진

  final int stepNumber;
  final String key;

  const OnboardingStep(this.stepNumber, this.key);

  /// 다음 단계 반환
  OnboardingStep? get next {
    if (stepNumber >= 10) return null;
    return OnboardingStep.values.firstWhere(
      (step) => step.stepNumber == stepNumber + 1,
    );
  }

  /// 이전 단계 반환
  OnboardingStep? get previous {
    if (stepNumber <= 1) return null;
    return OnboardingStep.values.firstWhere(
      (step) => step.stepNumber == stepNumber - 1,
    );
  }

  /// 진행률 (0.0 ~ 1.0)
  double get progress => stepNumber / 10;

  /// 진행률 퍼센트 (0 ~ 100)
  int get progressPercent => (progress * 100).round();
}
