type BadgeProps = {
  children: string;
  variant?: 'new' | 'discount' | 'info' | 'success';
};

export function Badge({ children, variant = 'info' }: BadgeProps) {
  const variants = {
    new: 'bg-[#FEE2E2] text-[#EF4444]',
    discount: 'bg-[#FEF2F2] text-[#EF4444]',
    info: 'bg-[#EFF6FF] text-[#2563EB]',
    success: 'bg-[#F0FDF4] text-[#16A34A]',
  };

  return (
    <span className={`inline-block px-2 py-0.5 rounded text-[11px] font-semibold ${variants[variant]}`}>
      {children}
    </span>
  );
}
