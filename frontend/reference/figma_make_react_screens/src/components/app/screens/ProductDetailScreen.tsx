import { Heart, Bell, TrendingDown, Check } from 'lucide-react';
import { AppBar } from '../components/AppBar';
import { PrimaryButton } from '../components/PrimaryButton';
import { MatchScoreBadge } from '../components/MatchScoreBadge';
import { PriceDelta } from '../components/PriceDelta';
import { petData } from '../data/mockData';

type ProductDetailScreenProps = {
  product: any;
  onBack: () => void;
};

export function ProductDetailScreen({ product, onBack }: ProductDetailScreenProps) {
  const priceDelta = Math.round(((product.avgPrice - product.price) / product.avgPrice) * 100);

  return (
    <div className="min-h-screen bg-white">
      <AppBar title="상품 상세" onBack={onBack} />
      
      <div className="pb-24">
        {/* Product Hero */}
        <div className="relative">
          <img 
            src={product.image}
            alt={product.name}
            className="w-full h-80 object-cover"
          />
          <button className="absolute top-4 right-4 w-12 h-12 rounded-full bg-white/90 backdrop-blur-sm flex items-center justify-center active:scale-95 transition-all">
            <Heart className={`w-6 h-6 ${product.isWatched ? 'text-[#EF4444] fill-[#EF4444]' : 'text-[#6B7280]'}`} />
          </button>
          <div className="absolute bottom-4 left-4">
            <MatchScoreBadge score={product.matchScore} size="large" />
          </div>
        </div>

        <div className="px-4 space-y-8 pt-6">
          {/* Product Info */}
          <div>
            <p className="text-sub text-[#6B7280] mb-2">{product.brand}</p>
            <h1 className="text-title text-[#111827] mb-6">{product.name}</h1>
            
            {/* Price Hero - Strongest Visual */}
            <div className="mb-2">
              <div className="flex items-baseline gap-3 mb-2">
                <span className="text-hero text-[#111827]">
                  {product.price.toLocaleString()}원
                </span>
                <PriceDelta 
                  currentPrice={product.price}
                  avgPrice={product.avgPrice}
                  size="large"
                />
              </div>
              <p className="text-body text-[#6B7280]">
                평균 {product.avgPrice.toLocaleString()}원
              </p>
            </div>
          </div>

          {/* Price Comparison Message */}
          <div className="p-4 rounded-2xl bg-[#FEF2F2] border border-[#EF4444]/20">
            <div className="flex items-start gap-2">
              <TrendingDown className="w-5 h-5 text-[#EF4444] flex-shrink-0 mt-0.5" />
              <p className="text-body text-[#EF4444]">
                💰 평균 대비 {priceDelta}% 저렴해요. 지금이 구매 타이밍입니다!
              </p>
            </div>
          </div>

          {/* Price Graph Section */}
          <div>
            <h3 className="text-body text-[#111827] mb-4">가격 추이</h3>
            <div className="h-48 rounded-2xl bg-[#F7F8FA] flex flex-col items-center justify-center p-6">
              <div className="w-full flex items-end justify-between h-32 mb-4">
                {[65, 58, 62, 55, 60, 52, 48].map((height, i) => (
                  <div key={i} className="flex-1 flex flex-col items-center justify-end mx-0.5">
                    <div 
                      className={`w-full rounded-t transition-all ${
                        i === 6 ? 'bg-[#2563EB]' : 'bg-[#E5E7EB]'
                      }`}
                      style={{ height: `${height}%` }}
                    />
                  </div>
                ))}
              </div>
              <div className="flex items-center justify-between w-full text-sub text-[#6B7280]">
                <span>최저 {(product.price * 0.9).toLocaleString()}원</span>
                <span>평균 {product.avgPrice.toLocaleString()}원</span>
                <span>최고 {(product.price * 1.2).toLocaleString()}원</span>
              </div>
            </div>
          </div>

          {/* Match Analysis Section - NEW & ENHANCED */}
          <div>
            <h3 className="text-title text-[#111827] mb-4">{petData.name} 맞춤 분석</h3>
            
            {/* Match Score with Bar */}
            <div className="p-4 rounded-2xl bg-[#F0FDF4] border border-[#16A34A]/20 mb-4">
              <div className="flex items-center justify-between mb-3">
                <span className="text-body text-[#111827]">맞춤 점수</span>
                <span className="text-hero text-[#16A34A]">{product.matchScore}%</span>
              </div>
              <div className="w-full h-3 bg-[#16A34A]/20 rounded-full overflow-hidden">
                <div 
                  className="h-full bg-[#16A34A] rounded-full transition-all"
                  style={{ width: `${product.matchScore}%` }}
                />
              </div>
            </div>

            {/* Match Reasons List */}
            <div className="space-y-3">
              {product.matchReasons?.map((reason: string, index: number) => (
                <div key={index} className="flex items-start gap-3 p-3 rounded-xl bg-[#F7F8FA]">
                  <div className="w-8 h-8 rounded-full bg-[#EFF6FF] flex items-center justify-center flex-shrink-0">
                    <Check className="w-5 h-5 text-[#2563EB]" />
                  </div>
                  <p className="text-body text-[#111827] flex-1">{reason}</p>
                </div>
              ))}
            </div>
          </div>

          {/* Nutritional Analysis */}
          <div>
            <h3 className="text-body text-[#111827] mb-4">영양 성분</h3>
            <div className="space-y-3">
              <div className="flex items-center justify-between p-3 rounded-xl bg-[#F7F8FA]">
                <span className="text-body text-[#111827]">단백질</span>
                <span className="text-body text-[#2563EB] font-semibold">{product.protein}</span>
              </div>
              <div className="flex items-center justify-between p-3 rounded-xl bg-[#F7F8FA]">
                <span className="text-body text-[#111827]">지방</span>
                <span className="text-body text-[#2563EB] font-semibold">{product.fat}</span>
              </div>
              <div className="flex items-center justify-between p-3 rounded-xl bg-[#F7F8FA]">
                <span className="text-body text-[#111827]">섬유질</span>
                <span className="text-body text-[#2563EB] font-semibold">{product.fiber}</span>
              </div>
            </div>
          </div>

          {/* Alert CTA Section */}
          <div className="p-4 rounded-2xl bg-[#FEF3C7]">
            <div className="flex items-start gap-3 mb-3">
              <div className="w-10 h-10 rounded-full bg-white flex items-center justify-center flex-shrink-0">
                <Bell className="w-5 h-5 text-[#F59E0B]" />
              </div>
              <div className="flex-1">
                <h3 className="text-body text-[#111827] mb-1">가격 알림 받기</h3>
                <p className="text-sub text-[#6B7280]">
                  목표 가격 이하로 떨어지면 알려드릴게요
                </p>
              </div>
            </div>
            <PrimaryButton variant="small" onClick={() => {}}>
              알림 설정하기
            </PrimaryButton>
          </div>
        </div>
      </div>

      {/* Sticky Bottom Bar */}
      <div className="fixed bottom-0 left-0 right-0 max-w-[375px] mx-auto bg-white border-t border-[#F7F8FA] p-4">
        <div className="flex gap-3">
          <button className="w-14 h-[56px] rounded-[18px] bg-[#F7F8FA] flex items-center justify-center active:scale-95 transition-all">
            <Heart className={`w-6 h-6 ${product.isWatched ? 'text-[#EF4444] fill-[#EF4444]' : 'text-[#111827]'}`} />
          </button>
          <div className="flex-1">
            <PrimaryButton onClick={() => {}}>
              최저가 구매하기
            </PrimaryButton>
          </div>
        </div>
      </div>
    </div>
  );
}
