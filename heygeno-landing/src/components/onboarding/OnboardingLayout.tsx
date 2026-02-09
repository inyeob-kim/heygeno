import { ReactNode } from 'react';
import { ArrowLeft } from 'lucide-react';
import { ProgressBar } from './ProgressBar';
import { CTAButton } from './CTAButton';

type OnboardingLayoutProps = {
  currentStep: number;
  totalSteps: number;
  onBack?: () => void;
  emoji: string;
  title: string;
  subtitle?: string;
  children: ReactNode;
  ctaText: string;
  ctaDisabled?: boolean;
  onCTAClick: () => void;
  ctaSecondary?: {
    text: string;
    onClick: () => void;
  };
};

export function OnboardingLayout({
  currentStep,
  totalSteps,
  onBack,
  emoji,
  title,
  subtitle,
  children,
  ctaText,
  ctaDisabled = false,
  onCTAClick,
  ctaSecondary
}: OnboardingLayoutProps) {
  return (
    <div className="bg-white min-h-[667px] flex flex-col">
      {/* Progress Bar */}
      <div className="px-4 pt-5">
        <ProgressBar current={currentStep} total={totalSteps} />
      </div>

      {/* Back Button */}
      {onBack && (
        <button
          onClick={onBack}
          className="mt-4 ml-4 w-11 h-11 flex items-center justify-center rounded-full hover:bg-[#F7F8FA] active:scale-95 transition-all"
          aria-label="Go back"
        >
          <ArrowLeft className="w-6 h-6 text-[#111827]" />
        </button>
      )}

      {/* Scrollable Content Area */}
      <div className="flex-1 overflow-y-auto">
        {/* Header */}
        <div className={`px-4 ${onBack ? 'mt-8' : 'mt-10'}`}>
          <div className="text-[80px] leading-none mb-6">{emoji}</div>
          <h1 className="text-title text-[#111827] mb-3">
            {title}
          </h1>
          {subtitle && (
            <p className="text-body text-[#6B7280]">
              {subtitle}
            </p>
          )}
        </div>

        {/* Content */}
        <div className="px-4 mt-8 pb-6">{children}</div>
      </div>

      {/* Bottom CTA */}
      <div className="px-4 pb-6 pt-4 bg-white">
        <div className="space-y-3">
          <CTAButton
            onClick={onCTAClick}
            disabled={ctaDisabled}
            variant="primary"
          >
            {ctaText}
          </CTAButton>
          {ctaSecondary && (
            <CTAButton
              onClick={ctaSecondary.onClick}
              variant="secondary"
            >
              {ctaSecondary.text}
            </CTAButton>
          )}
        </div>
      </div>
    </div>
  );
}