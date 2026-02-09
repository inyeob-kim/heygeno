import React from 'react';
import { Heart } from 'lucide-react';

type NavigationProps = {
  scrolled: boolean;
};

export function Navigation({ scrolled }: NavigationProps) {
  return (
    <nav className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
      scrolled 
        ? 'bg-gradient-to-r from-[#10B981]/95 via-[#22C55E]/95 to-[#059669]/95 backdrop-blur-xl border-b-2 border-[#22C55E]/60 shadow-lg shadow-[#10B981]/30' 
        : 'bg-transparent'
    }`}>
      <div className="max-w-7xl mx-auto px-6 py-4">
        <div className="flex items-center justify-between">
          {/* Logo */}
          <div className="flex items-center gap-2">
            <div className="w-10 h-10 rounded-2xl bg-gradient-to-br from-[#10B981] via-[#22C55E] to-[#059669] flex items-center justify-center shadow-lg shadow-[#22C55E]/40">
              <Heart className="w-6 h-6 text-white fill-white" />
            </div>
            <span className={`text-xl font-bold ${scrolled ? 'text-white' : 'bg-gradient-to-r from-[#10B981] via-[#22C55E] to-[#059669] bg-clip-text text-transparent'}`}>
              HeyGeno
            </span>
          </div>

          {/* Navigation Links */}
          <div className="hidden md:flex items-center gap-8">
            <a href="#how-it-works" className={`text-sm font-medium transition-colors ${scrolled ? 'text-white/90 hover:text-white' : 'text-[#6B4423] hover:text-[#8B4513]'}`}>
              How it works
            </a>
            <a href="#features" className={`text-sm font-medium transition-colors ${scrolled ? 'text-white/90 hover:text-white' : 'text-[#6B4423] hover:text-[#8B4513]'}`}>
              Features
            </a>
            <a href="#point-rewards" className={`text-sm font-medium transition-colors ${scrolled ? 'text-white/90 hover:text-white' : 'text-[#6B4423] hover:text-[#8B4513]'}`}>
              포인트
            </a>
            <a href="#price-alerts" className={`text-sm font-medium transition-colors ${scrolled ? 'text-white/90 hover:text-white' : 'text-[#6B4423] hover:text-[#8B4513]'}`}>
              Price Alerts
            </a>
            <button className={`px-5 py-2.5 rounded-xl text-white text-sm font-bold hover:shadow-xl hover:scale-105 transition-all active:scale-95 border-2 border-transparent hover:border-white/30 ${scrolled ? 'bg-white/20 backdrop-blur-sm hover:bg-white/30' : 'bg-gradient-to-r from-[#10B981] via-[#22C55E] to-[#059669] hover:shadow-[#22C55E]/60'}`}>
              Get Started
            </button>
          </div>
        </div>
      </div>
    </nav>
  );
}
