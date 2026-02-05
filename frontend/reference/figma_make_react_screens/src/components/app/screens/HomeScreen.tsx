import { AppBar } from '../components/AppBar';
import { PrimaryButton } from '../components/PrimaryButton';
import { MatchScoreBadge } from '../components/MatchScoreBadge';
import { PriceDelta } from '../components/PriceDelta';
import { mockProducts, petData } from '../data/mockData';
import { Check } from 'lucide-react';

type HomeScreenProps = {
  onNavigateToProduct: (product: any) => void;
};

export function HomeScreen({ onNavigateToProduct }: HomeScreenProps) {
  const recommendedProduct = mockProducts[0];

  return (
    <div className="pb-24">
      {/* App Title */}
      <div className="pt-6 px-4">
        <h1 className="text-[28px] font-bold text-[#111827] leading-tight" style={{ letterSpacing: '-0.5px' }}>
          오늘, {petData.name}에게<br />딱 맞는 사료
        </h1>
      </div>

      <div className="px-4 space-y-8 mt-8">
        {/* Pet Summary - Light Header */}
        <div className="flex items-start justify-between">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <span className="text-body text-[#111827]">{petData.name}</span>
              <span className="text-sub text-[#6B7280]">·</span>
              <span className="text-sub text-[#6B7280]">{petData.breed}</span>
            </div>
            <p className="text-sub text-[#6B7280]">{petData.age}살</p>
          </div>
          <div className="text-right">
            <div className="text-[24px] font-bold text-[#2563EB]" style={{ letterSpacing: '-0.4px' }}>
              {petData.weight}kg
            </div>
            <p className="text-sub text-[#6B7280]">현재 체중</p>
          </div>
        </div>

        {/* Daily Indicators */}
        <div className="flex gap-3">
          <div className="flex-1 py-3 rounded-2xl bg-[#F7F8FA] text-center">
            <div className="text-body text-[#111827] font-semibold mb-0.5">BCS {petData.bcs}</div>
            <div className="text-sub text-[#6B7280]">이상적</div>
          </div>
          <div className="flex-1 py-3 rounded-2xl bg-[#F7F8FA] text-center">
            <div className="text-body text-[#111827] font-semibold mb-0.5">{petData.dailyKcal}</div>
            <div className="text-sub text-[#6B7280]">kcal/day</div>
          </div>
          <div className="flex-1 py-3 rounded-2xl bg-[#F7F8FA] text-center">
            <div className="text-body text-[#111827] font-semibold mb-0.5">{petData.dailyGrams}g</div>
            <div className="text-sub text-[#6B7280]">하루 급여량</div>
          </div>
        </div>

        {/* Single Recommendation - Center Focus */}
        <div className="pt-4">
          <button 
            onClick={() => onNavigateToProduct(recommendedProduct)}
            className="w-full active:scale-[0.99] transition-all"
          >
            {/* Large Image */}
            <div className="relative aspect-[4/3] rounded-3xl overflow-hidden bg-[#F7F8FA] mb-4">
              <img 
                src={recommendedProduct.image}
                alt={recommendedProduct.name}
                className="w-full h-full object-cover"
              />
              <div className="absolute top-3 left-3">
                <MatchScoreBadge score={recommendedProduct.matchScore} size="medium" />
              </div>
              {recommendedProduct.badge && (
                <div className="absolute bottom-3 left-3">
                  <span className="inline-block px-3 py-1 rounded-full text-[11px] font-semibold bg-[#EFF6FF] text-[#2563EB]">
                    {recommendedProduct.badge}
                  </span>
                </div>
              )}
            </div>

            {/* Brand + Product Name */}
            <div className="text-left mb-3">
              <p className="text-sub text-[#6B7280] mb-1">{recommendedProduct.brand}</p>
              <h2 className="text-title text-[#111827]">{recommendedProduct.name}</h2>
            </div>

            {/* Price Hero */}
            <div className="text-left mb-4">
              <div className="flex items-baseline gap-3 mb-2">
                <span className="text-hero text-[#111827]">
                  {recommendedProduct.price.toLocaleString()}원
                </span>
                <PriceDelta 
                  currentPrice={recommendedProduct.price}
                  avgPrice={recommendedProduct.avgPrice}
                  size="large"
                />
              </div>
              <p className="text-body text-[#6B7280]">
                평균 대비 {Math.round(((recommendedProduct.avgPrice - recommendedProduct.price) / recommendedProduct.avgPrice) * 100)}% 저렴해요
              </p>
            </div>
          </button>

          {/* Trust Message */}
          <div className="p-4 rounded-2xl bg-[#F0FDF4] border border-[#16A34A]/20 mb-4">
            <div className="flex items-start gap-2">
              <Check className="w-5 h-5 text-[#16A34A] flex-shrink-0 mt-0.5" />
              <p className="text-body text-[#16A34A]">
                {petData.name}의 영양 요구사항 {recommendedProduct.matchScore}% 부합 (알레르기 피함, 체중 관리 적합)
              </p>
            </div>
          </div>

          {/* Simple Reason */}
          <div className="flex items-start gap-3 p-4 rounded-2xl bg-[#F7F8FA]">
            <div className="w-10 h-10 rounded-full bg-[#EFF6FF] flex items-center justify-center flex-shrink-0">
              <svg className="w-5 h-5 text-[#2563EB]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <div className="flex-1">
              <h3 className="text-body text-[#111827] mb-1">왜 이 제품?</h3>
              <p className="text-sub text-[#6B7280]">
                {petData.name}의 나이 {petData.age}살, 체중 {petData.weight}kg, BCS {petData.bcs} 기반 최적 선택
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Sticky CTA */}
      <div className="fixed bottom-16 left-0 right-0 max-w-[375px] mx-auto px-4 pb-4 bg-gradient-to-t from-white via-white to-transparent pt-4">
        <PrimaryButton onClick={() => onNavigateToProduct(recommendedProduct)}>
          상세보기
        </PrimaryButton>
      </div>
    </div>
  );
}
