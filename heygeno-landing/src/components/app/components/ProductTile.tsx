import { Heart } from 'lucide-react';
import { Badge } from './Badge';
import { MatchScoreBadge } from './MatchScoreBadge';
import { PriceDelta } from './PriceDelta';

type ProductTileProps = {
  product: {
    id: string;
    name: string;
    brand: string;
    price: number;
    comparePrice?: number;
    avgPrice: number;
    matchScore: number;
    image: string;
    isWatched?: boolean;
    badge?: string;
  };
  onClick: () => void;
  layout?: 'grid' | 'horizontal';
};

export function ProductTile({ product, onClick, layout = 'grid' }: ProductTileProps) {
  const discount = product.comparePrice 
    ? Math.round(((product.comparePrice - product.price) / product.comparePrice) * 100)
    : 0;

  if (layout === 'horizontal') {
    return (
      <button
        onClick={onClick}
        className="flex-shrink-0 w-[140px] active:scale-95 transition-all"
      >
        <div className="relative aspect-square rounded-2xl overflow-hidden bg-[#F7F8FA] mb-3">
          <img 
            src={product.image} 
            alt={product.name}
            className="w-full h-full object-cover"
          />
          {product.isWatched && (
            <div className="absolute top-2 right-2 w-8 h-8 rounded-full bg-white/90 backdrop-blur-sm flex items-center justify-center">
              <Heart className="w-4 h-4 text-[#EF4444] fill-[#EF4444]" />
            </div>
          )}
          <div className="absolute top-2 left-2">
            <MatchScoreBadge score={product.matchScore} size="small" />
          </div>
          {product.badge && (
            <div className="absolute bottom-2 left-2">
              <Badge variant="info">{product.badge}</Badge>
            </div>
          )}
        </div>
        <div className="text-left">
          <p className="text-sub text-[#6B7280] mb-1">{product.brand}</p>
          <h3 className="text-body text-[#111827] mb-2 line-clamp-2 leading-tight">
            {product.name}
          </h3>
          <div className="flex items-center gap-2 mb-1">
            {discount > 0 && (
              <span className="text-sub text-[#EF4444] font-semibold">
                {discount}%
              </span>
            )}
            <span className="text-price text-[#111827]">
              {product.price.toLocaleString()}원
            </span>
          </div>
          <PriceDelta currentPrice={product.price} avgPrice={product.avgPrice} size="small" />
        </div>
      </button>
    );
  }

  return (
    <button
      onClick={onClick}
      className="w-full active:scale-95 transition-all"
    >
      <div className="relative aspect-square rounded-2xl overflow-hidden bg-[#F7F8FA] mb-3">
        <img 
          src={product.image} 
          alt={product.name}
          className="w-full h-full object-cover"
        />
        {product.isWatched && (
          <div className="absolute top-2 right-2 w-8 h-8 rounded-full bg-white/90 backdrop-blur-sm flex items-center justify-center">
            <Heart className="w-4 h-4 text-[#EF4444] fill-[#EF4444]" />
          </div>
        )}
        <div className="absolute top-2 left-2">
          <MatchScoreBadge score={product.matchScore} size="small" />
        </div>
        {product.badge && (
          <div className="absolute bottom-2 left-2">
            <Badge variant="info">{product.badge}</Badge>
          </div>
        )}
      </div>
      <div className="text-left">
        <p className="text-sub text-[#6B7280] mb-1">{product.brand}</p>
        <h3 className="text-[15px] font-medium text-[#111827] mb-2 line-clamp-2 leading-tight">
          {product.name}
        </h3>
        <div className="flex items-center gap-2 mb-1">
          {discount > 0 && (
            <span className="text-sub text-[#EF4444] font-semibold">
              {discount}%
            </span>
          )}
          <span className="text-[18px] font-bold text-[#111827]">
            {product.price.toLocaleString()}원
          </span>
        </div>
        <PriceDelta currentPrice={product.price} avgPrice={product.avgPrice} size="small" />
      </div>
    </button>
  );
}