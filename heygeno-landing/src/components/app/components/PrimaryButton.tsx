import { ReactNode } from 'react';

type PrimaryButtonProps = {
  children: ReactNode;
  onClick: () => void;
  variant?: 'primary' | 'secondary' | 'small';
  disabled?: boolean;
};

export function PrimaryButton({ 
  children, 
  onClick, 
  variant = 'primary',
  disabled = false 
}: PrimaryButtonProps) {
  if (variant === 'small') {
    return (
      <button
        onClick={onClick}
        disabled={disabled}
        className="h-9 px-4 rounded-xl bg-[#2563EB] text-white text-sub hover:bg-[#1d4ed8] active:scale-95 transition-all disabled:bg-[#F7F8FA] disabled:text-[#6B7280]"
      >
        {children}
      </button>
    );
  }

  if (variant === 'secondary') {
    return (
      <button
        onClick={onClick}
        disabled={disabled}
        className="w-full h-[56px] rounded-[18px] bg-[#F7F8FA] text-[#111827] text-body hover:bg-[#E5E7EB] active:scale-[0.98] transition-all"
      >
        {children}
      </button>
    );
  }

  return (
    <button
      onClick={onClick}
      disabled={disabled}
      className="w-full h-[56px] rounded-[18px] bg-[#2563EB] text-white text-body hover:bg-[#1d4ed8] active:scale-[0.98] transition-all disabled:bg-[#F7F8FA] disabled:text-[#6B7280]"
    >
      {children}
    </button>
  );
}
