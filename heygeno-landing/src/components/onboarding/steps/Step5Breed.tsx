import { OnboardingLayout } from '../OnboardingLayout';
import { TextInput } from '../TextInput';

type Step5BreedProps = {
  value: string;
  onUpdate: (value: string) => void;
  onNext: () => void;
  onBack: () => void;
  currentStep: number;
  totalSteps: number;
};

export function Step5Breed({
  value,
  onUpdate,
  onNext,
  onBack,
  currentStep,
  totalSteps
}: Step5BreedProps) {
  const isValid = value.trim().length > 0;

  return (
    <OnboardingLayout
      currentStep={currentStep}
      totalSteps={totalSteps}
      onBack={onBack}
      emoji="🦴"
      title="What breed is your dog?"
      subtitle="Enter your dog's breed or mix"
      ctaText="Continue"
      ctaDisabled={!isValid}
      onCTAClick={onNext}
    >
      <div className="space-y-3">
        <label className="block text-sub text-[#6B7280]">
          Breed
        </label>
        <TextInput
          value={value}
          onChange={onUpdate}
          placeholder="e.g., Golden Retriever, Mixed"
        />
        <p className="text-sub text-[#6B7280]">
          Enter breed name or "Mixed" for mixed breeds
        </p>
      </div>
    </OnboardingLayout>
  );
}