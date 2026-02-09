import { ChevronRight, Info } from 'lucide-react';

type SectionHeaderProps = {
  title: string;
  subtitle?: string;
  count?: number;
  showInfo?: boolean;
  onViewAll?: () => void;
};

export function SectionHeader({ title, subtitle, count, showInfo, onViewAll }: SectionHeaderProps) {
  return (
    <div className="flex items-center justify-between">
      <div className="flex items-center gap-2">
        <h2 className="text-title text-[#111827]">{title}</h2>
        {showInfo && (
          <button className="w-5 h-5 rounded-full bg-[#F7F8FA] flex items-center justify-center">
            <Info className="w-3.5 h-3.5 text-[#6B7280]" />
          </button>
        )}
        {count !== undefined && (
          <span className="text-body text-[#2563EB]">{count}개</span>
        )}
      </div>
      {onViewAll && (
        <button
          onClick={onViewAll}
          className="flex items-center gap-1 text-sub text-[#6B7280] hover:text-[#2563EB] active:scale-95 transition-all"
        >
          <ChevronRight className="w-5 h-5" />
        </button>
      )}
    </div>
  );
}