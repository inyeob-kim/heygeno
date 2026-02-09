type PillChipProps = {
  label: string;
  selected: boolean;
  onClick: () => void;
};

export function PillChip({ label, selected, onClick }: PillChipProps) {
  return (
    <button
      onClick={onClick}
      className={`h-9 px-4 rounded-full text-sub whitespace-nowrap transition-all duration-150 active:scale-95 ${
        selected
          ? 'bg-[#2563EB] text-white'
          : 'bg-[#F7F8FA] text-[#111827] hover:bg-[#E5E7EB]'
      }`}
    >
      {label}
    </button>
  );
}
