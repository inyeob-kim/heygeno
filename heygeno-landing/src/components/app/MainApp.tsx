import { useState } from 'react';
import { HomeScreen } from './screens/HomeScreen';
import { WatchScreen } from './screens/WatchScreen';
import { MarketScreen } from './screens/MarketScreen';
import { BenefitsScreen } from './screens/BenefitsScreen';
import { MyScreen } from './screens/MyScreen';
import { ProductDetailScreen } from './screens/ProductDetailScreen';
import { BottomNav } from './components/BottomNav';

export type Screen = 'home' | 'watch' | 'market' | 'benefits' | 'my' | 'product-detail';

export function MainApp() {
  const [currentScreen, setCurrentScreen] = useState<Screen>('home');
  const [selectedProduct, setSelectedProduct] = useState<any>(null);

  const navigateToProductDetail = (product: any) => {
    setSelectedProduct(product);
    setCurrentScreen('product-detail');
  };

  const navigateToMarket = () => {
    setCurrentScreen('market');
  };

  return (
    <div className="min-h-screen bg-[#F7F8FA]">
      <div className="max-w-[375px] mx-auto bg-white min-h-screen relative pb-20">
        {currentScreen === 'home' && (
          <HomeScreen onNavigateToProduct={navigateToProductDetail} />
        )}
        {currentScreen === 'watch' && (
          <WatchScreen 
            onNavigateToProduct={navigateToProductDetail}
            onNavigateToMarket={navigateToMarket}
          />
        )}
        {currentScreen === 'market' && (
          <MarketScreen onNavigateToProduct={navigateToProductDetail} />
        )}
        {currentScreen === 'benefits' && <BenefitsScreen />}
        {currentScreen === 'my' && <MyScreen />}
        {currentScreen === 'product-detail' && selectedProduct && (
          <ProductDetailScreen 
            product={selectedProduct}
            onBack={() => setCurrentScreen('home')}
          />
        )}

        <BottomNav 
          currentScreen={currentScreen} 
          onNavigate={setCurrentScreen}
        />
      </div>
    </div>
  );
}
