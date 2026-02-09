import { Home, Heart, ShoppingBag, Gift, User, Plus } from 'lucide-react';
import { Screen } from '../MainApp';

type BottomNavProps = {
  currentScreen: Screen;
  onNavigate: (screen: Screen) => void;
};

export function BottomNav({ currentScreen, onNavigate }: BottomNavProps) {
  const tabs = [
    { id: 'watch' as Screen, label: 'Watch', icon: Heart },
    { id: 'market' as Screen, label: 'Market', icon: ShoppingBag },
    { id: 'fab' as Screen, label: '', icon: Plus }, // FAB
    { id: 'benefits' as Screen, label: 'Benefits', icon: Gift },
    { id: 'my' as Screen, label: 'My', icon: User },
  ];

  // Hide nav on product detail
  if (currentScreen === 'product-detail') return null;

  return (
    <div className="fixed bottom-0 left-0 right-0 max-w-[375px] mx-auto bg-white border-t border-[#F7F8FA]">
      <div className="flex items-center justify-around h-16 px-2">
        {tabs.map((tab) => {
          const Icon = tab.icon;
          const isActive = currentScreen === tab.id;
          const isFAB = tab.id === 'fab';
          
          if (isFAB) {
            return (
              <button
                key={tab.id}
                onClick={() => onNavigate('home')}
                className="w-14 h-14 -mt-6 rounded-full bg-[#2563EB] flex items-center justify-center shadow-lg active:scale-95 transition-all"
              >
                <Plus className="w-7 h-7 text-white" />
              </button>
            );
          }
          
          return (
            <button
              key={tab.id}
              onClick={() => onNavigate(tab.id)}
              className="flex flex-col items-center justify-center gap-1 flex-1 h-full transition-all active:scale-95"
            >
              <Icon 
                className={`w-6 h-6 ${
                  isActive ? 'text-[#2563EB]' : 'text-[#6B7280]'
                }`}
              />
              <span className={`text-[11px] ${
                isActive ? 'text-[#2563EB] font-medium' : 'text-[#6B7280]'
              }`}>
                {tab.label}
              </span>
            </button>
          );
        })}
      </div>
    </div>
  );
}