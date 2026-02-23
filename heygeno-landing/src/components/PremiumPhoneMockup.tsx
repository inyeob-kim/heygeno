import { AlertCircle, TrendingDown } from 'lucide-react';
import { useLanguage } from '../contexts/LanguageContext';

interface PremiumPhoneMockupProps {
  onOpenModal?: () => void;
  onOpenPriceModal?: () => void;
}

export function PremiumPhoneMockup({ onOpenModal, onOpenPriceModal }: PremiumPhoneMockupProps) {
  const { t } = useLanguage();
  
  return (
    <div className="relative w-full max-w-[280px] sm:max-w-[320px]">
      {/* Phone Frame */}
      <div 
        className="relative mx-auto transition-transform hover:scale-105 duration-500 ease-out"
        style={{ 
          width: '100%',
          maxWidth: '320px',
          aspectRatio: '1/2',
          filter: 'drop-shadow(0 20px 60px rgba(37, 99, 235, 0.15))'
        }}
      >
        <div className="absolute inset-0 bg-gray-900 rounded-[2.5rem] sm:rounded-[3rem] p-2 sm:p-3">
          <div className="bg-white h-full rounded-[2rem] sm:rounded-[2.5rem] overflow-hidden flex flex-col">
            {/* Status Bar */}
            <div className="h-10 sm:h-12 flex items-center justify-between px-4 sm:px-6 pt-2 flex-shrink-0">
              <div className="text-xs font-semibold" style={{ color: '#0F172A' }}>9:41</div>
              <div className="flex gap-1">
                <div className="w-4 h-3 bg-gray-300 rounded-sm"></div>
                <div className="w-4 h-3 bg-gray-300 rounded-sm"></div>
                <div className="w-4 h-3 bg-gray-300 rounded-sm"></div>
              </div>
            </div>

            {/* Top Label */}
            <div className="px-4 sm:px-5 pb-2 flex-shrink-0">
              <div className="inline-block px-3 py-1 rounded-full text-xs font-medium" style={{ backgroundColor: '#EFF6FF', color: '#2563EB' }}>
                {t('hero.phone.prelaunch')}
              </div>
            </div>

            {/* Scrollable Content */}
            <div className="flex-1 overflow-y-auto px-4 sm:px-5 pb-4 space-y-3 sm:space-y-4 scrollbar-hide">
              {/* Header */}
              <div>
                <div className="text-xs font-medium mb-1" style={{ color: '#475569' }}>
                  Royal Canin Mini Adult
                </div>
                <div className="text-xl sm:text-2xl font-bold" style={{ color: '#0F172A' }}>
                  {t('hero.phone.score')}
                </div>
              </div>

              {/* Score Card - Clickable */}
              <div 
                onClick={(e) => {
                  e.stopPropagation();
                  onOpenModal?.();
                }}
                className="bg-gradient-to-br from-blue-50 to-blue-100 rounded-xl sm:rounded-2xl p-4 sm:p-6 text-center border-2 cursor-pointer hover:border-blue-400 hover:shadow-lg active:scale-95 transition-all relative group" 
                style={{ borderColor: '#2563EB' }}
              >
                <div className="text-5xl sm:text-6xl font-bold mb-2" style={{ color: '#2563EB' }}>
                  85
                </div>
                <div className="text-xs sm:text-sm font-medium" style={{ color: '#475569' }}>
                  {t('hero.phone.scoreMax')}
                </div>
                
                {/* Hover Label */}
                <div className="absolute -top-2 -right-2 bg-blue-500 text-white text-xs font-bold px-2 py-1 rounded-full opacity-0 group-hover:opacity-100 transition-opacity animate-pulse">
                  {t('hero.phone.clickAnalysis')}
                </div>
              </div>

              {/* Warning Alert */}
              <div className="bg-red-50 rounded-lg sm:rounded-xl p-3 sm:p-4 border-2" style={{ borderColor: '#EF4444' }}>
                <div className="flex items-start gap-2 sm:gap-3">
                  <AlertCircle className="w-4 h-4 sm:w-5 sm:h-5 flex-shrink-0 mt-0.5" style={{ color: '#EF4444' }} />
                  <div>
                    <div className="text-xs sm:text-sm font-semibold mb-1" style={{ color: '#EF4444' }}>
                      {t('hero.phone.warning')}
                    </div>
                    <div className="text-xs" style={{ color: '#475569' }}>
                      Contains BHA and ethoxyquin
                    </div>
                  </div>
                </div>
              </div>

              {/* Price Comparison - Clickable */}
              <div className="space-y-2">
                <div className="text-sm font-semibold" style={{ color: '#0F172A' }}>
                  {t('hero.phone.priceCompare')}
                </div>
                
                <div 
                  onClick={(e) => {
                    e.stopPropagation();
                    onOpenPriceModal?.();
                  }}
                  className="bg-teal-50 rounded-lg p-3 border-2 cursor-pointer hover:border-teal-400 hover:shadow-lg active:scale-95 transition-all relative group" 
                  style={{ borderColor: '#14B8A6' }}
                >
                  <div className="flex items-center justify-between">
                    <div>
                      <div className="text-xs font-medium mb-1" style={{ color: '#475569' }}>
                        Amazon
                      </div>
                      <div className="text-base sm:text-lg font-bold" style={{ color: '#14B8A6' }}>
                        $42.90
                      </div>
                    </div>
                    <div className="px-2 sm:px-3 py-1 rounded-full text-xs font-semibold text-white" style={{ backgroundColor: '#14B8A6' }}>
                      {t('hero.phone.lowest')}
                    </div>
                  </div>
                  
                  {/* Hover Label */}
                  <div className="absolute -top-2 -right-2 bg-teal-500 text-white text-xs font-bold px-2 py-1 rounded-full opacity-0 group-hover:opacity-100 transition-opacity animate-pulse">
                    {t('hero.phone.clickAlert')}
                  </div>
                </div>

                <div className="bg-gray-50 rounded-lg p-3">
                  <div className="flex items-center justify-between">
                    <div>
                      <div className="text-xs font-medium mb-1" style={{ color: '#475569' }}>
                        Chewy
                      </div>
                      <div className="text-base sm:text-lg font-bold" style={{ color: '#0F172A' }}>
                        $46.50
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Bottom Label */}
            <div className="px-4 sm:px-5 py-3 border-t flex-shrink-0" style={{ borderColor: '#F1F5F9' }}>
              <div className="text-center text-xs font-medium" style={{ color: '#94A3B8' }}>
                {t('hero.phone.launch')}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Subtle Decorative Gradient */}
      <div 
        className="absolute -z-10 top-1/4 left-1/2 -translate-x-1/2 w-64 h-64 rounded-full opacity-10 pointer-events-none" 
        style={{ 
          backgroundColor: '#2563EB', 
          filter: 'blur(80px)' 
        }}
      />
    </div>
  );
}