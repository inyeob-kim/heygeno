import { ArrowLeft } from 'lucide-react';

type AppBarProps = {
  title: string;
  onBack?: () => void;
  transparent?: boolean;
};

export function AppBar({ title, onBack, transparent = false }: AppBarProps) {
  return (
    <div className={`h-14 flex items-center px-4 ${
      transparent ? 'bg-transparent' : 'bg-white'
    }`}>
      {onBack ? (
        <button
          onClick={onBack}
          className="w-10 h-10 -ml-2 flex items-center justify-center rounded-full hover:bg-[#F7F8FA] active:scale-95 transition-all"
        >
          <ArrowLeft className="w-6 h-6 text-[#111827]" />
        </button>
      ) : (
        <div className="w-10" />
      )}
      <h1 className="flex-1 text-center text-body text-[#111827]">{title}</h1>
      <div className="w-10" />
    </div>
  );
}
