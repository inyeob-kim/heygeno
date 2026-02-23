import { Gift } from 'lucide-react';
import { useLanguage } from '../contexts/LanguageContext';

export function FinalReinforcementCTA() {
  const { t } = useLanguage();
  
  return (
    <section className="py-20 sm:py-24 lg:py-32 px-4 sm:px-6 lg:px-8 relative overflow-hidden w-full" style={{ backgroundColor: '#1E3A8A' }}>
      {/* Background Pattern */}
      <div className="absolute inset-0 opacity-10">
        <div className="absolute top-0 left-0 w-64 h-64 sm:w-96 sm:h-96 rounded-full" style={{ background: 'radial-gradient(circle, #60A5FA 0%, transparent 70%)' }}></div>
        <div className="absolute bottom-0 right-0 w-64 h-64 sm:w-96 sm:h-96 rounded-full" style={{ background: 'radial-gradient(circle, #14B8A6 0%, transparent 70%)' }}></div>
      </div>

      <div className="max-w-4xl mx-auto text-center relative z-10 w-full">
        <h2 className="text-3xl sm:text-4xl lg:text-5xl xl:text-6xl font-bold text-white mb-8 sm:mb-12 leading-tight">
          {t('final.title')}
        </h2>

        {/* CTA button */}
        <div className="mb-6 sm:mb-8 px-4">
          <a
            href="https://forms.gle/sniAUJaSQktvAjzH6"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center justify-center gap-2 sm:gap-3 px-8 sm:px-10 py-4 sm:py-5 bg-white rounded-xl font-semibold text-base sm:text-lg shadow-xl hover:shadow-2xl transition-all whitespace-nowrap"
            style={{ color: '#1E3A8A' }}
          >
            <Gift className="w-4 h-4 sm:w-5 sm:h-5 flex-shrink-0" />
            {t('final.button')}
          </a>
        </div>

        <p className="text-base sm:text-lg text-blue-100 px-4">
          {t('final.subtitle')}
        </p>
      </div>
    </section>
  );
}