import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'route_paths.dart';
import 'router_guards.dart';
import 'route_validators.dart';
import '../../ui/widgets/bottom_nav_shell.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/initial_splash_screen.dart';
import '../../features/pet_profile/presentation/screens/pet_profile_screen.dart';
import '../../features/pet_update/presentation/screens/pet_update_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/watch/presentation/screens/watch_screen.dart';
import '../../features/benefits/presentation/screens/benefits_screen.dart';
import '../../features/market/presentation/screens/market_screen_v2.dart';
import '../../features/me/presentation/screens/my_screen.dart';
import '../../features/product_detail/presentation/screens/product_detail_screen.dart';
import '../../features/pet_profile/presentation/screens/pet_profile_detail_screen.dart';
import '../../features/me/presentation/screens/privacy_settings_screen.dart';
import '../../features/me/presentation/screens/help_screen.dart';
import '../../features/me/presentation/screens/contact_screen.dart';
import '../../features/me/presentation/screens/app_info_screen.dart';
import '../../features/home/presentation/screens/recommendation_animation_screen.dart';
import '../../features/home/presentation/screens/recommendation_detail_screen.dart';
import '../../onboarding_v2/onboarding_flow.dart';
import '../../data/models/pet_summary_dto.dart';
import '../../data/models/recommendation_dto.dart';

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
    redirect: (context, state) => onboardingGuard(context, state, ref),
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
      // 펫 프로필 업데이트 화면
      GoRoute(
        path: '/pet-update/:petId',
        name: 'pet-update',
        builder: (context, state) {
          final petId = state.pathParameters['petId']!;
          return PetUpdateScreen(petId: petId);
        },
      ),
      GoRoute(
        path: RoutePaths.recommendationAnimation,
        name: RoutePaths.recommendationAnimation,
        builder: (context, state) {
          // 데이터 검증
          final errorWidget = validateRecommendationAnimationRoute(state);
          if (errorWidget != null) {
            return errorWidget;
          }
          final petSummary = state.extra as PetSummaryDto;
          return RecommendationAnimationScreen(petSummary: petSummary);
        },
      ),
      GoRoute(
        path: RoutePaths.recommendationDetail,
        name: RoutePaths.recommendationDetail,
        builder: (context, state) {
          // 데이터 검증
          final errorWidget = validateRecommendationDetailRoute(state);
          if (errorWidget != null) {
            return errorWidget;
          }
          final args = state.extra as Map<String, dynamic>;
          final petSummary = args['petSummary'] as PetSummaryDto;
          final recommendations = args['recommendations'] as RecommendationResponseDto;
          
          return RecommendationDetailScreen(
            petSummary: petSummary,
            recommendations: recommendations,
          );
        },
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
                builder: (context, state) => const MarketScreenV2(),
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
