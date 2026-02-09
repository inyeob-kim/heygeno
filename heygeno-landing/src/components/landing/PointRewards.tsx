import React from 'react';
import { motion } from 'motion/react';
import { Gift, Coins, ShoppingBag, Sparkles } from 'lucide-react';

const benefits = [
  {
    icon: Coins,
    title: '구매 시 포인트 적립',
    description: '사료 구매 금액의\n일정 비율이 포인트로 적립됩니다',
    gradient: 'from-[#10B981] to-[#22C55E]',
  },
  {
    icon: ShoppingBag,
    title: '재구매 할인',
    description: '적립된 포인트로\n다음 구매 시 할인받으세요',
    gradient: 'from-[#22C55E] to-[#059669]',
  },
  {
    icon: Gift,
    title: '간식·장난감 교환',
    description: '포인트로 간식이나\n장난감으로 교환 가능합니다',
    gradient: 'from-[#059669] to-[#10B981]',
  },
];

export function PointRewards() {
  return (
    <section id="point-rewards" className="py-20 px-6 relative overflow-hidden">
      {/* Background Gradient */}
      <div className="absolute inset-0 bg-gradient-to-br from-[#D1FAE5]/20 via-[#A7F3D0]/20 to-[#6EE7B7]/20" />
      
      <div className="max-w-7xl mx-auto relative z-10">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-gradient-to-r from-[#10B981]/30 to-[#22C55E]/30 backdrop-blur-sm border-2 border-[#22C55E]/50 shadow-lg shadow-[#10B981]/20 mb-6">
            <Sparkles className="w-4 h-4 text-[#10B981] fill-[#10B981]" strokeWidth={2.5} />
            <span className="text-sm text-[#059669] font-semibold">포인트 적립 시스템</span>
          </div>
          
          <h2 className="text-4xl md:text-5xl font-bold mb-4">
            <span className="bg-gradient-to-r from-[#10B981] via-[#22C55E] to-[#059669] bg-clip-text text-transparent drop-shadow-lg">
              구매할수록 더 많은 혜택
            </span>
          </h2>
          <p className="text-xl text-[#8B4513] font-medium">
            포인트 적립부터 재구매 할인, 간식·장난감 교환까지
          </p>
        </motion.div>

        <div className="grid md:grid-cols-3 gap-8">
          {benefits.map((benefit, index) => {
            const Icon = benefit.icon;
            return (
              <motion.div
                key={benefit.title}
                initial={{ opacity: 0, y: 30 }}
                animate={{ opacity: 1, y: 0 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: "-100px" }}
                transition={{ duration: 0.5, delay: index * 0.1 }}
                whileHover={{ y: -8 }}
                className="group relative"
              >
                {/* Glow on hover */}
                <div className={`absolute inset-0 bg-gradient-to-r ${benefit.gradient} opacity-0 group-hover:opacity-20 rounded-3xl blur-xl transition-opacity duration-300`} />
                
                {/* Card */}
                <div className="relative h-full bg-white/90 backdrop-blur-sm border-2 border-[#D1FAE5]/60 rounded-3xl p-8 hover:border-[#22C55E]/60 hover:shadow-xl hover:shadow-[#22C55E]/30 transition-all group-hover:-translate-y-2">
                  <div className={`w-16 h-16 rounded-2xl bg-gradient-to-br ${benefit.gradient} flex items-center justify-center mb-6 group-hover:scale-110 transition-transform shadow-lg`}>
                    <Icon className="w-8 h-8 text-white fill-white" strokeWidth={2.5} />
                  </div>
                  
                  <h3 className="text-2xl font-bold text-[#8B4513] mb-3">
                    {benefit.title}
                  </h3>
                  
                  <p className="text-[#6B4423] leading-relaxed whitespace-pre-line mb-4">
                    {benefit.description}
                  </p>
                  
                  {/* Example */}
                  {index === 0 && (
                    <div className="mt-4 p-3 rounded-xl bg-gradient-to-r from-[#10B981]/10 to-[#22C55E]/10 border border-[#22C55E]/30">
                      <p className="text-xs text-[#059669] font-semibold">예: 50,000원 구매 시 500P 적립</p>
                    </div>
                  )}
                  {index === 1 && (
                    <div className="mt-4 p-3 rounded-xl bg-gradient-to-r from-[#22C55E]/10 to-[#059669]/10 border border-[#22C55E]/30">
                      <p className="text-xs text-[#059669] font-semibold">예: 1,000P = 1,000원 할인</p>
                    </div>
                  )}
                  {index === 2 && (
                    <div className="mt-4 p-3 rounded-xl bg-gradient-to-r from-[#059669]/10 to-[#10B981]/10 border border-[#22C55E]/30">
                      <p className="text-xs text-[#059669] font-semibold">예: 2,000P = 프리미엄 간식 1개</p>
                    </div>
                  )}
                </div>
              </motion.div>
            );
          })}
        </div>

        {/* CTA Section */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.6, delay: 0.3 }}
          className="mt-16 text-center"
        >
          <div className="inline-block px-8 py-4 rounded-2xl bg-gradient-to-r from-[#10B981]/20 via-[#22C55E]/20 to-[#059669]/20 backdrop-blur-sm border-2 border-[#22C55E]/40 shadow-lg">
            <p className="text-lg text-[#8B4513] font-semibold mb-2">
              💰 포인트는 영구 유효합니다
            </p>
            <p className="text-sm text-[#6B4423]">
              만료일 없이 언제든지 사용하실 수 있어요
            </p>
          </div>
        </motion.div>
      </div>
    </section>
  );
}
