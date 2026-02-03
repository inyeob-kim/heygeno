import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'route_paths.dart';
import '../../ui/widgets/bottom_nav_shell.dart';
import '../../features/onboarding/presentation/screens/onboarding_wrapper.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/onboarding/data/repositories/onboarding_repository.dart';
import '../../features/pet_profile/presentation/screens/pet_profile_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/watch/presentation/screens/watch_screen.dart';
import '../../features/benefits/presentation/screens/benefits_screen.dart';
import '../../features/me/presentation/screens/me_screen.dart';
import '../../features/product_detail/presentation/screens/product_detail_screen.dart';

/// GoRouter Provider (Riverpod과 연동)
final routerProvider = Provider<GoRouter>((ref) {
  return _createRouter(ref);
});

GoRouter _createRouter(Ref ref) {
  // 각 탭별 NavigatorKey 생성
  final homeNavigatorKey = GlobalKey<NavigatorState>();
  final watchNavigatorKey = GlobalKey<NavigatorState>();
  final benefitsNavigatorKey = GlobalKey<NavigatorState>();
  final meNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    initialLocation: RoutePaths.onboarding,
    redirect: (context, state) async {
      final onboardingRepo = OnboardingRepositoryImpl();
      final isCompleted = await onboardingRepo.isOnboardingCompleted();
      final location = state.uri.path;

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
      // 온보딩 라우트
      GoRoute(
        path: RoutePaths.onboarding,
        name: RoutePaths.onboarding,
        builder: (context, state) => const OnboardingWrapper(),
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
                builder: (context, state) => const MeScreen(),
              ),
            ],
          ),
        ],
      ),
      
      // 상세 화면 (탭 외부)
      GoRoute(
        path: RoutePaths.productDetail,
        name: RoutePaths.productDetail,
        builder: (context, state) {
          final productId = state.pathParameters['id']!;
          return ProductDetailScreen(productId: productId);
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
