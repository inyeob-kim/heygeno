import { OnboardingLayout } from '../OnboardingLayout';
import { Chip } from '../Chip';
import { TextInput } from '../TextInput';

type Step10FoodAllergiesProps = {
  value: string[];
  otherAllergy: string;
  onUpdate: (updates: { foodAllergies?: string[]; otherAllergy?: string }) => void;
  onNext: () => void;
  onBack: () => void;
  currentStep: number;
  totalSteps: number;
};

const allergyOptions = [
  'None',
  'Chicken',
  'Beef',
  'Dairy',
  'Wheat',
  'Soy',
  'Fish',
  'Eggs',
  'Other'
];

export function Step10FoodAllergies({
  value,
  otherAllergy,
  onUpdate,
  onNext,
  onBack,
  currentStep,
  totalSteps
}: Step10FoodAllergiesProps) {
  const handleToggle = (allergy: string) => {
    if (allergy === 'None') {
      // "None" is exclusive
      onUpdate({ 
        foodAllergies: value.includes('None') ? [] : ['None'],
        otherAllergy: ''
      });
    } else {
      // Remove "None" if selecting anything else
      const filtered = value.filter(v => v !== 'None');
      if (filtered.includes(allergy)) {
        const newValue = filtered.filter(v => v !== allergy);
        onUpdate({ 
          foodAllergies: newValue,
          otherAllergy: allergy === 'Other' ? '' : otherAllergy
        });
      } else {
        onUpdate({ foodAllergies: [...filtered, allergy] });
      }
    }
  };

  return (
    <OnboardingLayout
      currentStep={currentStep}
      totalSteps={totalSteps}
      onBack={onBack}
      emoji="🍖"
      title="Any food allergies?"
      subtitle="Select all ingredients your pet is allergic to"
      ctaText="Continue"
      onCTAClick={onNext}
    >
      <div className="space-y-4">
        <div className="flex flex-wrap gap-2">
          {allergyOptions.map((option) => (
            <Chip
              key={option}
              label={option}
              selected={value.includes(option)}
              onClick={() => handleToggle(option)}
            />
          ))}
        </div>

        {value.includes('Other') && (
          <div className="pt-2">
            <label className="block text-sm font-medium text-[#6B7280] mb-2">
              Please specify
            </label>
            <TextInput
              value={otherAllergy}
              onChange={(val) => onUpdate({ otherAllergy: val })}
              placeholder="Enter other allergies"
            />
          </div>
        )}
      </div>
    </OnboardingLayout>
  );
}
