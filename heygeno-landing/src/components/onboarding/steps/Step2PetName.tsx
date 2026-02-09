import { OnboardingLayout } from '../OnboardingLayout';
import { TextInput } from '../TextInput';

type Step2PetNameProps = {
  value: string;
  onUpdate: (value: string) => void;
  onNext: () => void;
  onBack: () => void;
  currentStep: number;
  totalSteps: number;
};

export function Step2PetName({
  value,
  onUpdate,
  onNext,
  onBack,
  currentStep,
  totalSteps
}: Step2PetNameProps) {
  const isValid = value.length >= 1 && value.length <= 20;

  return (
    <OnboardingLayout
      currentStep={currentStep}
      totalSteps={totalSteps}
      onBack={onBack}
      emoji="🐾"
      title="What's your pet's name?"
      subtitle="Let us know what to call your furry friend"
      ctaText="Continue"
      ctaDisabled={!isValid}
      onCTAClick={onNext}
    >
      <div className="space-y-3">
        <label className="block text-sub text-[#6B7280]">
          Pet's name
        </label>
        <TextInput
          value={value}
          onChange={onUpdate}
          placeholder="Enter pet's name"
          maxLength={20}
        />
        <p className="text-sub text-[#6B7280]">
          1–20 characters
        </p>
      </div>
    </OnboardingLayout>
  );
}