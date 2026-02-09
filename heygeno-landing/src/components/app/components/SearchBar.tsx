import { Search } from 'lucide-react';

type SearchBarProps = {
  placeholder?: string;
  onSearch?: (query: string) => void;
};

export function SearchBar({ placeholder = 'Search products', onSearch }: SearchBarProps) {
  return (
    <div className="relative">
      <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-[#6B7280]" />
      <input
        type="text"
        placeholder={placeholder}
        onChange={(e) => onSearch?.(e.target.value)}
        className="w-full h-12 pl-12 pr-4 bg-[#F7F8FA] rounded-2xl text-body text-[#111827] placeholder:text-[#6B7280] focus:bg-white focus:ring-2 focus:ring-[#EFF6FF] outline-none transition-all"
      />
    </div>
  );
}
