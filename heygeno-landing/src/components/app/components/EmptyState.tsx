import { ReactNode } from 'react';
import { PrimaryButton } from './PrimaryButton';

type EmptyStateProps = {
  emoji: string;
  title: string;
  description: string;
  ctaText?: string;
  onCTA?: () => void;
};

export function EmptyState({ emoji, title, description, ctaText, onCTA }: EmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center py-16 px-4">
      <div className="text-7xl mb-6">{emoji}</div>
      <h3 className="text-title text-[#111827] mb-3 text-center">{title}</h3>
      <p className="text-body text-[#6B7280] text-center mb-8 max-w-[280px]">
        {description}
      </p>
      {ctaText && onCTA && (
        <div className="w-full max-w-[280px]">
          <PrimaryButton onClick={onCTA}>
            {ctaText}
          </PrimaryButton>
        </div>
      )}
    </div>
  );
}
