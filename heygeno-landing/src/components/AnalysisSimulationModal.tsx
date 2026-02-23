import { useState, useEffect } from 'react';
import { X, Loader2, AlertCircle, CheckCircle, Shield, Award, XCircle, Info, ArrowRight } from 'lucide-react';
import productImage from 'figma:asset/1f513950e90391a568bd6fbe59d74c33c122cf66.png';

interface AnalysisSimulationModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export function AnalysisSimulationModal({ isOpen, onClose }: AnalysisSimulationModalProps) {
  const [currentStep, setCurrentStep] = useState(0);
  const [ingredientCount, setIngredientCount] = useState(0);
  const [isTransitioning, setIsTransitioning] = useState(false);

  const goToStep = (step: number) => {
    setIsTransitioning(true);
    setTimeout(() => {
      setCurrentStep(step);
      setIsTransitioning(false);
    }, 300);
  };

  useEffect(() => {
    if (!isOpen) {
      setCurrentStep(0);
      setIngredientCount(0);
      return;
    }

    // Reset state on open
    setCurrentStep(0);
    setIngredientCount(0);

    // Auto-advance through steps
    const stepTimers = [
      setTimeout(() => goToStep(1), 2000),  // Step 1: 2s
      setTimeout(() => goToStep(2), 4500),  // Step 2: 4.5s
      setTimeout(() => goToStep(3), 7000),  // Step 3: 7s
      setTimeout(() => goToStep(4), 9500),  // Step 4: 9.5s
      setTimeout(() => goToStep(5), 12000), // Step 5: 12s
    ];

    return () => {
      stepTimers.forEach(timer => clearTimeout(timer));
    };
  }, [isOpen]);

  // Ingredient count animation for step 1
  useEffect(() => {
    if (currentStep !== 1) return;

    let count = 0;
    const countInterval = setInterval(() => {
      count += 2;
      if (count >= 36) {
        count = 36;
        clearInterval(countInterval);
      }
      setIngredientCount(count);
    }, 40);

    return () => clearInterval(countInterval);
  }, [currentStep]);

  if (!isOpen) return null;

  console.log('✅ AnalysisSimulationModal RENDERING - currentStep:', currentStep);

  const totalSteps = 6;
  const progress = ((currentStep + 1) / totalSteps) * 100;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm" onClick={onClose}>
      <div 
        className="bg-white rounded-2xl sm:rounded-3xl shadow-2xl max-w-lg sm:max-w-xl w-full mx-4 h-[90vh] sm:h-[85vh] flex flex-col relative overflow-hidden"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Close Button */}
        <button
          onClick={onClose}
          className="absolute top-4 right-4 sm:top-6 sm:right-6 w-9 h-9 sm:w-10 sm:h-10 rounded-full bg-white/90 hover:bg-white shadow-lg transition-colors flex items-center justify-center z-50"
        >
          <X className="w-4 h-4 sm:w-5 sm:h-5" style={{ color: '#475569' }} />
        </button>

        {/* Progress Bar */}
        <div className="absolute top-0 left-0 right-0 h-1 sm:h-1.5 bg-gray-200 z-40">
          <div 
            className="h-full transition-all duration-500 ease-out"
            style={{ 
              width: `${progress}%`,
              backgroundColor: '#2563EB'
            }}
          />
        </div>

        {/* Step Indicator */}
        <div className="absolute top-14 sm:top-16 left-1/2 -translate-x-1/2 z-40 px-4 py-2 rounded-full bg-white/90 backdrop-blur-sm shadow-lg">
          <div className="flex items-center gap-2">
            {[0, 1, 2, 3, 4, 5].map((step) => (
              <div
                key={step}
                className={`w-1.5 h-1.5 sm:w-2 sm:h-2 rounded-full transition-all duration-300 ${
                  step === currentStep 
                    ? 'w-6 sm:w-8' 
                    : ''
                }`}
                style={{ 
                  backgroundColor: step <= currentStep ? '#2563EB' : '#E5E7EB'
                }}
              />
            ))}
          </div>
        </div>

        {/* Content Container */}
        <div className="flex-1 relative overflow-hidden">
          <div
            className={`absolute inset-0 transition-all duration-500 ease-in-out ${
              isTransitioning ? 'opacity-0 scale-95' : 'opacity-100 scale-100'
            }`}
          >
            {/* Step 0: start screen */}
            {currentStep === 0 && (
              <div className="h-full flex flex-col items-center justify-center p-4 sm:p-8 text-center">
                <div className="w-14 h-14 sm:w-20 sm:h-20 rounded-full flex items-center justify-center mb-4 sm:mb-6 animate-pulse" style={{ backgroundColor: '#EFF6FF' }}>
                  <Loader2 className="w-7 h-7 sm:w-10 sm:h-10 animate-spin" style={{ color: '#2563EB' }} />
                </div>
                
                <h2 className="text-xl sm:text-3xl font-bold mb-3 sm:mb-4" style={{ color: '#0F172A' }}>
                  Analyzing the best food for Zeno
                </h2>
                <p className="text-sm sm:text-lg mb-6 sm:mb-8" style={{ color: '#475569' }}>
                  Maltese, 3 years old · 7.1 lb
                </p>

                <div className="bg-gradient-to-br from-gray-50 to-gray-100 rounded-xl sm:rounded-2xl p-3 sm:p-6 mb-6 sm:mb-8 max-w-md w-full">
                  <div className="flex items-center gap-3 sm:gap-4">
                    <div className="w-16 h-16 sm:w-24 sm:h-24 rounded-lg sm:rounded-xl overflow-hidden shadow-md bg-white flex-shrink-0">
                      <img
                        src={productImage}
                        alt="dog food"
                        className="w-full h-full object-contain"
                      />
                    </div>
                    <div className="flex-1 text-left">
                      <h3 className="text-sm sm:text-lg font-bold mb-1" style={{ color: '#0F172A' }}>
                        KibbleWise Adult Dog Food
                      </h3>
                      <p className="text-xs sm:text-sm" style={{ color: '#475569' }}>
                        Small Breed Adult · 4.4 lb
                      </p>
                    </div>
                  </div>
                </div>

                <div className="flex items-center gap-2 text-xs sm:text-sm" style={{ color: '#475569' }}>
                  <Loader2 className="w-3 h-3 sm:w-4 sm:h-4 animate-spin" style={{ color: '#2563EB' }} />
                  <span>Starting analysis...</span>
                </div>
              </div>
            )}

            {/* Step 1: ingredient scan */}
            {currentStep === 1 && (
              <div className="h-full flex flex-col items-center justify-center p-4 sm:p-8">
                <div className="w-14 h-14 sm:w-20 sm:h-20 rounded-full flex items-center justify-center mb-4 sm:mb-6" style={{ backgroundColor: '#EFF6FF' }}>
                  <CheckCircle className="w-7 h-7 sm:w-10 sm:h-10" style={{ color: '#14B8A6' }} />
                </div>
                
                <h2 className="text-xl sm:text-3xl font-bold mb-3 sm:mb-4 text-center" style={{ color: '#0F172A' }}>
                  Ingredient Scan Complete
                </h2>
                <p className="text-sm sm:text-lg mb-6 sm:mb-8 text-center" style={{ color: '#475569' }}>
                  Found {ingredientCount} total ingredients
                </p>

                <div className="w-full max-w-md space-y-3 sm:space-y-4 px-2">
                  <div className="bg-gradient-to-br from-blue-50 to-teal-50 rounded-xl sm:rounded-2xl p-5 sm:p-6 text-center">
                    <div className="text-4xl sm:text-6xl font-bold mb-2" style={{ color: '#2563EB' }}>
                      {ingredientCount}
                    </div>
                    <div className="text-sm sm:text-base font-semibold" style={{ color: '#475569' }}>
                      Detected Ingredients
                    </div>
                  </div>

                  <div className="bg-white rounded-lg sm:rounded-xl p-4 sm:p-5 border-2" style={{ borderColor: '#E5E7EB' }}>
                    <div className="text-xs sm:text-sm font-semibold mb-2 sm:mb-3" style={{ color: '#0F172A' }}>
                      Key Ingredients
                    </div>
                    <div className="flex flex-wrap gap-2">
                      {['Chicken', 'Brown Rice', 'Corn', 'Beet Pulp', 'Chicken Fat', 'Wheat'].map((ing) => (
                        <span key={ing} className="px-2.5 sm:px-3 py-1 sm:py-1.5 rounded-full text-xs font-medium bg-gray-100" style={{ color: '#475569' }}>
                          {ing}
                        </span>
                      ))}
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Step 2: allergen check */}
            {currentStep === 2 && (
              <div className="h-full flex flex-col items-center justify-center p-4 sm:p-8">
                <div className="w-14 h-14 sm:w-20 sm:h-20 rounded-full flex items-center justify-center mb-4 sm:mb-6" style={{ backgroundColor: '#ECFDF5' }}>
                  <CheckCircle className="w-7 h-7 sm:w-10 sm:h-10" style={{ color: '#14B8A6' }} />
                </div>
                
                <h2 className="text-xl sm:text-3xl font-bold mb-3 sm:mb-4 text-center" style={{ color: '#0F172A' }}>
                  Allergen Check Passed
                </h2>
                <p className="text-sm sm:text-lg mb-6 sm:mb-8 text-center" style={{ color: '#475569' }}>
                  Ingredients look safe for Zeno
                </p>

                <div className="w-full max-w-md space-y-3 sm:space-y-4 px-2">
                  <div className="bg-gradient-to-br from-emerald-50 to-teal-50 rounded-xl sm:rounded-2xl p-5 sm:p-6">
                    <div className="flex items-center justify-center gap-2 sm:gap-3 mb-5 sm:mb-6">
                      <div className="text-4xl sm:text-6xl font-bold" style={{ color: '#14B8A6' }}>
                        0
                      </div>
                      <div className="text-left">
                        <div className="text-xs sm:text-sm font-semibold" style={{ color: '#14B8A6' }}>
                          Allergen Hits
                        </div>
                        <div className="text-xs" style={{ color: '#475569' }}>
                          None detected
                        </div>
                      </div>
                    </div>

                    <div className="space-y-2 sm:space-y-3">
                      <div className="bg-white rounded-lg sm:rounded-xl p-3 sm:p-4 flex items-start gap-2 sm:gap-3">
                        <CheckCircle className="w-4 h-4 sm:w-5 sm:h-5 flex-shrink-0 mt-0.5" style={{ color: '#14B8A6' }} />
                        <div>
                          <div className="font-semibold text-xs sm:text-sm mb-0.5 sm:mb-1" style={{ color: '#0F172A' }}>Chicken Protein</div>
                          <div className="text-xs" style={{ color: '#475569' }}>Safe core protein for Zeno</div>
                        </div>
                      </div>
                      <div className="bg-white rounded-lg sm:rounded-xl p-3 sm:p-4 flex items-start gap-2 sm:gap-3">
                        <CheckCircle className="w-4 h-4 sm:w-5 sm:h-5 flex-shrink-0 mt-0.5" style={{ color: '#14B8A6' }} />
                        <div>
                          <div className="font-semibold text-xs sm:text-sm mb-0.5 sm:mb-1" style={{ color: '#0F172A' }}>Brown Rice & Oats</div>
                          <div className="text-xs" style={{ color: '#475569' }}>Digestible grain blend</div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Step 3: risk ingredient analysis */}
            {currentStep === 3 && (
              <div className="h-full flex flex-col items-center justify-center p-4 sm:p-8">
                <div className="w-14 h-14 sm:w-20 sm:h-20 rounded-full flex items-center justify-center mb-4 sm:mb-6" style={{ backgroundColor: '#FFF7ED' }}>
                  <Info className="w-7 h-7 sm:w-10 sm:h-10" style={{ color: '#F97316' }} />
                </div>
                
                <h2 className="text-xl sm:text-3xl font-bold mb-3 sm:mb-4 text-center" style={{ color: '#0F172A' }}>
                  Caution Ingredient Found
                </h2>
                <p className="text-sm sm:text-lg mb-6 sm:mb-8 text-center" style={{ color: '#475569' }}>
                  Preservative and additive review
                </p>

                <div className="w-full max-w-md px-2">
                  <div className="bg-gradient-to-br from-orange-50 to-yellow-50 rounded-xl sm:rounded-2xl p-4 sm:p-6">
                    <div className="bg-white rounded-lg sm:rounded-xl p-4 sm:p-5">
                      <div className="flex items-start gap-2 sm:gap-3">
                        <div className="w-9 h-9 sm:w-10 sm:h-10 rounded-full flex items-center justify-center flex-shrink-0" style={{ backgroundColor: '#FFF7ED' }}>
                          <AlertCircle className="w-4 h-4 sm:w-5 sm:h-5" style={{ color: '#F97316' }} />
                        </div>
                        <div className="flex-1">
                          <div className="font-bold text-sm sm:text-base mb-1 sm:mb-2" style={{ color: '#0F172A' }}>
                            BHA (Butylated Hydroxyanisole)
                          </div>
                          <div className="text-xs sm:text-sm leading-relaxed" style={{ color: '#475569' }}>
                            A synthetic preservative that should be limited in long-term use
                          </div>
                          <div className="mt-3 sm:mt-4 px-2.5 sm:px-3 py-1.5 sm:py-2 rounded-lg inline-block text-xs font-semibold" style={{ backgroundColor: '#FFF7ED', color: '#F97316' }}>
                            Long-term use caution
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Step 4: quality scoring */}
            {currentStep === 4 && (
              <div className="h-full flex flex-col items-center justify-center p-4 sm:p-8">
                <div className="w-14 h-14 sm:w-20 sm:h-20 rounded-full flex items-center justify-center mb-4 sm:mb-6" style={{ backgroundColor: '#EFF6FF' }}>
                  <Shield className="w-7 h-7 sm:w-10 sm:h-10" style={{ color: '#2563EB' }} />
                </div>
                
                <h2 className="text-xl sm:text-3xl font-bold mb-3 sm:mb-4 text-center" style={{ color: '#0F172A' }}>
                  Quality Review Complete
                </h2>
                <p className="text-sm sm:text-lg mb-6 sm:mb-8 text-center" style={{ color: '#475569' }}>
                  Nutrition balance and quality check
                </p>

                <div className="w-full max-w-md px-2">
                  <div className="bg-gradient-to-br from-blue-50 to-teal-50 rounded-xl sm:rounded-2xl p-4 sm:p-6">
                    <div className="space-y-2 sm:space-y-3">
                      <div className="bg-white rounded-lg sm:rounded-xl p-3 sm:p-4 flex items-start gap-2 sm:gap-3">
                        <CheckCircle className="w-4 h-4 sm:w-5 sm:h-5 flex-shrink-0 mt-0.5" style={{ color: '#14B8A6' }} />
                        <div>
                          <div className="font-semibold text-xs sm:text-sm" style={{ color: '#0F172A' }}>
                            First ingredient: animal protein (chicken)
                          </div>
                        </div>
                      </div>
                      <div className="bg-white rounded-lg sm:rounded-xl p-3 sm:p-4 flex items-start gap-2 sm:gap-3">
                        <CheckCircle className="w-4 h-4 sm:w-5 sm:h-5 flex-shrink-0 mt-0.5" style={{ color: '#14B8A6' }} />
                        <div>
                          <div className="font-semibold text-xs sm:text-sm" style={{ color: '#0F172A' }}>
                            Protein level: within target range
                          </div>
                        </div>
                      </div>
                      <div className="bg-white rounded-lg sm:rounded-xl p-3 sm:p-4 flex items-start gap-2 sm:gap-3">
                        <CheckCircle className="w-4 h-4 sm:w-5 sm:h-5 flex-shrink-0 mt-0.5" style={{ color: '#14B8A6' }} />
                        <div>
                          <div className="font-semibold text-xs sm:text-sm" style={{ color: '#0F172A' }}>
                            Daily suggested serving: about 2.4 oz
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Step 5: final assessment */}
            {currentStep === 5 && (
              <div className="h-full flex flex-col overflow-y-auto pt-14 sm:pt-20">
                <div className="flex-1 flex flex-col items-center justify-center p-3 sm:p-8">
                  <div className="w-full max-w-md">
                    {/* Score card */}
                    <div className="bg-gradient-to-br from-blue-500 to-teal-500 rounded-xl sm:rounded-2xl p-5 sm:p-8 text-white text-center mb-4 sm:mb-6">
                      <div className="flex items-center justify-center gap-3 sm:gap-4 mb-4 sm:mb-6">
                        <Award className="w-8 h-8 sm:w-12 sm:h-12" />
                        <div className="text-left">
                          <h3 className="text-lg sm:text-2xl font-bold">Final Assessment</h3>
                          <p className="text-xs sm:text-sm opacity-90">AI-powered personalized analysis</p>
                        </div>
                      </div>
                      
                      <div className="bg-white/10 backdrop-blur-sm rounded-xl p-4 sm:p-6">
                        <div className="text-5xl sm:text-7xl font-bold mb-1 sm:mb-2">85</div>
                        <div className="text-sm sm:text-lg font-semibold mb-3 sm:mb-4">out of 100</div>
                        <div className="inline-block px-4 sm:px-6 py-1.5 sm:py-2 rounded-full text-xs sm:text-sm font-bold bg-white/20">
                          Great fit for Zeno
                        </div>
                      </div>
                    </div>

                    {/* Positive highlights */}
                    <div className="bg-gradient-to-br from-blue-50 to-teal-50 rounded-xl sm:rounded-2xl p-4 sm:p-6 mb-4 sm:mb-6">
                      <div className="font-bold text-base sm:text-lg mb-3 sm:mb-4" style={{ color: '#0F172A' }}>
                        Why this works for Zeno
                      </div>
                      <div className="space-y-2 sm:space-y-3">
                        <div className="flex items-start gap-2 sm:gap-3 p-3 sm:p-4 bg-white rounded-lg sm:rounded-xl">
                          <div className="w-5 h-5 sm:w-6 sm:h-6 rounded-full flex items-center justify-center flex-shrink-0" style={{ backgroundColor: '#DBEAFE' }}>
                            <span className="text-xs font-bold" style={{ color: '#2563EB' }}>1</span>
                          </div>
                          <p className="text-xs sm:text-sm" style={{ color: '#475569' }}>
                            No known allergen triggers detected for Zeno
                          </p>
                        </div>
                        <div className="flex items-start gap-2 sm:gap-3 p-3 sm:p-4 bg-white rounded-lg sm:rounded-xl">
                          <div className="w-5 h-5 sm:w-6 sm:h-6 rounded-full flex items-center justify-center flex-shrink-0" style={{ backgroundColor: '#DBEAFE' }}>
                            <span className="text-xs font-bold" style={{ color: '#2563EB' }}>2</span>
                          </div>
                          <p className="text-xs sm:text-sm" style={{ color: '#475569' }}>
                            Animal protein is the first ingredient
                          </p>
                        </div>
                        <div className="flex items-start gap-2 sm:gap-3 p-3 sm:p-4 bg-white rounded-lg sm:rounded-xl">
                          <div className="w-5 h-5 sm:w-6 sm:h-6 rounded-full flex items-center justify-center flex-shrink-0" style={{ backgroundColor: '#DBEAFE' }}>
                            <span className="text-xs font-bold" style={{ color: '#2563EB' }}>3</span>
                          </div>
                          <p className="text-xs sm:text-sm" style={{ color: '#475569' }}>
                            Nutrition profile suits small adult dogs
                          </p>
                        </div>
                      </div>
                    </div>

                    {/* CTA */}
                    <a
                      href="https://forms.gle/sniAUJaSQktvAjzH6"
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex items-center justify-center gap-2 w-full py-3 sm:py-4 rounded-lg sm:rounded-xl text-white font-semibold text-center shadow-lg hover:shadow-xl transition-all text-sm sm:text-lg group"
                      style={{ backgroundColor: '#2563EB' }}
                    >
                      Get More Food Insights
                      <ArrowRight className="w-4 h-4 sm:w-5 sm:h-5 group-hover:translate-x-1 transition-transform" />
                    </a>
                    <p className="text-xs text-center mt-2 sm:mt-3" style={{ color: '#94A3B8' }}>
                      Join early access and get 1,000 bonus points
                    </p>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      <style>{`
        @keyframes slide-in {
          from { 
            opacity: 0; 
            transform: translateX(30px);
          }
          to { 
            opacity: 1; 
            transform: translateX(0);
          }
        }
      `}</style>
    </div>
  );
}