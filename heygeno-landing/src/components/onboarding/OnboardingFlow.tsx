import { useState } from 'react';
import { Step1Nickname } from './steps/Step1Nickname';
import { Step2PetName } from './steps/Step2PetName';
import { Step3Species } from './steps/Step3Species';
import { Step4Age } from './steps/Step4Age';
import { Step5Breed } from './steps/Step5Breed';
import { Step6SexNeutered } from './steps/Step6SexNeutered';
import { Step7Weight } from './steps/Step7Weight';
import { Step8BCS } from './steps/Step8BCS';
import { Step9HealthConcerns } from './steps/Step9HealthConcerns';
import { Step10FoodAllergies } from './steps/Step10FoodAllergies';
import { Step11Photo } from './steps/Step11Photo';

export type OnboardingData = {
  nickname: string;
  petName: string;
  species: 'dog' | 'cat' | '';
  ageType: 'birthdate' | 'approximate' | '';
  birthdate: string;
  approximateAge: string;
  breed: string;
  sex: 'male' | 'female' | '';
  neutered: boolean | null;
  weight: string;
  bcs: number;
  healthConcerns: string[];
  foodAllergies: string[];
  otherAllergy: string;
  photo: string;
};

export function OnboardingFlow() {
  const [currentStep, setCurrentStep] = useState(1);
  const [data, setData] = useState<OnboardingData>({
    nickname: '',
    petName: '',
    species: '',
    ageType: '',
    birthdate: '',
    approximateAge: '',
    breed: '',
    sex: '',
    neutered: null,
    weight: '',
    bcs: 5,
    healthConcerns: [],
    foodAllergies: [],
    otherAllergy: '',
    photo: ''
  });

  const updateData = (updates: Partial<OnboardingData>) => {
    setData(prev => ({ ...prev, ...updates }));
  };

  const nextStep = () => {
    // Handle Dog/Cat branching logic
    if (currentStep === 4 && data.species === 'cat') {
      setCurrentStep(6); // Skip breed step for cats
    } else {
      setCurrentStep(prev => prev + 1);
    }
  };

  const prevStep = () => {
    // Handle Dog/Cat branching logic in reverse
    if (currentStep === 6 && data.species === 'cat') {
      setCurrentStep(4); // Go back to age step for cats
    } else {
      setCurrentStep(prev => prev - 1);
    }
  };

  const getTotalSteps = () => {
    return data.species === 'cat' ? 11 : 12;
  };

  const getCurrentStepNumber = () => {
    if (data.species === 'cat' && currentStep > 4) {
      return currentStep - 1; // Adjust step number for cats (skipped breed)
    }
    return currentStep;
  };

  return (
    <div className="min-h-screen bg-[#F7F8FA] flex items-center justify-center p-4">
      <div className="w-full max-w-[375px] rounded-3xl overflow-hidden shadow-sm">
        {currentStep === 1 && (
          <Step1Nickname
            value={data.nickname}
            onUpdate={(nickname) => updateData({ nickname })}
            onNext={nextStep}
            currentStep={getCurrentStepNumber()}
            totalSteps={getTotalSteps()}
          />
        )}
        {currentStep === 2 && (
          <Step2PetName
            value={data.petName}
            onUpdate={(petName) => updateData({ petName })}
            onNext={nextStep}
            onBack={prevStep}
            currentStep={getCurrentStepNumber()}
            totalSteps={getTotalSteps()}
          />
        )}
        {currentStep === 3 && (
          <Step3Species
            value={data.species}
            onUpdate={(species) => updateData({ species })}
            onNext={nextStep}
            onBack={prevStep}
            currentStep={getCurrentStepNumber()}
            totalSteps={getTotalSteps()}
          />
        )}
        {currentStep === 4 && (
          <Step4Age
            ageType={data.ageType}
            birthdate={data.birthdate}
            approximateAge={data.approximateAge}
            onUpdate={(updates) => updateData(updates)}
            onNext={nextStep}
            onBack={prevStep}
            currentStep={getCurrentStepNumber()}
            totalSteps={getTotalSteps()}
          />
        )}
        {currentStep === 5 && data.species === 'dog' && (
          <Step5Breed
            value={data.breed}
            onUpdate={(breed) => updateData({ breed })}
            onNext={nextStep}
            onBack={prevStep}
            currentStep={getCurrentStepNumber()}
            totalSteps={getTotalSteps()}
          />
        )}
        {currentStep === 6 && (
          <Step6SexNeutered
            sex={data.sex}
            neutered={data.neutered}
            onUpdate={(updates) => updateData(updates)}
            onNext={nextStep}
            onBack={prevStep}
            currentStep={getCurrentStepNumber()}
            totalSteps={getTotalSteps()}
          />
        )}
        {currentStep === 7 && (
          <Step7Weight
            value={data.weight}
            onUpdate={(weight) => updateData({ weight })}
            onNext={nextStep}
            onBack={prevStep}
            currentStep={getCurrentStepNumber()}
            totalSteps={getTotalSteps()}
          />
        )}
        {currentStep === 8 && (
          <Step8BCS
            value={data.bcs}
            onUpdate={(bcs) => updateData({ bcs })}
            onNext={nextStep}
            onBack={prevStep}
            currentStep={getCurrentStepNumber()}
            totalSteps={getTotalSteps()}
          />
        )}
        {currentStep === 9 && (
          <Step9HealthConcerns
            value={data.healthConcerns}
            onUpdate={(healthConcerns) => updateData({ healthConcerns })}
            onNext={nextStep}
            onBack={prevStep}
            currentStep={getCurrentStepNumber()}
            totalSteps={getTotalSteps()}
          />
        )}
        {currentStep === 10 && (
          <Step10FoodAllergies
            value={data.foodAllergies}
            otherAllergy={data.otherAllergy}
            onUpdate={(updates) => updateData(updates)}
            onNext={nextStep}
            onBack={prevStep}
            currentStep={getCurrentStepNumber()}
            totalSteps={getTotalSteps()}
          />
        )}
        {currentStep === 11 && (
          <Step11Photo
            value={data.photo}
            petName={data.petName}
            onUpdate={(photo) => updateData({ photo })}
            onNext={() => console.log('Onboarding complete!', data)}
            onBack={prevStep}
            currentStep={getCurrentStepNumber()}
            totalSteps={getTotalSteps()}
          />
        )}
      </div>
    </div>
  );
}