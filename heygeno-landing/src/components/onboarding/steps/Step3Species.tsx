import { OnboardingLayout } from '../OnboardingLayout';
import { SelectionCard } from '../SelectionCard';

type Step3SpeciesProps = {
  value: 'dog' | 'cat' | '';
  onUpdate: (value: 'dog' | 'cat') => void;
  onNext: () => void;
  onBack: () => void;
  currentStep: number;
  totalSteps: number;
};

export function Step3Species({
  value,
  onUpdate,
  onNext,
  onBack,
  currentStep,
  totalSteps
}: Step3SpeciesProps) {
  const handleSelect = (species: 'dog' | 'cat') => {
    onUpdate(species);
  };

  return (
    <OnboardingLayout
      currentStep={currentStep}
      totalSteps={totalSteps}
      onBack={onBack}
      emoji="🐶"
      title="What kind of pet do you have?"
      subtitle="Select your pet's species"
      ctaText="Continue"
      ctaDisabled={!value}
      onCTAClick={onNext}
    >
      <div className="space-y-3">
        <SelectionCard
          selected={value === 'dog'}
          onClick={() => handleSelect('dog')}
          emoji="🐶"
        >
          <span className="text-body text-[#111827]">Dog</span>
        </SelectionCard>

        <SelectionCard
          selected={value === 'cat'}
          onClick={() => handleSelect('cat')}
          emoji="🐱"
        >
          <span className="text-body text-[#111827]">Cat</span>
        </SelectionCard>
      </div>
    </OnboardingLayout>
  );
}