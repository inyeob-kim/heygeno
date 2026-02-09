import React from 'react';
import { motion } from 'motion/react';
import { Star } from 'lucide-react';

const testimonials = [
  {
    name: '김민지',
    pet: '말티즈 · 5살',
    comment: '알러지가 많은 우리 강아지에게 딱 맞는 사료를 찾았어요. 성분 분석 기능이 정말 유용합니다!',
    rating: 5,
    avatar: '🐕',
  },
  {
    name: '박준호',
    pet: '페르시안 고양이 · 2살',
    comment: '가격 비교까지 해주니까 너무 편해요. 최저가 알림 덕분에 20% 할인받고 샀어요.',
    rating: 5,
    avatar: '🐱',
  },
  {
    name: '이서연',
    pet: '골든 리트리버 · 7살',
    comment: '체중 관리 중인데 칼로리까지 계산해주니 정말 과학적이에요. 믿고 쓰는 서비스입니다.',
    rating: 5,
    avatar: '🐕',
  },
];

export function SocialProof() {
  return (
    <section className="py-20 px-6 relative">
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
              반려인들의 이야기
            </span>
          </h2>
          <p className="text-xl text-[#8B4513] font-medium">
            실제 사용자들의 생생한 후기
          </p>
        </motion.div>

        <div className="grid md:grid-cols-3 gap-6">
          {testimonials.map((testimonial, index) => (
            <motion.div
              key={testimonial.name}
              initial={{ opacity: 0, y: 30 }}
              animate={{ opacity: 1, y: 0 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-100px" }}
              transition={{ duration: 0.5, delay: index * 0.1 }}
              className="group"
            >
              <div className="h-full bg-white/80 backdrop-blur-sm border-2 border-[#FFE5CC]/60 rounded-3xl p-6 hover:border-[#22C55E]/60 hover:bg-white/90 hover:shadow-xl hover:shadow-[#22C55E]/30 transition-all hover:-translate-y-2">
                {/* Rating */}
                <div className="flex gap-1 mb-4">
                  {[...Array(testimonial.rating)].map((_, i) => (
                    <Star key={i} className="w-4 h-4 fill-amber-500 text-amber-500" strokeWidth={2} />
                  ))}
                </div>

                {/* Comment */}
                <p className="text-[#6B4423] mb-6 leading-relaxed">
                  "{testimonial.comment}"
                </p>

                {/* User Info */}
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 rounded-full bg-gradient-to-br from-[#10B981] via-[#22C55E] to-[#059669] flex items-center justify-center text-2xl shadow-lg">
                    {testimonial.avatar}
                  </div>
                  <div>
                    <p className="font-semibold text-[#8B4513]">{testimonial.name}</p>
                    <p className="text-sm text-[#6B4423]">{testimonial.pet}</p>
                  </div>
                </div>
              </div>
            </motion.div>
          ))}
        </div>

        {/* Stats */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.6, delay: 0.3 }}
          className="grid grid-cols-3 gap-8 mt-16 max-w-3xl mx-auto"
        >
          <div className="text-center">
            <div className="text-4xl font-bold bg-gradient-to-r from-[#10B981] via-[#22C55E] to-[#059669] bg-clip-text text-transparent mb-2">
              12,000+
            </div>
            <p className="text-[#6B4423] font-medium">반려동물 프로필</p>
          </div>
          <div className="text-center">
            <div className="text-4xl font-bold bg-gradient-to-r from-[#22C55E] via-[#10B981] to-[#059669] bg-clip-text text-transparent mb-2">
              4.9
            </div>
            <p className="text-[#6B4423] font-medium">평균 평점</p>
          </div>
          <div className="text-center">
            <div className="text-4xl font-bold bg-gradient-to-r from-[#059669] via-[#22C55E] to-[#10B981] bg-clip-text text-transparent mb-2">
              95%
            </div>
            <p className="text-[#6B4423] font-medium">만족도</p>
          </div>
        </motion.div>
      </div>
    </section>
  );
}
