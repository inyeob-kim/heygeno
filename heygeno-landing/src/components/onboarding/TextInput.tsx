import { ChangeEvent } from 'react';

type TextInputProps = {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  maxLength?: number;
  type?: 'text' | 'number' | 'date';
  step?: string;
  min?: string;
  max?: string;
};

export function TextInput({
  value,
  onChange,
  placeholder = '',
  maxLength,
  type = 'text',
  step,
  min,
  max
}: TextInputProps) {
  const handleChange = (e: ChangeEvent<HTMLInputElement>) => {
    onChange(e.target.value);
  };

  return (
    <div className="relative">
      <input
        type={type}
        value={value}
        onChange={handleChange}
        placeholder={placeholder}
        maxLength={maxLength}
        step={step}
        min={min}
        max={max}
        className="w-full h-[56px] px-4 bg-[#F7F8FA] border border-transparent rounded-xl text-body text-[#111827] placeholder:text-[#6B7280] focus:border-[#2563EB] focus:bg-white focus:ring-4 focus:ring-[#EFF6FF] outline-none transition-all duration-200"
      />
      {maxLength && (
        <div className="absolute right-4 top-1/2 -translate-y-1/2 text-sub text-[#6B7280]">
          {value.length}/{maxLength}
        </div>
      )}
    </div>
  );
}