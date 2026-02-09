import { FlaskConical, Sparkles, TrendingDown } from 'lucide-react';
import { motion } from 'motion/react';
import React from 'react';

const features = [
  {
    icon: FlaskConical,
    title: '성분 분석',
    description: '사료 성분을 하나하나 분석해\n알러지·위험 성분을 미리 걸러줍니다.',
    gradient: 'from-[#10B981] to-[#22C55E]',
  },
  {
    icon: Sparkles,
    title: '맞춤 추천',
    description: '우리 아이 데이터에 맞춰\n정말 필요한 사료만 추천합니다.',
    gradient: 'from-[#22C55E] to-[#059669]',
  },
  {
    icon: TrendingDown,
    title: '최저가 알림',
    description: '가격이 내려가면\n바로 알려주는 스마트 알림.',
    gradient: 'from-[#059669] to-[#10B981]',
  },
];

export function FeatureCards() {
  return (
    <section id="features" className="py-20 px-6 relative">
      <div className="max-w-7xl mx-auto">
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
              왜 HeyGeno인가요?
            </span>
          </h2>
          <p className="text-xl text-[#8B4513] font-medium">
            데이터 기반으로 우리 아이를 케어합니다
          </p>
        </motion.div>

        <div className="grid md:grid-cols-3 gap-8">
          {features.map((feature, index) => {
            const Icon = feature.icon;
            return (
              <motion.div
                key={feature.title}
                initial={{ opacity: 0, y: 30 }}
                animate={{ opacity: 1, y: 0 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: "-100px" }}
                transition={{ duration: 0.5, delay: index * 0.1 }}
                whileHover={{ y: -8 }}
                className="group relative"
              >
                {/* Glow on hover */}
                <div className={`absolute inset-0 bg-gradient-to-r ${feature.gradient} opacity-0 group-hover:opacity-30 rounded-3xl blur-xl transition-opacity duration-300`} />
                
                {/* Card */}
                <div className="relative h-full bg-white/80 backdrop-blur-sm border-2 border-[#FFE5CC]/60 rounded-3xl p-8 hover:border-[#22C55E]/60 hover:shadow-xl hover:shadow-[#22C55E]/30 transition-all group-hover:-translate-y-2">
                  <div className={`w-14 h-14 rounded-2xl bg-gradient-to-br ${feature.gradient} flex items-center justify-center mb-6 group-hover:scale-110 transition-transform shadow-lg`}>
                    <Icon className="w-7 h-7 text-white fill-white" strokeWidth={2.5} />
                  </div>
                  
                  <h3 className="text-2xl font-bold text-[#8B4513] mb-3">
                    {feature.title}
                  </h3>
                  
                  <p className="text-[#6B4423] leading-relaxed whitespace-pre-line">
                    {feature.description}
                  </p>
                </div>
              </motion.div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
