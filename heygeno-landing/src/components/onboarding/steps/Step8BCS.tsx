import { OnboardingLayout } from '../OnboardingLayout';

type Step8BCSProps = {
  value: number;
  onUpdate: (value: number) => void;
  onNext: () => void;
  onBack: () => void;
  currentStep: number;
  totalSteps: number;
};

export function Step8BCS({
  value,
  onUpdate,
  onNext,
  onBack,
  currentStep,
  totalSteps
}: Step8BCSProps) {
  const getBCSLabel = (score: number) => {
    if (score <= 3) return 'Underweight';
    if (score <= 5) return 'Ideal';
    if (score <= 7) return 'Overweight';
    return 'Obese';
  };

  return (
    <OnboardingLayout
      currentStep={currentStep}
      totalSteps={totalSteps}
      onBack={onBack}
      emoji="📊"
      title="Body condition score"
      subtitle="Rate your pet's body condition from 1 (very thin) to 9 (obese)"
      ctaText="Continue"
      onCTAClick={onNext}
    >
      <div className="space-y-8">
        <div>
          <div className="flex items-baseline justify-between mb-6">
            <span className="text-hero text-[#2563EB]">{value}</span>
            <span className="text-body text-[#6B7280]">
              {getBCSLabel(value)}
            </span>
          </div>
          
          <input
            type="range"
            min="1"
            max="9"
            value={value}
            onChange={(e) => onUpdate(parseInt(e.target.value))}
            className="w-full h-2 bg-[#F7F8FA] rounded-full appearance-none cursor-pointer"
            style={{
              background: `linear-gradient(to right, #2563EB 0%, #2563EB ${((value - 1) / 8) * 100}%, #F7F8FA ${((value - 1) / 8) * 100}%, #F7F8FA 100%)`
            }}
          />
          
          <div className="flex justify-between mt-3">
            <span className="text-sub text-[#6B7280]">1</span>
            <span className="text-sub text-[#6B7280]">5</span>
            <span className="text-sub text-[#6B7280]">9</span>
          </div>
        </div>

        <div className="space-y-4 text-sub">
          <div className="flex items-start gap-3">
            <div className="w-1.5 h-1.5 rounded-full bg-[#2563EB] mt-2 flex-shrink-0" />
            <p className="text-[#6B7280]">
              <strong className="text-[#111827]">1-3:</strong> Ribs, spine visible; no body fat
            </p>
          </div>
          <div className="flex items-start gap-3">
            <div className="w-1.5 h-1.5 rounded-full bg-[#2563EB] mt-2 flex-shrink-0" />
            <p className="text-[#6B7280]">
              <strong className="text-[#111827]">4-5:</strong> Ribs palpable; visible waist
            </p>
          </div>
          <div className="flex items-start gap-3">
            <div className="w-1.5 h-1.5 rounded-full bg-[#2563EB] mt-2 flex-shrink-0" />
            <p className="text-[#6B7280]">
              <strong className="text-[#111827]">6-7:</strong> Ribs difficult to feel; waist barely visible
            </p>
          </div>
          <div className="flex items-start gap-3">
            <div className="w-1.5 h-1.5 rounded-full bg-[#2563EB] mt-2 flex-shrink-0" />
            <p className="text-[#6B7280]">
              <strong className="text-[#111827]">8-9:</strong> Heavy fat deposits; no waist
            </p>
          </div>
        </div>
      </div>
    </OnboardingLayout>
  );
}