import { OnboardingLayout } from '../OnboardingLayout';
import { TextInput } from '../TextInput';

type Step1NicknameProps = {
  value: string;
  onUpdate: (value: string) => void;
  onNext: () => void;
  currentStep: number;
  totalSteps: number;
};

export function Step1Nickname({
  value,
  onUpdate,
  onNext,
  currentStep,
  totalSteps
}: Step1NicknameProps) {
  const isValid = value.length >= 2 && value.length <= 12;

  return (
    <OnboardingLayout
      currentStep={currentStep}
      totalSteps={totalSteps}
      emoji="👋"
      title="What should we call you?"
      subtitle="Enter a nickname to get started"
      ctaText="Continue"
      ctaDisabled={!isValid}
      onCTAClick={onNext}
    >
      <div className="space-y-3">
        <label className="block text-sub text-[#6B7280]">
          Nickname
        </label>
        <TextInput
          value={value}
          onChange={onUpdate}
          placeholder="Your nickname"
          maxLength={12}
        />
        <p className="text-sub text-[#6B7280]">
          2–12 characters
        </p>
      </div>
    </OnboardingLayout>
  );
}