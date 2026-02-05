import { ReactNode } from 'react';
import { PrimaryButton } from './PrimaryButton';

type InfoBannerProps = {
  icon?: string;
  title: string;
  description: string;
  ctaText: string;
  onCTA: () => void;
  variant?: 'default' | 'yellow' | 'blue';
};

export function InfoBanner({ 
  icon, 
  title, 
  description, 
  ctaText, 
  onCTA,
  variant = 'default'
}: InfoBannerProps) {
  const variants = {
    default: 'bg-[#F7F8FA]',
    yellow: 'bg-[#FEF3C7]',
    blue: 'bg-[#EFF6FF]',
  };

  const buttonVariants = {
    default: 'bg-[#111827]',
    yellow: 'bg-[#111827]',
    blue: 'bg-[#2563EB]',
  };

  return (
    <div className={`p-4 rounded-2xl ${variants[variant]}`}>
      {icon && (
        <div className="text-2xl mb-3">{icon}</div>
      )}
      <h3 className="text-body text-[#111827] mb-2">{title}</h3>
      <p className="text-sub text-[#6B7280] mb-4">{description}</p>
      <button
        onClick={onCTA}
        className={`w-full h-12 rounded-xl ${buttonVariants[variant]} text-white text-body hover:opacity-90 active:scale-[0.98] transition-all`}
      >
        {ctaText}
      </button>
    </div>
  );
}
