import React from 'react';
import { motion } from 'motion/react';
import { UserPlus, FlaskConical, Sparkles, ArrowRight } from 'lucide-react';

const steps = [
  {
    number: 1,
    icon: UserPlus,
    title: '펫 프로필 생성',
    description: '이름, 나이, 체중, 알러지 정보를\n간단하게 입력하세요',
  },
  {
    number: 2,
    icon: FlaskConical,
    title: '사료 성분 분석',
    description: 'AI가 수천 개 사료의 성분을\n우리 아이 기준으로 분석합니다',
  },
  {
    number: 3,
    icon: Sparkles,
    title: '추천 & 알림',
    description: '맞춤 추천과 최저가 알림을\n한번에 받아보세요',
  },
];

export function HowItWorks() {
  return (
    <section id="how-it-works" className="py-20 px-6 relative overflow-hidden">
      {/* Background Pattern */}
      <div className="absolute inset-0 opacity-10">
        <div className="absolute inset-0" style={{
          backgroundImage: 'radial-gradient(circle, #FF8C42 1px, transparent 1px)',
          backgroundSize: '50px 50px'
        }} />
      </div>

      <div className="max-w-6xl mx-auto relative z-10">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <h2 className="text-4xl md:text-5xl font-bold mb-4">
            <span className="bg-gradient-to-r from-[#10B981] via-[#22C55E] to-[#059669] bg-clip-text text-transparent drop-shadow-lg">
              어떻게 동작하나요?
            </span>
          </h2>
          <p className="text-xl text-[#8B4513] font-medium">
            3단계로 끝나는 간단한 시작
          </p>
        </motion.div>

        <div className="relative">
          {/* Connection Lines */}
          <div className="hidden lg:block absolute top-1/2 left-0 right-0 h-px bg-gradient-to-r from-transparent via-[#22C55E]/50 to-transparent -translate-y-1/2" />

          <div className="grid lg:grid-cols-3 gap-8 lg:gap-4">
            {steps.map((step, index) => {
              const Icon = step.icon;
              return (
                <motion.div
                  key={step.number}
                  initial={{ opacity: 0, scale: 0.9 }}
                  animate={{ opacity: 1, scale: 1 }}
                  whileInView={{ opacity: 1, scale: 1 }}
                  viewport={{ once: true, margin: "-100px" }}
                  transition={{ duration: 0.5, delay: index * 0.15 }}
                  className="relative"
                >
                  <div className="relative bg-white/80 backdrop-blur-sm border-2 border-[#FFE5CC]/60 rounded-3xl p-8 text-center hover:border-[#22C55E]/60 hover:shadow-xl hover:shadow-[#22C55E]/30 transition-all group hover:-translate-y-2">
                    {/* Step Number Badge */}
                    <div className="absolute -top-4 left-1/2 -translate-x-1/2">
                      <div className="w-12 h-12 rounded-full bg-gradient-to-br from-[#10B981] via-[#22C55E] to-[#059669] flex items-center justify-center text-white font-bold text-xl shadow-xl shadow-[#22C55E]/50">
                        {step.number}
                      </div>
                    </div>

                    {/* Icon */}
                    <div className="mt-8 mb-6 flex justify-center">
                      <div className="w-20 h-20 rounded-2xl bg-gradient-to-br from-[#10B981]/30 via-[#22C55E]/30 to-[#059669]/30 border-2 border-[#22C55E]/50 flex items-center justify-center group-hover:scale-110 transition-transform shadow-lg">
                        <Icon className="w-10 h-10 text-[#10B981]" strokeWidth={2.5} />
                      </div>
                    </div>

                    <h3 className="text-xl font-bold text-[#8B4513] mb-3">
                      {step.title}
                    </h3>

                    <p className="text-[#6B4423] leading-relaxed whitespace-pre-line">
                      {step.description}
                    </p>
                  </div>

                  {/* Arrow (except last item) */}
                  {index < steps.length - 1 && (
                    <div className="hidden lg:flex absolute top-1/2 -right-2 -translate-y-1/2 z-20">
                      <ArrowRight className="w-6 h-6 text-[#22C55E]" strokeWidth={2.5} />
                    </div>
                  )}
                </motion.div>
              );
            })}
          </div>
        </div>
      </div>
    </section>
  );
}
