import { ArrowRight } from 'lucide-react';
import { useState } from 'react';
import { AnalysisSimulationModal } from './AnalysisSimulationModal';
import { useLanguage } from '../contexts/LanguageContext';

export function FinalCTA() {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const { t } = useLanguage();

  return (
    <>
      <section id="contact" className="py-20 sm:py-24 lg:py-32 px-4 sm:px-6 lg:px-8 relative overflow-hidden w-full" style={{ backgroundColor: '#1E3A8A' }}>
        {/* Background Pattern */}
        <div className="absolute inset-0 opacity-10">
          <div className="absolute top-0 left-0 w-64 h-64 sm:w-96 sm:h-96 rounded-full" style={{ background: 'radial-gradient(circle, #60A5FA 0%, transparent 70%)' }}></div>
          <div className="absolute bottom-0 right-0 w-64 h-64 sm:w-96 sm:h-96 rounded-full" style={{ background: 'radial-gradient(circle, #14B8A6 0%, transparent 70%)' }}></div>
        </div>

        <div className="max-w-4xl mx-auto text-center relative z-10 w-full">
          <h2 className="text-3xl sm:text-4xl lg:text-5xl xl:text-6xl font-bold text-white mb-6 sm:mb-8 leading-tight">
            {t('finalcta.title')}
          </h2>
          
          <p className="text-base sm:text-lg lg:text-xl text-blue-100 mb-8 sm:mb-12 max-w-2xl mx-auto px-4">
            {t('finalcta.subtitle')}
          </p>

          <div className="flex flex-col sm:flex-row gap-3 sm:gap-4 justify-center items-stretch sm:items-center w-full max-w-2xl mx-auto px-4">
            <button 
              onClick={() => setIsModalOpen(true)}
              className="group w-full sm:w-auto px-8 sm:px-10 py-4 sm:py-5 bg-white rounded-xl font-semibold text-base sm:text-lg shadow-xl hover:shadow-2xl transition-all flex items-center justify-center gap-2 sm:gap-3 whitespace-nowrap" 
              style={{ color: '#1E3A8A' }}
            >
              {t('solution.demo')}
              <ArrowRight className="w-4 h-4 sm:w-5 sm:h-5 group-hover:translate-x-1 transition-transform flex-shrink-0" />
            </button>
            
            <a
              href="https://forms.gle/sniAUJaSQktvAjzH6"
              target="_blank"
              rel="noopener noreferrer"
              className="w-full sm:w-auto px-8 sm:px-10 py-4 sm:py-5 rounded-xl font-semibold text-base sm:text-lg border-2 border-white text-white hover:bg-white/10 transition-all text-center whitespace-nowrap"
            >
              {t('finalcta.button')}
            </a>
          </div>

          <div className="mt-12 sm:mt-16 flex flex-wrap justify-center gap-6 sm:gap-8 text-white/80">
            <div className="text-center min-w-[100px]">
              <div className="text-2xl sm:text-3xl font-bold text-white mb-1">10,000+</div>
              <div className="text-xs sm:text-sm">Analyses Completed</div>
            </div>
            <div className="text-center min-w-[100px]">
              <div className="text-2xl sm:text-3xl font-bold text-white mb-1">500+</div>
              <div className="text-xs sm:text-sm">Products Tracked</div>
            </div>
            <div className="text-center min-w-[100px]">
              <div className="text-2xl sm:text-3xl font-bold text-white mb-1">4.8/5.0</div>
              <div className="text-xs sm:text-sm">User Rating</div>
            </div>
          </div>
        </div>
      </section>

      <AnalysisSimulationModal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} />
    </>
  );
}