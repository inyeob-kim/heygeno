import { Check } from 'lucide-react';
import { PremiumPhoneMockup } from './PremiumPhoneMockup';
import { useLanguage } from '../contexts/LanguageContext';

interface HeroSectionProps {
  onOpenModal?: () => void;
  onOpenPriceModal?: () => void;
}

export function HeroSection({ onOpenModal, onOpenPriceModal }: HeroSectionProps) {
  const { t } = useLanguage();
  
  return (
    <section className="pt-20 sm:pt-24 lg:pt-32 pb-16 sm:pb-20 lg:pb-28 px-4 sm:px-6 w-full overflow-x-hidden bg-white">
      <div className="max-w-7xl mx-auto w-full">
        <div className="grid lg:grid-cols-2 gap-12 lg:gap-16 items-center w-full">
          {/* Left Column: Content */}
          <div className="space-y-8 sm:space-y-10 w-full max-w-xl">
            {/* Brand Label */}
            <div className="inline-block">
              <div 
                className="text-xs sm:text-sm font-semibold tracking-wider uppercase"
                style={{ color: '#2563EB', letterSpacing: '0.1em' }}
              >
                {t('hero.brand')}
              </div>
            </div>

            {/* Headline */}
            <div className="space-y-4">
              <h1 className="text-3xl sm:text-4xl lg:text-5xl font-bold leading-tight" style={{ color: '#0F172A' }}>
                {t('hero.headline1')}{' '}
                <span style={{ color: '#2563EB' }}>{t('hero.headline2')}</span>{t('hero.headline3')}<br />
                {t('hero.headline4')}{' '}
                <span style={{ color: '#2563EB' }}>{t('hero.headline5')}</span>{t('hero.headline6')}
              </h1>
            </div>

            {/* Subheadline */}
            <div className="space-y-3">
              <p className="text-lg sm:text-xl leading-relaxed" style={{ color: '#475569' }}>
                {t('hero.subheadline1')}<br />
                {t('hero.subheadline2')}<br />
                {t('hero.subheadline3')}
              </p>
            </div>

            {/* CTA Buttons */}
            <div className="space-y-3 sm:space-y-4 w-full">
              <button
                onClick={() => window.open('https://forms.gle/sniAUJaSQktvAjzH6', '_blank')}
                className="w-full sm:w-auto px-8 py-4 rounded-xl text-white font-semibold text-base sm:text-lg shadow-lg hover:shadow-xl transition-all whitespace-nowrap"
                style={{ backgroundColor: '#2563EB' }}
              >
                {t('hero.cta.primary')}
              </button>
              
              <button
                onClick={() => window.open('https://forms.gle/sniAUJaSQktvAjzH6', '_blank')}
                className="w-full sm:w-auto px-8 py-4 rounded-xl font-semibold text-base sm:text-lg border-2 hover:bg-gray-50 transition-all whitespace-nowrap ml-0 sm:ml-3"
                style={{ color: '#475569', borderColor: '#E5E7EB' }}
              >
                {t('hero.cta.secondary')}
              </button>
            </div>

            {/* Benefit Bullets */}
            <div className="pt-4 sm:pt-6 space-y-3">
              <div className="flex items-center gap-3">
                <div className="w-5 h-5 rounded-full flex items-center justify-center flex-shrink-0" style={{ backgroundColor: '#DBEAFE' }}>
                  <Check className="w-3 h-3" style={{ color: '#2563EB' }} />
                </div>
                <span className="text-sm sm:text-base" style={{ color: '#475569' }}>
                  {t('hero.benefit1')}
                </span>
              </div>
              
              <div className="flex items-center gap-3">
                <div className="w-5 h-5 rounded-full flex items-center justify-center flex-shrink-0" style={{ backgroundColor: '#DBEAFE' }}>
                  <Check className="w-3 h-3" style={{ color: '#2563EB' }} />
                </div>
                <span className="text-sm sm:text-base" style={{ color: '#475569' }}>
                  {t('hero.benefit2')}
                </span>
              </div>
              
              <div className="flex items-center gap-3">
                <div className="w-5 h-5 rounded-full flex items-center justify-center flex-shrink-0" style={{ backgroundColor: '#DBEAFE' }}>
                  <Check className="w-3 h-3" style={{ color: '#2563EB' }} />
                </div>
                <span className="text-sm sm:text-base" style={{ color: '#475569' }}>
                  {t('hero.benefit3')}
                </span>
              </div>
            </div>
          </div>

          {/* Right Column: Phone Mockup */}
          <div className="w-full flex justify-center lg:justify-end mt-8 lg:mt-0">
            <PremiumPhoneMockup 
              onOpenModal={onOpenModal}
              onOpenPriceModal={onOpenPriceModal}
            />
          </div>
        </div>
      </div>
    </section>
  );
}