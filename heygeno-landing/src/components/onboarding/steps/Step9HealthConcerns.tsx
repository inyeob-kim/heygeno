import { OnboardingLayout } from '../OnboardingLayout';
import { Chip } from '../Chip';

type Step9HealthConcernsProps = {
  value: string[];
  onUpdate: (value: string[]) => void;
  onNext: () => void;
  onBack: () => void;
  currentStep: number;
  totalSteps: number;
};

const healthOptions = [
  'None',
  'Allergies',
  'Arthritis',
  'Diabetes',
  'Heart disease',
  'Kidney disease',
  'Dental issues',
  'Skin conditions',
  'Digestive issues'
];

export function Step9HealthConcerns({
  value,
  onUpdate,
  onNext,
  onBack,
  currentStep,
  totalSteps
}: Step9HealthConcernsProps) {
  const handleToggle = (concern: string) => {
    if (concern === 'None') {
      // "None" is exclusive
      onUpdate(value.includes('None') ? [] : ['None']);
    } else {
      // Remove "None" if selecting anything else
      const filtered = value.filter(v => v !== 'None');
      if (filtered.includes(concern)) {
        onUpdate(filtered.filter(v => v !== concern));
      } else {
        onUpdate([...filtered, concern]);
      }
    }
  };

  return (
    <OnboardingLayout
      currentStep={currentStep}
      totalSteps={totalSteps}
      onBack={onBack}
      emoji="🏥"
      title="Any health concerns?"
      subtitle="Select all that apply to your pet"
      ctaText="Continue"
      onCTAClick={onNext}
    >
      <div className="flex flex-wrap gap-2">
        {healthOptions.map((option) => (
          <Chip
            key={option}
            label={option}
            selected={value.includes(option)}
            onClick={() => handleToggle(option)}
          />
        ))}
      </div>
    </OnboardingLayout>
  );
}
