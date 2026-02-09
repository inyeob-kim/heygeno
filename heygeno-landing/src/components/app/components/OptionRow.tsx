import { ReactNode } from 'react';
import { ChevronRight } from 'lucide-react';

type OptionRowProps = {
  icon: ReactNode;
  label: string;
  badge?: string;
  hasChevron?: boolean;
  onClick?: () => void;
};

export function OptionRow({ icon, label, badge, hasChevron = true, onClick }: OptionRowProps) {
  return (
    <button
      onClick={onClick}
      className="w-full flex items-center gap-3 py-4 hover:bg-[#F7F8FA] active:bg-[#F7F8FA] transition-all"
    >
      <div className="flex-shrink-0">
        {icon}
      </div>
      <span className="flex-1 text-left text-body text-[#111827]">{label}</span>
      {badge && (
        <span className="px-2 py-0.5 rounded text-[11px] font-semibold bg-[#FEE2E2] text-[#EF4444]">
          {badge}
        </span>
      )}
      {hasChevron && (
        <ChevronRight className="w-5 h-5 text-[#6B7280]" />
      )}
    </button>
  );
}
