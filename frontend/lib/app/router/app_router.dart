import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'route_paths.dart';
import '../../ui/widgets/bottom_nav_shell.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/initial_splash_screen.dart';
import '../../domain/services/onboarding_service.dart';
import '../../features/pet_profile/presentation/screens/pet_profile_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/watch/presentation/screens/watch_screen.dart';
import '../../features/benefits/presentation/screens/benefits_screen.dart';
import '../../features/market/presentation/screens/market_screen.dart';
import '../../features/me/presentation/screens/my_screen.dart';
import '../../features/product_detail/presentation/screens/product_detail_screen.dart';
import '../../features/pet_profile/presentation/screens/pet_profile_detail_screen.dart';
import '../../features/me/presentation/screens/privacy_settings_screen.dart';
import '../../features/me/presentation/screens/help_screen.dart';
import '../../features/me/presentation/screens/contact_screen.dart';
import '../../features/me/presentation/screens/app_info_screen.dart';
import '../../onboarding_v2/onboarding_flow.dart';
import '../../data/models/pet_summary_dto.dart';

// 루트 네비게이터 키 (바텀 탭 밖의 페이지용) - 전역으로 선언하여 접근 가능하게
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// GoRouter Provider (Riverpod과 연동)
final routerProvider = Provider<GoRouter>((ref) {
  return _createRouter(ref);
});

GoRouter _createRouter(Ref ref) {
  // 각 탭별 NavigatorKey 생성
  final homeNavigatorKey = GlobalKey<NavigatorState>();
  final watchNavigatorKey = GlobalKey<NavigatorState>();
  final marketNavigatorKey = GlobalKey<NavigatorState>();
  final benefitsNavigatorKey = GlobalKey<NavigatorState>();
  final meNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RoutePaths.initialSplash,
    redirect: (context, state) async {
      final location = state.uri.path;
      
      // 초기 스플래시 화면은 리다이렉트하지 않음 (자체적으로 처리)
      if (location == RoutePaths.initialSplash) {
        return null;
      }

      // 상세 페이지 및 펫 추가 페이지는 온보딩 체크 제외
      if (location.startsWith('/products/') || 
          location == RoutePaths.petProfileDetail ||
          location == RoutePaths.onboardingV2) {
        return null;
      }

      // 온보딩 서비스를 통해 완료 여부 확인
      final onboardingService = ref.read(onboardingServiceProvider);
      final isCompleted = await onboardingService.isOnboardingCompleted();

      // A) 온보딩 미완료 → 온보딩으로 리다이렉트
      if (!isCompleted) {
        if (location != RoutePaths.onboarding) {
          return RoutePaths.onboarding;
        }
        return null; // 이미 온보딩 화면이면 그대로
      }

      // B) 온보딩 완료 → 온보딩 화면 접근 시 홈으로 리다이렉트
      if (isCompleted && location == RoutePaths.onboarding) {
        return RoutePaths.home;
      }

      return null; // 리다이렉트 불필요
    },
    routes: [
      // 초기 스플래시 스크린 (앱 시작 시 첫 화면)
      GoRoute(
        path: RoutePaths.initialSplash,
        name: RoutePaths.initialSplash,
        builder: (context, state) => const InitialSplashScreen(),
      ),
      // 온보딩 라우트 (V2)
      GoRoute(
        path: RoutePaths.onboarding,
        name: RoutePaths.onboarding,
        builder: (context, state) => const OnboardingFlowV2(),
      ),
      // 펫 추가용 온보딩 라우트 (V2) - 온보딩 완료 후에도 접근 가능
      GoRoute(
        path: RoutePaths.onboardingV2,
        name: RoutePaths.onboardingV2,
        builder: (context, state) {
          // 쿼리 파라미터를 위젯에 전달하기 위해 extra로 전달
          final isAddPetMode = state.uri.queryParameters['mode'] == 'add_pet';
          return OnboardingFlowV2(isAddPetMode: isAddPetMode);
        },
      ),
      // 스플래시 스크린 (온보딩 완료 후)
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.petProfile,
        name: RoutePaths.petProfile,
        builder: (context, state) => const PetProfileScreen(),
      ),
      
      // 메인 탭 ShellRoute
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BottomNavShell(navigationShell: navigationShell);
        },
        branches: [
          // 홈 탭
          StatefulShellBranch(
            navigatorKey: homeNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.home,
                name: RoutePaths.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // 관심 탭
          StatefulShellBranch(
            navigatorKey: watchNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.watch,
                name: RoutePaths.watch,
                builder: (context, state) => const WatchScreen(),
              ),
            ],
          ),
          // 검색/마켓 탭
          StatefulShellBranch(
            navigatorKey: marketNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.market,
                name: RoutePaths.market,
                builder: (context, state) => const MarketScreen(),
              ),
            ],
          ),
          // 혜택 탭
          StatefulShellBranch(
            navigatorKey: benefitsNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.benefits,
                name: RoutePaths.benefits,
                builder: (context, state) => const BenefitsScreen(),
              ),
            ],
          ),
          // 마이 탭
          StatefulShellBranch(
            navigatorKey: meNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.me,
                name: RoutePaths.me,
                builder: (context, state) => const MyScreen(),
                routes: [
                  // 설정 화면들 (중첩 라우트)
                  GoRoute(
                    path: 'privacy',
                    builder: (context, state) => const PrivacySettingsScreen(),
                  ),
                  GoRoute(
                    path: 'help',
                    builder: (context, state) => const HelpScreen(),
                  ),
                  GoRoute(
                    path: 'contact',
                    builder: (context, state) => const ContactScreen(),
                  ),
                  GoRoute(
                    path: 'app-info',
                    builder: (context, state) => const AppInfoScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      
      // 상세 화면 (탭 외부 - 루트 네비게이터 사용)
      GoRoute(
        path: RoutePaths.productDetail,
        name: RoutePaths.productDetail,
        builder: (context, state) {
          final productId = state.pathParameters['id']!;
          return ProductDetailScreen(productId: productId);
        },
      ),
      GoRoute(
        path: RoutePaths.petProfileDetail,
        name: RoutePaths.petProfileDetail,
        builder: (context, state) {
          final petSummary = state.extra as PetSummaryDto;
          return PetProfileDetailScreen(petSummary: petSummary);
        },
      ),
    ],
  );
}

/// AppRouter 클래스 (기존 호환성 유지)
/// 주의: Riverpod Provider를 사용해야 하므로 직접 사용하지 말고 routerProvider를 사용하세요
class AppRouter {
  // Deprecated: routerProvider를 사용하세요
  static GoRouter get router => throw UnimplementedError('routerProvider를 사용하세요');
}
