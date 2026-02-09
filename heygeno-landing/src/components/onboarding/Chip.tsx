type ChipProps = {
  label: string;
  selected: boolean;
  onClick: () => void;
};

export function Chip({ label, selected, onClick }: ChipProps) {
  return (
    <button
      onClick={onClick}
      className={`h-11 px-5 rounded-full text-body transition-all duration-150 active:scale-95 ${
        selected
          ? 'bg-[#2563EB] text-white'
          : 'bg-[#F7F8FA] text-[#111827] hover:bg-[#E5E7EB]'
      }`}
    >
      {label}
    </button>
  );
}