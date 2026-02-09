import React, { useEffect, useState } from 'react';
import { FeatureCards } from './FeatureCards';
import { Footer } from './Footer';
import { HeroSection } from './HeroSection';
import { HowItWorks } from './HowItWorks';
import { Navigation } from './Navigation';
import { PointRewards } from './PointRewards';
import { PriceAlertSignup } from './PriceAlertSignup';
import { SocialProof } from './SocialProof';

export function LandingPage() {
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 20);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#FFE8D6] via-[#FFD4B3] to-[#FFC49B] text-[#5C4033] overflow-x-hidden">
      <Navigation scrolled={scrolled} />
      <HeroSection />
      <FeatureCards />
      <PointRewards />
      <HowItWorks />
      <SocialProof />
      <PriceAlertSignup />
      <Footer />
    </div>
  );
}
