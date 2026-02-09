import { ReactNode } from 'react';

type SelectionCardProps = {
  selected: boolean;
  onClick: () => void;
  children: ReactNode;
  emoji?: string;
};

export function SelectionCard({
  selected,
  onClick,
  children,
  emoji
}: SelectionCardProps) {
  return (
    <button
      onClick={onClick}
      className={`w-full min-h-[68px] px-5 py-4 rounded-2xl transition-all duration-200 active:scale-[0.98] ${
        selected
          ? 'bg-[#EFF6FF] ring-2 ring-[#2563EB]'
          : 'bg-[#F7F8FA] hover:bg-[#E5E7EB]'
      }`}
    >
      <div className="flex items-center gap-4">
        {emoji && <span className="text-4xl">{emoji}</span>}
        <div className="flex-1 text-left">
          {children}
        </div>
        <div
          className={`w-6 h-6 rounded-full flex items-center justify-center flex-shrink-0 transition-all duration-150 ${
            selected
              ? 'bg-[#2563EB]'
              : 'bg-white ring-2 ring-[#E5E7EB] ring-inset'
          }`}
        >
          {selected && (
            <svg
              className="w-4 h-4 text-white"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              strokeWidth={3}
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M5 13l4 4L19 7"
              />
            </svg>
          )}
        </div>
      </div>
    </button>
  );
}