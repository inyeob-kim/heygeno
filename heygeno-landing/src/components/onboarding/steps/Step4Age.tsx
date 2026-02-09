import { OnboardingLayout } from '../OnboardingLayout';
import { SelectionCard } from '../SelectionCard';
import { TextInput } from '../TextInput';

type Step4AgeProps = {
  ageType: 'birthdate' | 'approximate' | '';
  birthdate: string;
  approximateAge: string;
  onUpdate: (updates: { ageType?: 'birthdate' | 'approximate'; birthdate?: string; approximateAge?: string }) => void;
  onNext: () => void;
  onBack: () => void;
  currentStep: number;
  totalSteps: number;
};

export function Step4Age({
  ageType,
  birthdate,
  approximateAge,
  onUpdate,
  onNext,
  onBack,
  currentStep,
  totalSteps
}: Step4AgeProps) {
  const isValid = 
    (ageType === 'birthdate' && birthdate !== '') ||
    (ageType === 'approximate' && approximateAge !== '');

  return (
    <OnboardingLayout
      currentStep={currentStep}
      totalSteps={totalSteps}
      onBack={onBack}
      emoji="📅"
      title="How old is your pet?"
      subtitle="Choose how you'd like to enter their age"
      ctaText="Continue"
      ctaDisabled={!isValid}
      onCTAClick={onNext}
    >
      <div className="space-y-3">
        <SelectionCard
          selected={ageType === 'birthdate'}
          onClick={() => onUpdate({ ageType: 'birthdate' })}
          emoji="📅"
        >
          <div>
            <div className="text-body text-[#111827] mb-1">
              Birthdate
            </div>
            <div className="text-sub text-[#6B7280]">
              I know the exact birthdate
            </div>
          </div>
        </SelectionCard>

        {ageType === 'birthdate' && (
          <div className="pt-2">
            <TextInput
              type="date"
              value={birthdate}
              onChange={(val) => onUpdate({ birthdate: val })}
            />
          </div>
        )}

        <SelectionCard
          selected={ageType === 'approximate'}
          onClick={() => onUpdate({ ageType: 'approximate' })}
          emoji="🎈"
        >
          <div>
            <div className="text-body text-[#111827] mb-1">
              Approximate age
            </div>
            <div className="text-sub text-[#6B7280]">
              I know roughly how old they are
            </div>
          </div>
        </SelectionCard>

        {ageType === 'approximate' && (
          <div className="pt-2">
            <TextInput
              value={approximateAge}
              onChange={(val) => onUpdate({ approximateAge: val })}
              placeholder="e.g., 3 years, 6 months"
            />
          </div>
        )}
      </div>
    </OnboardingLayout>
  );
}