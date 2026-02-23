import { useState, useEffect } from 'react';
import { X, TrendingDown, Bell, Check, DollarSign, ShoppingCart } from 'lucide-react';
import productImage from 'figma:asset/1f513950e90391a568bd6fbe59d74c33c122cf66.png';

interface PriceAlertModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export function PriceAlertModal({ isOpen, onClose }: PriceAlertModalProps) {
  const [currentStep, setCurrentStep] = useState(0);
  const [showNotification, setShowNotification] = useState(false);
  const [chartProgress, setChartProgress] = useState(0);
  const [isTransitioning, setIsTransitioning] = useState(false);

  useEffect(() => {
    if (!isOpen) {
      setCurrentStep(0);
      setShowNotification(false);
      setChartProgress(0);
      return;
    }

    // Reset state on open
    setCurrentStep(0);
    setShowNotification(false);
    setChartProgress(0);

    // Step transitions
    const stepTimers = [
      setTimeout(() => goToStep(1), 2000),  // Step 1: show chart
      setTimeout(() => goToStep(2), 5000),  // Step 2: price drop detected
      setTimeout(() => goToStep(3), 7500),  // Step 3: send notification
    ];

    return () => {
      stepTimers.forEach(timer => clearTimeout(timer));
    };
  }, [isOpen]);

  // Chart progress animation for step 1
  useEffect(() => {
    if (currentStep !== 1) return;

    let progress = 0;
    const chartInterval = setInterval(() => {
      progress += 2;
      if (progress >= 100) {
        progress = 100;
        clearInterval(chartInterval);
      }
      setChartProgress(progress);
    }, 20);

    return () => clearInterval(chartInterval);
  }, [currentStep]);

  // Show notification animation for step 3
  useEffect(() => {
    if (currentStep === 3) {
      setTimeout(() => setShowNotification(true), 300);
    }
  }, [currentStep]);

  const goToStep = (step: number) => {
    setIsTransitioning(true);
    setTimeout(() => {
      setCurrentStep(step);
      setIsTransitioning(false);
    }, 300);
  };

  if (!isOpen) return null;

  // Price data for graph (30 days, in USD cents)
  const priceData = [
    4999, 4950, 5020, 4980, 5050, 5010, 4970, 4990,
    5030, 5000, 4960, 4980, 5040, 5020, 4990, 5010,
    4970, 4950, 5000, 4980, 4940, 4960, 4920, 4890,
    4870, 4850, 4820, 4790, 4760, 4729
  ];

  const maxPrice = Math.max(...priceData);
  const minPrice = Math.min(...priceData);
  const currentPrice = priceData[priceData.length - 1];
  const originalPrice = priceData[0];
  const discount = ((originalPrice - currentPrice) / originalPrice * 100).toFixed(0);
  const formatUsd = (valueInCents: number) => `$${(valueInCents / 100).toFixed(2)}`;

  const totalSteps = 4;
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
            {[0, 1, 2, 3].map((step) => (
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
              <div className="h-full flex flex-col items-center justify-center p-6 sm:p-12 text-center">
                <div className="w-16 h-16 sm:w-20 sm:h-20 rounded-full flex items-center justify-center mb-6 sm:mb-8 animate-pulse" style={{ backgroundColor: '#EFF6FF' }}>
                  <DollarSign className="w-8 h-8 sm:w-10 sm:h-10" style={{ color: '#2563EB' }} />
                </div>
                
                <h2 className="text-2xl sm:text-3xl lg:text-4xl font-bold mb-4" style={{ color: '#0F172A' }}>
                  Best Price Tracking Started
                </h2>
                <p className="text-base sm:text-lg mb-8" style={{ color: '#475569' }}>
                  KibbleWise is now monitoring prices automatically
                </p>

                <div className="bg-gradient-to-br from-gray-50 to-gray-100 rounded-xl sm:rounded-2xl p-6 mb-8 max-w-md">
                  <div className="flex items-center gap-4 mb-6">
                    <div className="w-20 h-20 sm:w-24 sm:h-24 rounded-xl overflow-hidden shadow-md bg-white flex-shrink-0">
                      <img
                        src={productImage}
                        alt="dog food"
                        className="w-full h-full object-contain"
                      />
                    </div>
                    <div className="flex-1 text-left">
                      <h3 className="text-base sm:text-lg font-bold mb-1" style={{ color: '#0F172A' }}>
                        KibbleWise Adult Dog Food
                      </h3>
                      <p className="text-xs sm:text-sm mb-2" style={{ color: '#475569' }}>
                        Small Breed Adult · 4.4 lb
                      </p>
                    </div>
                  </div>

                  <div className="grid grid-cols-3 gap-3">
                    <div className="bg-white rounded-lg p-3 text-center">
                      <div className="text-xs mb-1" style={{ color: '#475569' }}>Amazon</div>
                      <div className="text-sm font-bold" style={{ color: '#0F172A' }}>$49.99</div>
                    </div>
                    <div className="bg-white rounded-lg p-3 text-center">
                      <div className="text-xs mb-1" style={{ color: '#475569' }}>Chewy</div>
                      <div className="text-sm font-bold" style={{ color: '#0F172A' }}>$50.49</div>
                    </div>
                    <div className="bg-white rounded-lg p-3 text-center">
                      <div className="text-xs mb-1" style={{ color: '#475569' }}>Petco</div>
                      <div className="text-sm font-bold" style={{ color: '#0F172A' }}>$50.99</div>
                    </div>
                  </div>
                </div>

                <div className="flex items-center gap-2 text-sm" style={{ color: '#475569' }}>
                  <TrendingDown className="w-4 h-4" style={{ color: '#2563EB' }} />
                  <span>Tracking price movement...</span>
                </div>
              </div>
            )}

            {/* Step 1: price graph */}
            {currentStep === 1 && (
              <div className="h-full flex flex-col items-center justify-center p-6 sm:p-12">
                <h2 className="text-2xl sm:text-3xl lg:text-4xl font-bold mb-4 text-center" style={{ color: '#0F172A' }}>
                  30-Day Price Trend
                </h2>
                <p className="text-base sm:text-lg mb-8 text-center" style={{ color: '#475569' }}>
                  Amazon pricing trend over the past month
                </p>

                <div className="w-full max-w-md">
                  <div className="bg-gradient-to-br from-blue-50 to-gray-50 rounded-2xl p-6">
                    {/* Price Info */}
                    <div className="flex items-center justify-between mb-6">
                      <div>
                        <div className="text-xs mb-1" style={{ color: '#475569' }}>Current Price</div>
                        <div className="text-2xl sm:text-3xl font-bold" style={{ color: '#2563EB' }}>
                          {formatUsd(currentPrice)}
                        </div>
                      </div>
                      <div className="text-right">
                        <div className="text-xs mb-1" style={{ color: '#475569' }}>vs 30 Days Ago</div>
                        <div className="text-xl sm:text-2xl font-bold" style={{ color: '#EF4444' }}>
                          -{discount}%
                        </div>
                      </div>
                    </div>

                    {/* Chart */}
                    <div className="bg-white rounded-xl p-4 mb-4 relative h-48 overflow-hidden">
                      <svg width="100%" height="100%" viewBox="0 0 400 160" preserveAspectRatio="none">
                        {/* Grid lines */}
                        {[0, 1, 2, 3, 4].map((i) => (
                          <line
                            key={i}
                            x1="0"
                            y1={i * 40}
                            x2="400"
                            y2={i * 40}
                            stroke="#E5E7EB"
                            strokeWidth="1"
                          />
                        ))}
                        
                        {/* Price line */}
                        <polyline
                          points={priceData.map((price, i) => {
                            const x = (i / (priceData.length - 1)) * 400;
                            const y = 160 - ((price - minPrice) / (maxPrice - minPrice)) * 140 - 10;
                            return `${x},${y}`;
                          }).join(' ')}
                          fill="none"
                          stroke="#2563EB"
                          strokeWidth="3"
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          style={{
                            strokeDasharray: 1000,
                            strokeDashoffset: 1000 - (chartProgress * 10),
                            transition: 'stroke-dashoffset 0.05s linear'
                          }}
                        />
                        
                        {/* Gradient fill */}
                        <defs>
                          <linearGradient id="priceGradient" x1="0%" y1="0%" x2="0%" y2="100%">
                            <stop offset="0%" stopColor="#2563EB" stopOpacity="0.2" />
                            <stop offset="100%" stopColor="#2563EB" stopOpacity="0" />
                          </linearGradient>
                        </defs>
                        <polygon
                          points={`0,160 ${priceData.map((price, i) => {
                            const x = (i / (priceData.length - 1)) * 400;
                            const y = 160 - ((price - minPrice) / (maxPrice - minPrice)) * 140 - 10;
                            return `${x},${y}`;
                          }).join(' ')} 400,160`}
                          fill="url(#priceGradient)"
                          style={{
                            clipPath: `inset(0 ${100 - chartProgress}% 0 0)`
                          }}
                        />
                      </svg>
                    </div>

                    {/* Timeline */}
                    <div className="flex justify-between text-xs" style={{ color: '#94A3B8' }}>
                      <span>30 days ago</span>
                      <span>Today</span>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Step 2: price drop detected */}
            {currentStep === 2 && (
              <div className="h-full flex flex-col items-center justify-center p-6 sm:p-12">
                <div className="w-16 h-16 sm:w-20 sm:h-20 rounded-full flex items-center justify-center mb-6 sm:mb-8 animate-bounce" style={{ backgroundColor: '#FEF2F2' }}>
                  <TrendingDown className="w-8 h-8 sm:w-10 sm:h-10" style={{ color: '#EF4444' }} />
                </div>
                
                <h2 className="text-2xl sm:text-3xl lg:text-4xl font-bold mb-4 text-center" style={{ color: '#0F172A' }}>
                  Price Drop Detected!
                </h2>
                <p className="text-base sm:text-lg mb-8 text-center" style={{ color: '#475569' }}>
                  The price is now below your target
                </p>

                <div className="w-full max-w-md">
                  <div className="bg-gradient-to-br from-red-50 to-orange-50 rounded-2xl p-6">
                    <div className="bg-white rounded-xl p-6 text-center mb-4">
                      <div className="text-sm mb-2" style={{ color: '#475569' }}>
                        Amazon Best Price
                      </div>
                      <div className="flex items-center justify-center gap-2 mb-3">
                        <div className="text-2xl line-through" style={{ color: '#94A3B8' }}>
                          $49.99
                        </div>
                        <div className="text-4xl font-bold" style={{ color: '#EF4444' }}>
                          $47.29
                        </div>
                      </div>
                      <div className="inline-block px-4 py-2 rounded-full text-sm font-bold" style={{ backgroundColor: '#FEE2E2', color: '#EF4444' }}>
                        Save $2.70 (5% off)
                      </div>
                    </div>

                    <div className="grid grid-cols-2 gap-3">
                      <div className="bg-white rounded-xl p-4">
                        <div className="flex items-center gap-2 mb-2">
                          <TrendingDown className="w-4 h-4" style={{ color: '#EF4444' }} />
                          <div className="text-xs font-semibold" style={{ color: '#475569' }}>Lowest Price</div>
                        </div>
                        <div className="text-lg font-bold" style={{ color: '#0F172A' }}>
                          $47.29
                        </div>
                      </div>
                      <div className="bg-white rounded-xl p-4">
                        <div className="flex items-center gap-2 mb-2">
                          <ShoppingCart className="w-4 h-4" style={{ color: '#2563EB' }} />
                          <div className="text-xs font-semibold" style={{ color: '#475569' }}>Retailer</div>
                        </div>
                        <div className="text-lg font-bold" style={{ color: '#0F172A' }}>
                          Amazon
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Step 3: notification sent */}
            {currentStep === 3 && (
              <div className="h-full flex flex-col items-center justify-center p-6 sm:p-12 relative overflow-hidden">
                {/* Notification Animation */}
                {showNotification && (
                  <div 
                    className="absolute top-24 sm:top-28 left-1/2 -translate-x-1/2 w-full max-w-sm px-4 z-10"
                    style={{
                      animation: 'slideDown 0.5s ease-out'
                    }}
                  >
                    <div className="bg-white rounded-2xl shadow-2xl border-2 overflow-hidden" style={{ borderColor: '#2563EB' }}>
                      <div className="bg-gradient-to-r from-blue-500 to-teal-500 p-4 flex items-center gap-3">
                        <div className="w-10 h-10 rounded-full bg-white/20 flex items-center justify-center">
                          <Bell className="w-5 h-5 text-white animate-pulse" />
                        </div>
                        <div className="flex-1 text-white">
                          <div className="font-bold text-sm">KibbleWise</div>
                          <div className="text-xs opacity-90">Now · Price Alert</div>
                        </div>
                      </div>
                      <div className="p-4">
                        <div className="font-bold text-base mb-2" style={{ color: '#0F172A' }}>
                          Price just dropped below your target!
                        </div>
                        <div className="flex items-center gap-3 mb-3">
                          <div className="w-12 h-12 rounded-lg overflow-hidden bg-gray-100 flex-shrink-0">
                            <img src={productImage} alt="dog food" className="w-full h-full object-contain" />
                          </div>
                          <div className="flex-1">
                            <div className="text-sm font-semibold mb-1" style={{ color: '#0F172A' }}>
                              KibbleWise Adult Dog Food
                            </div>
                            <div className="text-lg font-bold" style={{ color: '#EF4444' }}>
                              $47.29
                            </div>
                          </div>
                        </div>
                        <div className="bg-blue-50 rounded-lg p-3 text-xs" style={{ color: '#2563EB' }}>
                          <div className="flex items-center gap-1">
                            <Check className="w-3 h-3" />
                            <span className="font-semibold">Now $2.70 lower on Amazon</span>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                )}

                <div className="mt-80 sm:mt-96 w-full max-w-md">
                  <div className="text-center mb-6">
                    <h2 className="text-2xl sm:text-3xl font-bold mb-4" style={{ color: '#0F172A' }}>
                      Real-Time Alert Sent
                    </h2>
                    <p className="text-base" style={{ color: '#475569' }}>
                      Instant alerts were sent via app push and SMS
                    </p>
                  </div>

                  <div className="bg-gradient-to-br from-blue-50 to-teal-50 rounded-2xl p-6">
                    <div className="space-y-3">
                      <div className="bg-white rounded-xl p-4 flex items-center gap-3">
                        <div className="w-10 h-10 rounded-full flex items-center justify-center" style={{ backgroundColor: '#EFF6FF' }}>
                          <Check className="w-5 h-5" style={{ color: '#14B8A6' }} />
                        </div>
                        <div className="flex-1">
                          <div className="font-semibold text-sm" style={{ color: '#0F172A' }}>
                            App Push Notification
                          </div>
                          <div className="text-xs" style={{ color: '#475569' }}>
                            Sent successfully
                          </div>
                        </div>
                      </div>
                      <div className="bg-white rounded-xl p-4 flex items-center gap-3">
                        <div className="w-10 h-10 rounded-full flex items-center justify-center" style={{ backgroundColor: '#FFF7ED' }}>
                          <Check className="w-5 h-5" style={{ color: '#14B8A6' }} />
                        </div>
                        <div className="flex-1">
                          <div className="font-semibold text-sm" style={{ color: '#0F172A' }}>
                            SMS Alert
                          </div>
                          <div className="text-xs" style={{ color: '#475569' }}>
                            Message delivered
                          </div>
                        </div>
                      </div>
                    </div>

                    <div className="mt-6">
                      <a
                        href="https://forms.gle/sniAUJaSQktvAjzH6"
                        target="_blank"
                        rel="noopener noreferrer"
                        className="flex items-center justify-center gap-2 w-full py-4 rounded-xl text-white font-semibold text-center shadow-lg hover:shadow-xl transition-all text-base sm:text-lg group"
                        style={{ backgroundColor: '#2563EB' }}
                      >
                        Get Price Alerts
                        <Bell className="w-5 h-5 group-hover:scale-110 transition-transform" />
                      </a>
                      <p className="text-xs text-center mt-3" style={{ color: '#94A3B8' }}>
                        Join early access and get 1,000 bonus points
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      <style>{`
        @keyframes slideDown {
          from { 
            opacity: 0; 
            transform: translateX(-50%) translateY(-30px);
          }
          to { 
            opacity: 1; 
            transform: translateX(-50%) translateY(0);
          }
        }
      `}</style>
    </div>
  );
}