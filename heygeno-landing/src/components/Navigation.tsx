import { useLanguage } from '../contexts/LanguageContext';

export function Navigation() {
  const { t } = useLanguage();

  return (
    <nav className="fixed top-0 left-0 right-0 bg-white/80 backdrop-blur-lg border-b border-gray-200 z-50 w-full">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 w-full">
        <div className="flex items-center justify-between h-16 sm:h-20 w-full">
          <div className="flex items-center">
            <h1 className="text-xl sm:text-2xl font-bold" style={{ color: '#2563EB' }}>
              {t('hero.brand')}
            </h1>
          </div>
          
          <div className="flex items-center gap-4 sm:gap-8">
            <div className="hidden md:flex items-center gap-6">
              <a href="#features" className="text-sm hover:opacity-70 transition-opacity" style={{ color: '#475569' }}>
                {t('nav.features')}
              </a>
              <a href="#about" className="text-sm hover:opacity-70 transition-opacity" style={{ color: '#475569' }}>
                {t('nav.about')}
              </a>
              <a href="#contact" className="text-sm hover:opacity-70 transition-opacity" style={{ color: '#475569' }}>
                {t('nav.contact')}
              </a>
            </div>
            
            <div className="text-sm font-semibold" style={{ color: '#0F172A' }}>
              EN
            </div>
          </div>
        </div>
      </div>
    </nav>
  );
}
