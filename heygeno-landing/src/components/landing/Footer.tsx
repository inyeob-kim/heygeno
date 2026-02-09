import React from 'react';
import { Heart } from 'lucide-react';

export function Footer() {
  return (
    <footer className="py-12 px-6 border-t-2 border-[#22C55E]/40 bg-gradient-to-b from-transparent to-[#D1FAE5]/30">
      <div className="max-w-7xl mx-auto">
        <div className="flex flex-col md:flex-row items-center justify-between gap-6">
          {/* Logo & Copyright */}
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-xl bg-gradient-to-br from-[#10B981] via-[#22C55E] to-[#059669] flex items-center justify-center shadow-lg shadow-[#22C55E]/40">
              <Heart className="w-5 h-5 text-white fill-white" />
            </div>
            <div>
              <p className="font-bold text-[#8B4513]">HeyGeno</p>
              <p className="text-sm text-[#A0826D]">© 2026 HeyGeno. All rights reserved.</p>
            </div>
          </div>

          {/* Links */}
          <div className="flex items-center gap-8 text-sm text-[#A0826D]">
            <a href="#" className="hover:text-[#8B4513] transition-colors">
              이용약관
            </a>
            <a href="#" className="hover:text-[#8B4513] transition-colors">
              개인정보처리방침
            </a>
            <a href="#" className="hover:text-[#8B4513] transition-colors">
              문의하기
            </a>
          </div>
        </div>

        {/* Divider */}
        <div className="mt-8 pt-8 border-t border-[#FFE5CC]/20 text-center">
          <p className="text-sm text-[#A0826D]">
            Made with 💜 for pets and their humans
          </p>
        </div>
      </div>
    </footer>
  );
}
