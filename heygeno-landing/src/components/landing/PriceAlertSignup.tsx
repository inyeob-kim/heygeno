import React, { useState } from 'react';
import { motion } from 'motion/react';
import { Bell, ArrowRight } from 'lucide-react';

export function PriceAlertSignup() {
  const [email, setEmail] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    console.log('Email submitted:', email);
    // Handle email submission
  };

  return (
    <section id="price-alerts" className="py-20 px-6 relative">
      <div className="max-w-4xl mx-auto">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.6 }}
          className="relative"
        >
          {/* Glow Effect */}
          <div className="absolute inset-0 bg-gradient-to-r from-[#10B981]/40 via-[#22C55E]/40 to-[#059669]/40 rounded-3xl blur-3xl animate-pulse" />

          {/* Card */}
          <div className="relative bg-white/80 backdrop-blur-xl border-2 border-[#22C55E]/50 rounded-3xl p-12 text-center shadow-2xl shadow-[#22C55E]/30">
            <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-[#10B981] via-[#22C55E] to-[#059669] flex items-center justify-center mx-auto mb-6 shadow-xl shadow-[#22C55E]/50">
              <Bell className="w-8 h-8 text-white fill-white" />
            </div>

            <h2 className="text-3xl md:text-4xl font-bold mb-4">
              <span className="bg-gradient-to-r from-[#10B981] via-[#22C55E] to-[#059669] bg-clip-text text-transparent drop-shadow-lg">
                최저가 알림 신청하기
              </span>
            </h2>

            <p className="text-lg text-[#6B4423] mb-8 max-w-2xl mx-auto">
              원하는 사료의 가격이 떨어지면 바로 알려드릴게요.<br />
              스팸 없는 깔끔한 알림만 보내드립니다.
            </p>

            <form onSubmit={handleSubmit} className="max-w-md mx-auto">
              <div className="flex flex-col sm:flex-row gap-3">
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="이메일 주소를 입력하세요"
                  required
                  className="flex-1 px-6 py-4 rounded-xl bg-white/90 backdrop-blur-sm border-2 border-[#FFE5CC]/60 text-[#5C4033] placeholder:text-[#A0826D] focus:outline-none focus:border-[#22C55E] focus:ring-2 focus:ring-[#22C55E]/50 transition-all shadow-md"
                />
                <button
                  type="submit"
                  className="group px-8 py-4 rounded-xl bg-gradient-to-r from-[#10B981] via-[#22C55E] to-[#059669] text-white font-bold hover:shadow-2xl hover:shadow-[#22C55E]/60 hover:scale-105 transition-all active:scale-95 flex items-center justify-center gap-2 border-2 border-transparent hover:border-white/30"
                >
                  알림 신청
                  <ArrowRight className="w-5 h-5 text-white group-hover:translate-x-1 transition-transform" />
                </button>
              </div>
              <p className="text-sm text-[#A0826D] mt-4">
                언제든지 구독 해지 가능 · 개인정보는 안전하게 보호됩니다
              </p>
            </form>
          </div>
        </motion.div>
      </div>
    </section>
  );
}
