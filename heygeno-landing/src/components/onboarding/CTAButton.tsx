import { ReactNode } from 'react';

type CTAButtonProps = {
  children: ReactNode;
  onClick: () => void;
  disabled?: boolean;
  variant?: 'primary' | 'secondary';
};

export function CTAButton({
  children,
  onClick,
  disabled = false,
  variant = 'primary'
}: CTAButtonProps) {
  const baseStyles = 'w-full h-[56px] rounded-[18px] text-body transition-all duration-200';
  
  const variantStyles = variant === 'primary'
    ? 'bg-[#2563EB] text-white hover:bg-[#1d4ed8] active:scale-[0.98] disabled:bg-[#F7F8FA] disabled:text-[#6B7280] disabled:cursor-not-allowed'
    : 'bg-[#F7F8FA] text-[#111827] hover:bg-[#E5E7EB] active:scale-[0.98]';

  return (
    <button
      onClick={onClick}
      disabled={disabled}
      className={`${baseStyles} ${variantStyles}`}
    >
      {children}
    </button>
  );
}