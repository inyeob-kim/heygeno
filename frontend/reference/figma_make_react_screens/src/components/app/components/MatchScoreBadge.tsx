type MatchScoreBadgeProps = {
  score: number;
  size?: 'small' | 'medium' | 'large';
};

export function MatchScoreBadge({ score, size = 'small' }: MatchScoreBadgeProps) {
  const getColor = (score: number) => {
    if (score >= 90) return 'text-[#16A34A] bg-[#F0FDF4]';
    if (score >= 80) return 'text-[#2563EB] bg-[#EFF6FF]';
    return 'text-[#6B7280] bg-[#F7F8FA]';
  };

  const sizes = {
    small: 'text-[11px] px-2 py-0.5',
    medium: 'text-sub px-3 py-1',
    large: 'text-body px-4 py-2',
  };

  return (
    <div className={`inline-flex items-center gap-1 rounded-full font-semibold ${getColor(score)} ${sizes[size]}`}>
      <svg className="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
        <path d="M3.172 5.172a4 4 0 015.656 0L10 6.343l1.172-1.171a4 4 0 115.656 5.656L10 17.657l-6.828-6.829a4 4 0 010-5.656z" />
      </svg>
      <span>{score}%</span>
    </div>
  );
}
