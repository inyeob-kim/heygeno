type PriceDeltaProps = {
  currentPrice: number;
  avgPrice: number;
  size?: 'small' | 'medium' | 'large';
};

export function PriceDelta({ currentPrice, avgPrice, size = 'medium' }: PriceDeltaProps) {
  const delta = Math.round(((avgPrice - currentPrice) / avgPrice) * 100);
  
  if (delta <= 0) return null;

  const sizes = {
    small: 'text-[11px] px-2 py-0.5',
    medium: 'text-sub px-3 py-1',
    large: 'text-body px-4 py-2',
  };

  return (
    <div className={`inline-flex items-center gap-1 rounded-full font-semibold bg-[#FEF2F2] text-[#EF4444] ${sizes[size]}`}>
      <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={3}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M19 14l-7 7m0 0l-7-7m7 7V3" />
      </svg>
      <span>{delta}% 좋은 딜</span>
    </div>
  );
}
