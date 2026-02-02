/// 온보딩 단계 enum
enum OnboardingStep {
  welcome(1, 'welcome'),
  petName(2, 'petName'),
  species(3, 'species'),
  birthMode(4, 'birthMode'),
  breed(5, 'breed'),
  sexNeutered(6, 'sexNeutered'),
  weight(7, 'weight'),
  bodyCondition(8, 'bodyCondition'),
  healthConcerns(9, 'healthConcerns'),
  foodAllergies(10, 'foodAllergies'),
  photo(11, 'photo');

  final int stepNumber;
  final String key;

  const OnboardingStep(this.stepNumber, this.key);

  /// 다음 단계 반환
  OnboardingStep? get next {
    if (stepNumber >= 11) return null;
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
  double get progress => stepNumber / 11;

  /// 진행률 퍼센트 (0 ~ 100)
  int get progressPercent => (progress * 100).round();
}
