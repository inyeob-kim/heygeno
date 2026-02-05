import { useState } from 'react';
import { SectionHeader } from '../components/SectionHeader';
import { SearchBar } from '../components/SearchBar';
import { ProductTile } from '../components/ProductTile';
import { PillChip } from '../components/PillChip';
import { mockProducts, petData } from '../data/mockData';

type MarketScreenProps = {
  onNavigateToProduct: (product: any) => void;
};

export function MarketScreen({ onNavigateToProduct }: MarketScreenProps) {
  const [selectedCategory, setSelectedCategory] = useState('all');
  
  const categories = ['전체', '강아지 사료', '고양이 사료', '간식', '영양제'];
  const hotDeals = mockProducts.filter(p => p.comparePrice);
  const popular = mockProducts.slice(0, 4);
  // New: Personalized for pet
  const personalized = mockProducts
    .sort((a, b) => b.matchScore - a.matchScore)
    .slice(0, 4);

  return (
    <div className="pb-6">
      {/* Sliver AppBar */}
      <div className="sticky top-0 bg-white z-10">
        <div className="h-14 flex items-center px-4">
          <h1 className="text-body text-[#111827]">사료마켓</h1>
        </div>
        <div className="px-4 pb-4">
          <SearchBar placeholder="사료 브랜드나 제품명을 검색하세요" />
        </div>
      </div>

      <div className="space-y-8">
        {/* Hot Deals Section */}
        <div>
          <div className="px-4 mb-4">
            <SectionHeader title="오늘의 핫딜" />
          </div>
          <div className="flex gap-3 overflow-x-auto px-4 pb-2 scrollbar-hide">
            {hotDeals.map((product) => (
              <ProductTile
                key={product.id}
                product={product}
                onClick={() => onNavigateToProduct(product)}
                layout="horizontal"
              />
            ))}
          </div>
        </div>

        {/* Popular Section */}
        <div>
          <div className="px-4 mb-4">
            <SectionHeader title="실시간 인기 사료" />
          </div>
          <div className="flex gap-3 overflow-x-auto px-4 pb-2 scrollbar-hide">
            {popular.map((product) => (
              <ProductTile
                key={product.id}
                product={product}
                onClick={() => onNavigateToProduct(product)}
                layout="horizontal"
              />
            ))}
          </div>
        </div>

        {/* NEW: Personalized Section */}
        <div>
          <div className="px-4 mb-4">
            <SectionHeader 
              title={`${petData.name}에게 추천`}
              subtitle={`${petData.age}살 · ${petData.breed} 맞춤`}
              showInfo={true}
            />
          </div>
          <div className="flex gap-3 overflow-x-auto px-4 pb-2 scrollbar-hide">
            {personalized.map((product) => (
              <ProductTile
                key={product.id}
                product={product}
                onClick={() => onNavigateToProduct(product)}
                layout="horizontal"
              />
            ))}
          </div>
        </div>

        {/* Category Chips */}
        <div className="px-4">
          <div className="flex gap-2 overflow-x-auto pb-2 -mx-4 px-4 scrollbar-hide">
            {categories.map((category) => (
              <PillChip
                key={category}
                label={category}
                selected={selectedCategory === category.toLowerCase()}
                onClick={() => setSelectedCategory(category.toLowerCase())}
              />
            ))}
          </div>
        </div>

        {/* Full Product Grid */}
        <div className="px-4">
          <div className="grid grid-cols-2 gap-4">
            {mockProducts.map((product) => (
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
    </div>
  );
}