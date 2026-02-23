import { createContext, useContext, useState, ReactNode } from 'react';

type Language = 'ENG';

interface LanguageContextType {
  language: Language;
  t: (key: string) => string;
}

const LanguageContext = createContext<LanguageContextType | undefined>(undefined);

const translations: Record<Language, Record<string, string>> = {
  ENG: {
    // Navigation
    'nav.features': 'Features',
    'nav.about': 'About',
    'nav.contact': 'Contact',
    
    // Hero
    'hero.brand': 'KibbleWise',
    'hero.headline1': 'We want to feed our pets',
    'hero.headline2': 'the best',
    'hero.headline3': ',',
    'hero.headline4': 'but the price',
    'hero.headline5': 'can be a burden',
    'hero.headline6': '.',
    'hero.subheadline1': 'Ingredients made simple,',
    'hero.subheadline2': 'Prices made reasonable.',
    'hero.subheadline3': 'KibbleWise takes care of your concerns.',
    'hero.cta.primary': 'Get Early Access',
    'hero.cta.secondary': 'Get Launch Alert',
    'hero.benefit1': 'Points on launch',
    'hero.benefit2': 'Beta access priority',
    'hero.benefit3': 'First to know about launch',
    'hero.phone.prelaunch': 'Pre-launch Preview',
    'hero.phone.launch': 'Launching March 2026',
    'hero.phone.score': 'Overall Score',
    'hero.phone.scoreMax': 'out of 100',
    'hero.phone.warning': 'Harmful Ingredients Detected',
    'hero.phone.priceCompare': 'Best Price',
    'hero.phone.lowest': 'Lowest',
    'hero.phone.clickAnalysis': 'Tap to see analysis',
    'hero.phone.clickAlert': 'Tap to see alert',
    
    // Problem Section
    'problem.title': "Pet Parents' Concerns",
    'problem.card1.title': 'Complex Ingredients',
    'problem.card1.desc': "It's hard to understand complicated ingredient lists and identify harmful components",
    'problem.card2.title': 'High Prices',
    'problem.card2.desc': 'Quality food is expensive, and finding deals requires browsing multiple sites',
    'problem.card3.title': 'Allergy Risks',
    'problem.card3.desc': "It's burdensome to check every time if ingredients are safe for my pet",
    
    // Solution Section
    'solution.title': 'KibbleWise Takes a Different Approach.',
    'solution.step1.title': 'Ingredient Risk Analysis',
    'solution.step1.desc': 'Automatically detect and evaluate harmful ingredients and risk factors',
    'solution.step2.title': 'Allergen Detection',
    'solution.step2.desc': 'Pre-warn about allergens that may be dangerous for your pet',
    'solution.step3.title': 'Custom Nutrition Matching',
    'solution.step3.desc': 'Provide optimized nutrition solutions based on age, weight, and health',
    'solution.step4.title': 'Multi-platform Price Comparison',
    'solution.step4.desc': 'Compare real-time prices across Amazon, Chewy, Petco, PetSmart, Walmart, Target, Tractor Supply, and more',
    'solution.step5.title': 'Price Drop Alerts',
    'solution.step5.desc': 'Get real-time notifications when prices drop on your favorite foods',
    'solution.step6.title': 'Reward Points System',
    'solution.step6.desc': 'Earn points through purchases and activities, redeem for pet food',
    'solution.demo': 'View Demo',
    
    // Reward Section
    'reward.main.title': 'The More You Buy,\nThe Smarter We Get.',
    'reward.main.desc': 'Earn points through purchases and events, and redeem them for pet food or treats.',
    'reward.earn1.title': 'Purchase Rewards',
    'reward.earn1.desc': 'Earn up to 5% points on pet food purchases',
    'reward.earn2.title': 'Event Participation',
    'reward.earn2.desc': 'Earn additional points by writing reviews and rating products',
    'reward.earn3.title': 'Point Redemption',
    'reward.earn3.desc': 'Redeem accumulated points for pet food and treats',
    'reward.card.mypoints': 'My Points',
    'reward.card.recentearnings': 'Recent Earnings',
    'reward.card.today': 'Today',
    'reward.card.purchase': 'Pet Food Purchase',
    'reward.card.review': 'Review Written',
    'reward.card.redeemable': 'Redeemable Items',
    'reward.card.food2kg': '2kg Pet Food',
    'reward.card.treats': 'Premium Treats',
    'reward.card.button': 'Redeem Points',
    
    // Vision Section
    'vision.title': 'The Future KibbleWise Creates',
    'vision.subtitle': 'Data-driven smart pet nutrition management',
    'vision.feature1.title': 'Transparent Ingredients',
    'vision.feature1.desc': 'Clearly analyze all food ingredients and alert you to risk factors in advance',
    'vision.feature2.title': 'Reasonable Prices',
    'vision.feature2.desc': 'Compare prices across multiple platforms in real-time to find the best deal',
    'vision.feature3.title': 'Healthy Choices',
    'vision.feature3.desc': "Provide optimal nutrition solutions tailored to your pet's health condition",
    'vision.expansion.badge': 'Scalability',
    'vision.expansion.title': 'Growing Data-Driven\nPlatform',
    'vision.expansion.desc': 'Starting from food analysis, expanding to supplements and health management,\nbecoming a platform that takes care of your pet\'s entire lifecycle.',
    
    // Final CTA
    'finalcta.title': 'Start Right Now',
    'finalcta.subtitle': 'Pre-register and receive special benefits',
    'finalcta.button': 'Pre-register Now',
    
    // Countdown
    'countdown.title': 'Launching Soon',
    'countdown.timeframe': '1–2 months',
    'countdown.launch': 'Official Launch Expected',
    'countdown.message': 'Register now to be the first to experience the analysis feature.',
    
    // Social Proof
    'social.title': 'Made For Pet Parents Like You',
    'social.user1.title': 'For those who want to verify ingredients properly',
    'social.user1.desc': 'For those who want to accurately analyze and understand complex pet food ingredient lists',
    'social.user2.title': 'For families worried about allergies',
    'social.user2.desc': 'For those who want to check ingredients and allergens that may not suit their pet in advance',
    'social.user3.title': 'For those who want to compare prices across platforms',
    'social.user3.desc': 'For those who want side-by-side pricing from major U.S. affiliate partners including Amazon, Chewy, Petco, PetSmart, Walmart, and Target',
    
    // Final Reinforcement
    'final.title': 'When We Launch, Be The First To Analyze',
    'final.subtitle': "We'll notify you of the official launch and bonus points.",
    'final.button': 'Get 1,000P Now',
  },
};

export function LanguageProvider({ children }: { children: ReactNode }) {
  const [language] = useState<Language>('ENG');

  const t = (key: string): string => {
    return translations[language][key] || key;
  };

  return (
    <LanguageContext.Provider value={{ language, t }}>
      {children}
    </LanguageContext.Provider>
  );
}

export function useLanguage() {
  const context = useContext(LanguageContext);
  if (!context) {
    throw new Error('useLanguage must be used within LanguageProvider');
  }
  return context;
}