import { AppBar } from '../components/AppBar';
import { ChevronRight, Bell, Lock, HelpCircle, LogOut, Edit2 } from 'lucide-react';
import { MatchScoreBadge } from '../components/MatchScoreBadge';
import { petData, mockProducts, recentRecommendations } from '../data/mockData';

export function MyScreen() {
  // Get recent recommendation products
  const recentProducts = recentRecommendations.map(rec => ({
    ...mockProducts.find(p => p.id === rec.productId),
    recommendDate: rec.date,
    recommendScore: rec.matchScore,
    recommendPrice: rec.price,
  }));

  return (
    <div className="pb-6">
      <AppBar title="마이" />
      
      <div className="px-4 space-y-8">
        {/* Greeting */}
        <div className="pt-6 flex items-center justify-between">
          <div>
            <h2 className="text-title text-[#111827] mb-1">
              안녕하세요, {petData.name}님
            </h2>
            <p className="text-sub text-[#6B7280]">
              오늘도 건강한 하루 보내세요
            </p>
          </div>
          <button className="w-10 h-10 rounded-full bg-[#F7F8FA] flex items-center justify-center hover:bg-[#E5E7EB] active:scale-95 transition-all">
            <Edit2 className="w-5 h-5 text-[#6B7280]" />
          </button>
        </div>

        {/* Health Summary Pill */}
        <div className="p-4 rounded-2xl bg-[#F0FDF4] border border-[#16A34A]/20">
          <div className="flex items-center gap-2 mb-3">
            <div className="w-8 h-8 rounded-full bg-[#16A34A] flex items-center justify-center">
              <svg className="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <h3 className="text-body text-[#111827] flex-1">{petData.name}의 건강 리포트</h3>
            <ChevronRight className="w-5 h-5 text-[#6B7280]" />
          </div>
          
          <div className="flex items-center gap-3 mb-3">
            <div className="text-4xl">🐕</div>
            <div className="flex-1">
              <p className="text-body text-[#111827] mb-1">
                {petData.breed}, {petData.age}살
              </p>
              <p className="text-sub text-[#6B7280]">
                체중 {petData.weight}kg · BCS {petData.bcs}
              </p>
            </div>
          </div>
          
          <div className="p-3 rounded-xl bg-white/50">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sub text-[#6B7280]">건강 상태</span>
              <span className="text-sub text-[#16A34A] font-semibold">양호</span>
            </div>
            <div className="w-full h-2 bg-[#16A34A]/20 rounded-full overflow-hidden">
              <div className="h-full bg-[#16A34A] rounded-full" style={{ width: '85%' }} />
            </div>
          </div>
        </div>

        {/* NEW: Recent Recommendation History */}
        <div>
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-body text-[#111827]">최근 추천 히스토리</h3>
            <button className="text-sub text-[#6B7280] hover:text-[#2563EB]">
              전체보기
            </button>
          </div>
          
          <div className="space-y-3">
            {recentProducts.slice(0, 3).map((product) => (
              <button
                key={product.id}
                className="w-full flex items-center gap-3 p-3 rounded-2xl bg-[#F7F8FA] hover:bg-[#E5E7EB] active:scale-[0.99] transition-all"
              >
                <img 
                  src={product.image}
                  alt={product.name}
                  className="w-14 h-14 rounded-xl object-cover flex-shrink-0"
                />
                <div className="flex-1 text-left">
                  <p className="text-[11px] text-[#6B7280] mb-1">{product.recommendDate}</p>
                  <h4 className="text-sub text-[#111827] mb-1 line-clamp-1">{product.name}</h4>
                  <div className="flex items-center gap-2">
                    <MatchScoreBadge score={product.recommendScore} size="small" />
                    <span className="text-sub text-[#6B7280]">
                      {product.recommendPrice.toLocaleString()}원
                    </span>
                  </div>
                </div>
                <ChevronRight className="w-5 h-5 text-[#6B7280] flex-shrink-0" />
              </button>
            ))}
          </div>
        </div>

        {/* Profile Information */}
        <div>
          <h3 className="text-sub text-[#6B7280] mb-3">프로필 정보</h3>
          <div className="space-y-1">
            <button className="w-full flex items-center justify-between p-4 hover:bg-[#F7F8FA] rounded-2xl transition-all">
              <span className="text-body text-[#6B7280]">종류</span>
              <span className="text-body text-[#111827] font-medium">{petData.breed}</span>
            </button>
            <button className="w-full flex items-center justify-between p-4 hover:bg-[#F7F8FA] rounded-2xl transition-all">
              <span className="text-body text-[#6B7280]">나이</span>
              <span className="text-body text-[#111827] font-medium">{petData.age}살</span>
            </button>
            <button className="w-full flex items-center justify-between p-4 hover:bg-[#F7F8FA] rounded-2xl transition-all">
              <span className="text-body text-[#6B7280]">체중</span>
              <span className="text-body text-[#111827] font-medium">{petData.weight}kg</span>
            </button>
          </div>
        </div>

        {/* Settings */}
        <div>
          <h3 className="text-sub text-[#6B7280] mb-3">설정</h3>
          <div className="space-y-1">
            <button className="w-full flex items-center gap-3 p-4 hover:bg-[#F7F8FA] rounded-2xl transition-all">
              <div className="w-8 h-8 rounded-full bg-[#FEF3C7] flex items-center justify-center flex-shrink-0">
                <Bell className="w-5 h-5 text-[#F59E0B]" />
              </div>
              <span className="flex-1 text-left text-body text-[#111827]">알림 설정</span>
              <div className="w-11 h-6 rounded-full bg-[#2563EB] relative">
                <div className="absolute right-1 top-1 w-4 h-4 rounded-full bg-white" />
              </div>
            </button>
            
            <button className="w-full flex items-center gap-3 p-4 hover:bg-[#F7F8FA] rounded-2xl transition-all">
              <div className="w-8 h-8 rounded-full bg-[#F7F8FA] flex items-center justify-center flex-shrink-0">
                <Lock className="w-5 h-5 text-[#6B7280]" />
              </div>
              <span className="flex-1 text-left text-body text-[#111827]">개인정보 보호</span>
              <ChevronRight className="w-5 h-5 text-[#6B7280]" />
            </button>
            
            <button className="w-full flex items-center gap-3 p-4 hover:bg-[#F7F8FA] rounded-2xl transition-all">
              <div className="w-8 h-8 rounded-full bg-[#F7F8FA] flex items-center justify-center flex-shrink-0">
                <HelpCircle className="w-5 h-5 text-[#6B7280]" />
              </div>
              <span className="flex-1 text-left text-body text-[#111827]">도움말</span>
              <ChevronRight className="w-5 h-5 text-[#6B7280]" />
            </button>
          </div>
        </div>

        {/* Point Summary */}
        <div className="p-4 rounded-2xl bg-gradient-to-br from-[#EFF6FF] to-[#F7F8FA]">
          <div className="flex items-center justify-between mb-2">
            <span className="text-body text-[#111827]">사용 가능 포인트</span>
            <span className="text-price text-[#2563EB]">1,850P</span>
          </div>
          <p className="text-sub text-[#6B7280] mb-4">
            다음 구매 시 할인받으세요
          </p>
          <button className="w-full h-11 rounded-xl bg-[#2563EB] text-white text-body hover:bg-[#1d4ed8] active:scale-[0.98] transition-all">
            혜택 보기
          </button>
        </div>
      </div>
    </div>
  );
}
