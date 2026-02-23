import { AlertCircle, TrendingDown, Award } from 'lucide-react';

export function AppMockup() {
  return (
    <div className="relative">
      {/* Phone Frame */}
      <div className="relative mx-auto" style={{ width: '320px', height: '640px' }}>
        <div className="absolute inset-0 bg-gray-900 rounded-[3rem] shadow-2xl p-3">
          <div className="bg-white h-full rounded-[2.5rem] overflow-hidden">
            {/* Status Bar */}
            <div className="h-12 flex items-center justify-between px-6 pt-2">
              <div className="text-xs font-semibold">9:41</div>
              <div className="flex gap-1">
                <div className="w-4 h-3 bg-gray-300 rounded-sm"></div>
                <div className="w-4 h-3 bg-gray-300 rounded-sm"></div>
                <div className="w-4 h-3 bg-gray-300 rounded-sm"></div>
              </div>
            </div>

            {/* App Content */}
            <div className="px-5 py-4 space-y-4">
              {/* Header */}
              <div>
                <div className="text-xs font-medium mb-1" style={{ color: '#475569' }}>
                  Royal Canin Mini Adult
                </div>
                <div className="text-2xl font-bold" style={{ color: '#0F172A' }}>
                  Overall Score
                </div>
              </div>

              {/* Score Card */}
              <div className="bg-gradient-to-br from-blue-50 to-blue-100 rounded-2xl p-6 text-center border" style={{ borderColor: '#2563EB' }}>
                <div className="text-6xl font-bold mb-2" style={{ color: '#2563EB' }}>
                  72
                </div>
                <div className="text-sm font-medium" style={{ color: '#475569' }}>
                  out of 100
                </div>
              </div>

              {/* Warning Alert */}
              <div className="bg-red-50 rounded-xl p-4 border" style={{ borderColor: '#EF4444' }}>
                <div className="flex items-start gap-3">
                  <AlertCircle className="w-5 h-5 flex-shrink-0 mt-0.5" style={{ color: '#EF4444' }} />
                  <div>
                    <div className="text-sm font-semibold mb-1" style={{ color: '#EF4444' }}>
                      Harmful Ingredients Detected
                    </div>
                    <div className="text-xs" style={{ color: '#475569' }}>
                      Contains BHA and ethoxyquin
                    </div>
                  </div>
                </div>
              </div>

              {/* Price Comparison */}
              <div className="space-y-2">
                <div className="text-sm font-semibold" style={{ color: '#0F172A' }}>
                  Best Price
                </div>
                
                <div className="bg-teal-50 rounded-lg p-3 border" style={{ borderColor: '#14B8A6' }}>
                  <div className="flex items-center justify-between">
                    <div>
                      <div className="text-xs font-medium mb-1" style={{ color: '#475569' }}>
                        Amazon
                      </div>
                      <div className="text-lg font-bold" style={{ color: '#14B8A6' }}>
                        $42.90
                      </div>
                    </div>
                    <div className="px-3 py-1 rounded-full text-xs font-semibold text-white" style={{ backgroundColor: '#14B8A6' }}>
                      Lowest
                    </div>
                  </div>
                </div>

                <div className="bg-gray-50 rounded-lg p-3">
                  <div className="flex items-center justify-between">
                    <div>
                      <div className="text-xs font-medium mb-1" style={{ color: '#475569' }}>
                        Petco
                      </div>
                      <div className="text-lg font-bold" style={{ color: '#0F172A' }}>
                        $46.50
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Points */}
              <div className="bg-gradient-to-r from-blue-500 to-teal-500 rounded-xl p-4 text-white">
                <div className="flex items-center justify-between">
                  <div>
                    <div className="text-xs opacity-90 mb-1">
                      Current Points
                    </div>
                    <div className="text-2xl font-bold">
                      12,850P
                    </div>
                  </div>
                  <Award className="w-8 h-8 opacity-90" />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Decorative Elements */}
      <div className="absolute -z-10 top-10 -right-10 w-72 h-72 rounded-full opacity-20" style={{ backgroundColor: '#2563EB', filter: 'blur(60px)' }}></div>
      <div className="absolute -z-10 bottom-10 -left-10 w-64 h-64 rounded-full opacity-20" style={{ backgroundColor: '#14B8A6', filter: 'blur(60px)' }}></div>
    </div>
  );
}
