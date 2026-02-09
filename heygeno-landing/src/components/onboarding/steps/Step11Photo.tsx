import { Upload } from 'lucide-react';
import { OnboardingLayout } from '../OnboardingLayout';

type Step11PhotoProps = {
  value: string;
  petName: string;
  onUpdate: (value: string) => void;
  onNext: () => void;
  onBack: () => void;
  currentStep: number;
  totalSteps: number;
};

export function Step11Photo({
  value,
  petName,
  onUpdate,
  onNext,
  onBack,
  currentStep,
  totalSteps
}: Step11PhotoProps) {
  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        onUpdate(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  return (
    <OnboardingLayout
      currentStep={currentStep}
      totalSteps={totalSteps}
      onBack={onBack}
      emoji="📸"
      title={`Add a photo of ${petName}`}
      subtitle="Help us recognize your pet (optional)"
      ctaText={value ? 'Complete setup' : 'Skip for now'}
      onCTAClick={onNext}
      ctaSecondary={value ? {
        text: 'Change photo',
        onClick: () => document.getElementById('photo-upload')?.click()
      } : undefined}
    >
      <div>
        <input
          id="photo-upload"
          type="file"
          accept="image/*"
          onChange={handleFileChange}
          className="hidden"
        />

        {!value ? (
          <button
            onClick={() => document.getElementById('photo-upload')?.click()}
            className="w-full h-64 rounded-2xl border-2 border-dashed border-[#E5E7EB] bg-[#F7F8FA] hover:border-[#2563EB] hover:bg-[#EFF6FF] transition-all duration-200 flex flex-col items-center justify-center gap-4 active:scale-[0.98]"
          >
            <div className="w-16 h-16 rounded-full bg-white flex items-center justify-center">
              <Upload className="w-7 h-7 text-[#2563EB]" />
            </div>
            <div className="text-body text-[#111827]">
              Upload a photo
            </div>
            <div className="text-sub text-[#6B7280]">
              Tap to choose from your device
            </div>
          </button>
        ) : (
          <div className="w-full h-64 rounded-2xl overflow-hidden ring-2 ring-[#2563EB]">
            <img
              src={value}
              alt={`${petName}'s photo`}
              className="w-full h-full object-cover"
            />
          </div>
        )}
      </div>
    </OnboardingLayout>
  );
}