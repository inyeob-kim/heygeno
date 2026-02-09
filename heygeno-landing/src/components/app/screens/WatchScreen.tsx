import { useState } from 'react';
import { AppBar } from '../components/AppBar';
import { PillChip } from '../components/PillChip';
import { ProductTile } from '../components/ProductTile';
import { EmptyState } from '../components/EmptyState';
import { Grid3x3, List, Star, SlidersHorizontal, TrendingDown } from 'lucide-react';
import { mockProducts, petData } from '../data/mockData';

type WatchScreenProps = {
  onNavigateToProduct: (product: any) => void;
  onNavigateToMarket: () => void;
};

export function WatchScreen({ onNavigateToProduct, onNavigateToMarket }: WatchScreenProps) {
  const [sortBy, setSortBy] = useState('match');
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
  
  const watchedProducts = mockProducts.filter(p => p.isWatched);
  const isEmpty = watchedProducts.length === 0;

  // Calculate good deals count
  const goodDealsCount = watchedProducts.filter(p => {
    const delta = Math.round(((p.avgPrice - p.price) / p.avgPrice) * 100);
    return delta >= 5;
  }).length;

  if (isEmpty) {
    return (
      <div>
        <AppBar title="찜한 사료" />
        <EmptyState
          emoji="❤️"
          title="찜한 사료가 없어요"
          description="관심 있는 사료를 찜하고 가격 알림을 받아보세요"
          ctaText="사료 둘러보기"
          onCTA={onNavigateToMarket}
        />
      </div>
    );
  }

  return (
    <div className="pb-6">
      <AppBar title="찜한 사료" />
      
      <div className="px-4 space-y-6">
        {/* Summary - Numbers First */}
        <div className="pt-4 flex items-center gap-6">
          <div>
            <div className="text-hero text-[#111827] mb-1">{watchedProducts.length}</div>
            <p className="text-sub text-[#6B7280]">총 찜</p>
          </div>
          <div className="w-px h-12 bg-[#E5E7EB]" />
          <div>
            <div className="flex items-baseline gap-2 mb-1">
              <span className="text-hero text-[#2563EB]">{goodDealsCount}</span>
              <span className="text-body text-[#6B7280]">/ {watchedProducts.length}개</span>
            </div>
            <p className="text-sub text-[#6B7280]">평균 대비 -5% 이상</p>
          </div>
        </div>

        {/* Sorting Chips */}
        <div className="flex gap-2 overflow-x-auto pb-2 -mx-4 px-4 scrollbar-hide">
          <PillChip 
            label="맞춤 점수" 
            selected={sortBy === 'match'} 
            onClick={() => setSortBy('match')}
          />
          <PillChip 
            label="최저가" 
            selected={sortBy === 'lowest'} 
            onClick={() => setSortBy('lowest')}
          />
          <PillChip 
            label="안정 가격" 
            selected={sortBy === 'stable'} 
            onClick={() => setSortBy('stable')}
          />
          <PillChip 
            label="인기" 
            selected={sortBy === 'popular'} 
            onClick={() => setSortBy('popular')}
          />
        </div>

        {/* Toolbar */}
        <div className="flex items-center justify-between">
          <button className="flex items-center gap-1 h-9 px-3 rounded-lg bg-[#F7F8FA] text-sub text-[#111827] hover:bg-[#E5E7EB] active:scale-95 transition-all">
            <SlidersHorizontal className="w-4 h-4" />
            필터
          </button>
          <div className="flex gap-1">
            <button 
              onClick={() => setViewMode('grid')}
              className={`w-9 h-9 rounded-lg flex items-center justify-center transition-all ${
                viewMode === 'grid' ? 'bg-[#111827] text-white' : 'bg-[#F7F8FA] text-[#6B7280]'
              }`}
            >
              <Grid3x3 className="w-5 h-5" />
            </button>
            <button 
              onClick={() => setViewMode('list')}
              className={`w-9 h-9 rounded-lg flex items-center justify-center transition-all ${
                viewMode === 'list' ? 'bg-[#111827] text-white' : 'bg-[#F7F8FA] text-[#6B7280]'
              }`}
            >
              <List className="w-5 h-5" />
            </button>
          </div>
        </div>

        {/* Product Grid with Match Score */}
        <div className="grid grid-cols-2 gap-4">
          {watchedProducts
            .sort((a, b) => sortBy === 'match' ? b.matchScore - a.matchScore : a.price - b.price)
            .map((product) => (
              <ProductTile
                key={product.id}
                product={product}
                onClick={() => onNavigateToProduct(product)}
                layout="grid"
              />
            ))}
        </div>
      </div>
    </div>
  );
}
