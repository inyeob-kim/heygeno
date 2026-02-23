export function Footer() {
  return (
    <footer className="border-t border-gray-200 bg-gray-50">
      <div className="layout-container py-10 md:py-12">
        <div className="flex flex-col items-center gap-6 md:gap-8">
          <div className="text-center">
            <h3 className="text-xl font-bold" style={{ color: '#0F172A' }}>
              KibbleWise
            </h3>
            <p className="text-sm" style={{ color: '#64748B' }}>
              © 2026 KibbleWise. All rights reserved.
            </p>
          </div>

          <div className="grid w-full grid-cols-1 gap-3 text-center text-sm md:grid-cols-2 lg:grid-cols-4">
            <a href="#features" style={{ color: '#475569' }}>Features</a>
            <a href="#how-it-works" style={{ color: '#475569' }}>How it Works</a>
            <a href="#trust" style={{ color: '#475569' }}>Trust</a>
            <a href="#contact" style={{ color: '#475569' }}>Contact</a>
          </div>

          <div className="w-full border-t border-gray-200 pt-6 text-center text-sm" style={{ color: '#64748B' }}>
            Made with care for pets and their humans
          </div>
        </div>
      </div>
    </footer>
  );
}
