import { OnboardingLayout } from '../OnboardingLayout';
import { SelectionCard } from '../SelectionCard';

type Step6SexNeuteredProps = {
  sex: 'male' | 'female' | '';
  neutered: boolean | null;
  onUpdate: (updates: { sex?: 'male' | 'female'; neutered?: boolean }) => void;
  onNext: () => void;
  onBack: () => void;
  currentStep: number;
  totalSteps: number;
};

export function Step6SexNeutered({
  sex,
  neutered,
  onUpdate,
  onNext,
  onBack,
  currentStep,
  totalSteps
}: Step6SexNeuteredProps) {
  const isValid = sex !== '' && neutered !== null;

  return (
    <OnboardingLayout
      currentStep={currentStep}
      totalSteps={totalSteps}
      onBack={onBack}
      emoji="⚧️"
      title="Tell us about your pet"
      subtitle="Select sex and neutered status"
      ctaText="Continue"
      ctaDisabled={!isValid}
      onCTAClick={onNext}
    >
      <div className="space-y-8">
        <div>
          <h3 className="text-sub text-[#6B7280] mb-3">Sex</h3>
          <div className="space-y-3">
            <SelectionCard
              selected={sex === 'male'}
              onClick={() => onUpdate({ sex: 'male' })}
            >
              <span className="text-body text-[#111827]">
                Male
              </span>
            </SelectionCard>

            <SelectionCard
              selected={sex === 'female'}
              onClick={() => onUpdate({ sex: 'female' })}
            >
              <span className="text-body text-[#111827]">
                Female
              </span>
            </SelectionCard>
          </div>
        </div>

        <div>
          <h3 className="text-sub text-[#6B7280] mb-3">Neutered/Spayed</h3>
          <div className="space-y-3">
            <SelectionCard
              selected={neutered === true}
              onClick={() => onUpdate({ neutered: true })}
            >
              <span className="text-body text-[#111827]">
                Yes
              </span>
            </SelectionCard>

            <SelectionCard
              selected={neutered === false}
              onClick={() => onUpdate({ neutered: false })}
            >
              <span className="text-body text-[#111827]">
                No
              </span>
            </SelectionCard>
          </div>
        </div>
      </div>
    </OnboardingLayout>
  );
}