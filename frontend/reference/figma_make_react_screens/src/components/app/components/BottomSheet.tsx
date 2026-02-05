import { ReactNode } from 'react';
import { X } from 'lucide-react';

type BottomSheetProps = {
  isOpen: boolean;
  onClose: () => void;
  title?: string;
  children: ReactNode;
};

export function BottomSheet({ isOpen, onClose, title, children }: BottomSheetProps) {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center">
      {/* Backdrop */}
      <div 
        className="absolute inset-0 bg-black/40"
        onClick={onClose}
      />
      
      {/* Sheet */}
      <div className="relative w-full max-w-[375px] bg-white rounded-t-3xl animate-slide-up">
        {/* Handle */}
        <div className="flex justify-center pt-3 pb-2">
          <div className="w-10 h-1 bg-[#E5E7EB] rounded-full" />
        </div>

        {/* Header */}
        {title && (
          <div className="flex items-center justify-between px-4 pb-4">
            <h3 className="text-body text-[#111827] font-semibold">{title}</h3>
            <button
              onClick={onClose}
              className="w-8 h-8 rounded-full hover:bg-[#F7F8FA] flex items-center justify-center active:scale-95 transition-all"
            >
              <X className="w-5 h-5 text-[#6B7280]" />
            </button>
          </div>
        )}

        {/* Content */}
        <div className="px-4 pb-6 max-h-[70vh] overflow-y-auto">
          {children}
        </div>
      </div>
    </div>
  );
}
