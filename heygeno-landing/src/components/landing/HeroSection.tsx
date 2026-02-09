import React from 'react';
import { ArrowRight, Sparkles, Bell } from 'lucide-react';
import { motion } from 'motion/react';

export function HeroSection() {
  return (
    <section className="relative pt-32 pb-20 px-6 overflow-hidden">
      {/* Gradient Orbs */}
      <div className="absolute top-0 left-1/4 w-96 h-96 bg-[#FF6B35]/30 rounded-full blur-3xl animate-pulse" />
      <div className="absolute bottom-0 right-1/4 w-96 h-96 bg-[#FF8C42]/25 rounded-full blur-3xl animate-pulse" style={{ animationDelay: '1s' }} />
      <div className="absolute top-1/2 left-1/2 w-80 h-80 bg-[#FFB347]/20 rounded-full blur-3xl -translate-x-1/2 -translate-y-1/2 animate-pulse" style={{ animationDelay: '2s' }} />

      <div className="max-w-7xl mx-auto relative z-10">
        <div className="grid lg:grid-cols-2 gap-12 items-center">
          {/* Left: Text Content */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
          >
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-gradient-to-r from-[#10B981]/80 to-[#22C55E]/80 backdrop-blur-sm border-2 border-[#22C55E]/70 shadow-lg shadow-[#10B981]/40 mb-6">
              <Sparkles className="w-4 h-4 text-white fill-white" />
              <span className="text-sm text-white font-semibold">AI 기반 맞춤 추천</span>
            </div>

            <h1 className="text-5xl md:text-6xl lg:text-7xl font-bold mb-6 leading-tight">
              <span className="text-[#8B4513] drop-shadow-lg">
                성분으로 분석하는,
              </span>
              <br />
              <span className="bg-gradient-to-r from-[#10B981] via-[#22C55E] to-[#059669] bg-clip-text text-transparent drop-shadow-lg">
                우리 아이 맞춤 사료
              </span>
            </h1>

            <p className="text-xl text-[#6B4423] font-medium mb-8 leading-relaxed max-w-xl">
              나이, 체중, 알러지, 건강 상태를 기준으로<br />
              가장 잘 맞는 사료를 추천하고<br />
              최저가까지 알려드립니다.
            </p>

            <div className="flex flex-col sm:flex-row gap-4">
              <button className="group px-8 py-4 rounded-2xl bg-gradient-to-r from-[#10B981] via-[#22C55E] to-[#059669] text-white font-bold hover:shadow-2xl hover:shadow-[#22C55E]/60 hover:scale-105 transition-all active:scale-95 flex items-center justify-center gap-2 border-2 border-transparent hover:border-white/30">
                맞춤 추천 시작하기
                <ArrowRight className="w-5 h-5 text-white group-hover:translate-x-1 transition-transform" />
              </button>
              <button className="px-8 py-4 rounded-2xl bg-white/70 backdrop-blur-sm border-2 border-[#22C55E]/50 text-[#8B4513] font-semibold hover:bg-white/90 hover:border-[#10B981] hover:shadow-lg hover:shadow-[#22C55E]/30 transition-all active:scale-95 flex items-center justify-center gap-2">
                <Bell className="w-5 h-5 text-[#8B4513]" strokeWidth={2.5} />
                최저가 알림 받기
              </button>
            </div>
          </motion.div>

          {/* Right: Pet Profile Card Mockup */}
          <motion.div
            initial={{ opacity: 0, x: 50 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="relative"
          >
            <div className="relative">
              {/* Glow Effect */}
              <div className="absolute inset-0 bg-gradient-to-r from-[#FF6B35]/40 via-[#FF8C42]/40 to-[#FFB347]/40 rounded-3xl blur-2xl animate-pulse" />
              
              {/* Card */}
              <div className="relative bg-white/80 backdrop-blur-xl border-2 border-[#FF8C42]/40 rounded-3xl p-8 shadow-2xl shadow-[#FF6B35]/30 hover:shadow-[#FF6B35]/50 transition-all">
                <div className="flex items-start gap-4 mb-6">
                  <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-[#FF6B35] via-[#FF8C42] to-[#FFB347] flex items-center justify-center text-3xl shadow-lg shadow-[#FF8C42]/40">
                    🐕
                  </div>
                  <div>
                    <h3 className="text-2xl font-bold text-[#8B4513] mb-1">Max</h3>
                    <p className="text-[#6B4423]">Golden Retriever · 3살 · 15.2kg</p>
                  </div>
                </div>

                <div className="space-y-4">
                  {/* Safety Score */}
                  <div>
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-sm text-[#6B4423]">성분 안전도</span>
                      <span className="text-lg font-bold text-[#22C55E]">92%</span>
                    </div>
                    <div className="w-full h-3 bg-[#FFE5CC]/60 rounded-full overflow-hidden shadow-inner">
                      <motion.div
                        initial={{ width: 0 }}
                        animate={{ width: '92%' }}
                        transition={{ duration: 1, delay: 0.5 }}
                        className="h-full bg-gradient-to-r from-[#22C55E] via-[#10B981] to-[#059669] rounded-full shadow-lg"
                      />
                    </div>
                  </div>

                  {/* Allergy Warning */}
                  <div className="flex items-center gap-2 p-4 rounded-xl bg-gradient-to-r from-amber-400/30 to-orange-400/30 border-2 border-amber-500/50 shadow-md">
                    <svg className="w-5 h-5 text-amber-700" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                    </svg>
                    <span className="text-sm font-semibold text-[#8B4513]">닭고기 알러지 주의</span>
                  </div>

                  {/* Recommended Product */}
                  <div className="p-4 rounded-xl bg-gradient-to-br from-[#FF6B35]/30 via-[#FF8C42]/30 to-[#FFB347]/30 border-2 border-[#FF8C42]/50 shadow-lg">
                    <p className="text-xs text-[#8B4513] mb-2 font-medium">오늘의 추천 사료</p>
                    <h4 className="text-sm font-bold text-[#8B4513] mb-1">Premium Grain-Free</h4>
                    <div className="flex items-baseline gap-2">
                      <span className="text-xl font-bold text-[#8B4513]">45,000원</span>
                      <span className="text-xs text-[#22C55E] font-bold bg-green-100 px-2 py-0.5 rounded-full">-18% 좋은 딜</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  );
}
