import { Search, Shield, BarChart3 } from 'lucide-react';
import { useLanguage } from '../contexts/LanguageContext';

export function SocialProofSection() {
  const { t } = useLanguage();
  const affiliatePartners = [
    'Amazon',
    'Chewy',
    'Petco',
    'PetSmart',
    'Walmart',
    'Target',
    'Tractor Supply',
    'PetFlow',
    'The Farmer\'s Dog',
    'Ollie',
    'Nom Nom',
    'Spot & Tango',
    'Open Farm',
    'iHeartDogs',
  ];
  
  const targetUsers = [
    {
      icon: Search,
      title: t('social.user1.title'),
      description: t('social.user1.desc'),
      color: '#2563EB'
    },
    {
      icon: Shield,
      title: t('social.user2.title'),
      description: t('social.user2.desc'),
      color: '#EF4444'
    },
    {
      icon: BarChart3,
      title: t('social.user3.title'),
      description: t('social.user3.desc'),
      color: '#14B8A6'
    }
  ];

  return (
    <section className="py-16 sm:py-20 lg:py-24 px-4 sm:px-6 lg:px-8 bg-white w-full overflow-x-hidden">
      <div className="max-w-7xl mx-auto w-full">
        <div className="text-center mb-12 sm:mb-16">
          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold mb-6" style={{ color: '#0F172A' }}>
            {t('social.title')}
          </h2>
        </div>

        <div className="grid md:grid-cols-3 gap-6 sm:gap-8 w-full">
          {targetUsers.map((user, index) => (
            <div 
              key={index} 
              className="bg-white rounded-2xl p-6 sm:p-8 border-2 border-gray-100 hover:border-gray-200 transition-all w-full"
            >
              <div 
                className="w-12 h-12 sm:w-14 sm:h-14 rounded-2xl flex items-center justify-center mb-4 sm:mb-6" 
                style={{ backgroundColor: `${user.color}15` }}
              >
                <user.icon className="w-6 h-6 sm:w-7 sm:h-7" style={{ color: user.color }} />
              </div>
              <h3 className="text-lg sm:text-xl font-bold mb-3 sm:mb-4 leading-snug" style={{ color: '#0F172A' }}>
                {user.title}
              </h3>
              <p className="leading-relaxed text-sm sm:text-base" style={{ color: '#475569' }}>
                {user.description}
              </p>
            </div>
          ))}
        </div>

        <div className="mt-12 sm:mt-16 bg-white rounded-2xl p-6 sm:p-8 border-2 border-gray-100">
          <div className="text-center mb-5 sm:mb-6">
            <h3 className="text-lg sm:text-xl font-bold mb-2" style={{ color: '#0F172A' }}>
              U.S. Affiliate Retail & Brand Partners
            </h3>
            <p className="text-sm sm:text-base" style={{ color: '#475569' }}>
              We are building integrations across major partner programs to track pet food deals in one place.
            </p>
          </div>

          <div className="flex flex-wrap justify-center gap-2 sm:gap-3">
            {affiliatePartners.map((partner) => (
              <span
                key={partner}
                className="px-3 sm:px-4 py-1.5 sm:py-2 rounded-full text-xs sm:text-sm font-semibold border"
                style={{ borderColor: '#DBEAFE', color: '#2563EB', backgroundColor: '#EFF6FF' }}
              >
                {partner}
              </span>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}