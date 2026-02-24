import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'route_paths.dart';
import 'router_guards.dart';
import 'route_validators.dart';
import '../../ui/widgets/bottom_nav_shell.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/initial_splash_screen.dart';
import '../../features/onboarding/presentation/screens/welcome_screen.dart';
import '../../features/pet_profile/presentation/screens/pet_profile_screen.dart';
import '../../features/pet_update/presentation/screens/pet_update_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/watch/presentation/screens/watch_screen.dart';
import '../../features/find/presentation/screens/find_screen.dart';
import '../../features/benefits/presentation/screens/benefits_screen.dart';
import '../../features/market/presentation/screens/market_screen_v2.dart';
import '../../features/me/presentation/screens/my_screen.dart';
import '../../features/product_detail/presentation/screens/product_detail_screen.dart';
import '../../features/pet_profile/presentation/screens/pet_profile_detail_screen.dart';
import '../../features/me/presentation/screens/privacy_settings_screen.dart';
import '../../features/me/presentation/screens/help_screen.dart';
import '../../features/me/presentation/screens/contact_screen.dart';
import '../../features/me/presentation/screens/app_info_screen.dart';
import '../../features/me/presentation/screens/account_manage_screen.dart';
import '../../features/me/presentation/screens/recommendation_history_screen.dart';
import '../../features/home/presentation/screens/recommendation_animation_screen.dart';
import '../../features/home/presentation/screens/recommendation_detail_screen.dart';
import '../../onboarding_chat_v3/onboarding_chat_flow.dart';
import '../../features/auth/presentation/screens/start_screen.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/recommendation/presentation/screens/quick_profile_wizard.dart';
import '../../features/recommendation/presentation/screens/quick_recommendation_list_screen.dart';
import '../../data/repositories/recommendation_repository.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/auth/presentation/screens/verify_email_screen.dart';
import 'recommendation_animation_args.dart';
import '../../data/models/pet_summary_dto.dart';
import '../../data/models/recommendation_dto.dart';

// 루트 네비게이터 키 (바텀 탭 밖의 페이지용) - 전역으로 선언하여 접근 가능하게
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// GoRouter Provider (Riverpod과 연동)
final routerProvider = Provider<GoRouter>((ref) {
  return _createRouter(ref);
});

GoRouter _createRouter(Ref ref) {
  // 각 탭별 NavigatorKey 생성 (4탭 구조: Home, Match, Market, Alerts)
  final homeNavigatorKey = GlobalKey<NavigatorState>();
  final matchNavigatorKey = GlobalKey<NavigatorState>();
  final marketNavigatorKey = GlobalKey<NavigatorState>();
  final alertsNavigatorKey = GlobalKey<NavigatorState>();

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
      // 시작 화면 (게스트 우선)
      GoRoute(
        path: RoutePaths.start,
        name: RoutePaths.start,
        builder: (context, state) => const StartScreen(),
      ),
      // Quick recommendation flow (anonymous)
      GoRoute(
        path: RoutePaths.quickProfileWizard,
        name: RoutePaths.quickProfileWizard,
        builder: (context, state) => const QuickProfileWizard(),
      ),
      GoRoute(
        path: RoutePaths.quickRecommendationList,
        name: RoutePaths.quickRecommendationList,
        builder: (context, state) {
          final response = state.extra as QuickRecommendationResponseDto;
          return QuickRecommendationListScreen(response: response);
        },
      ),
      // 인증 라우트 (설정 화면 "계정 연결" 등에서 진입)
      GoRoute(
        path: RoutePaths.signIn,
        name: RoutePaths.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: RoutePaths.signUp,
        name: RoutePaths.signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: RoutePaths.verifyEmail,
        name: RoutePaths.verifyEmail,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          final token = state.uri.queryParameters['token'];
          return VerifyEmailScreen(email: email, token: token);
        },
      ),
      // 온보딩 라우트 (채팅형만 사용)
      GoRoute(
        path: RoutePaths.onboarding,
        name: RoutePaths.onboarding,
        builder: (context, state) => const OnboardingChatFlow(),
      ),
      // 펫 추가용 온보딩 (채팅형, 온보딩 완료 후에도 접근 가능)
      GoRoute(
        path: RoutePaths.onboardingV2,
        name: RoutePaths.onboardingV2,
        builder: (context, state) {
          final isAddPetMode = state.uri.queryParameters['mode'] == 'add_pet';
          return OnboardingChatFlow(isAddPetMode: isAddPetMode);
        },
      ),
      // 환영 스크린 (온보딩 직후, 홈으로 이동)
      GoRoute(
        path: RoutePaths.welcome,
        name: RoutePaths.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      // 스플래시 스크린 (레거시)
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
          final errorWidget = validateRecommendationAnimationRoute(state);
          if (errorWidget != null) {
            return errorWidget;
          }
          final RecommendationAnimationArgs args = state.extra is RecommendationAnimationArgs
              ? state.extra as RecommendationAnimationArgs
              : RecommendationAnimationArgs(petSummary: state.extra as PetSummaryDto);
          return RecommendationAnimationScreen(
            petSummary: args.petSummary,
            preloadedRecommendations: args.preloadedRecommendations,
            quickParams: args.quickParams,
          );
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
      
      // 메인 탭 ShellRoute (4탭 구조: Home, Match, Market, Alerts)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BottomNavShell(navigationShell: navigationShell);
        },
        branches: [
          // 0: Home 탭
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
          // 1: Match 탭 (추천 엔진 + 성분 분석)
          StatefulShellBranch(
            navigatorKey: matchNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.match,
                name: RoutePaths.match,
                builder: (context, state) => const FindScreen(), // TODO: MatchScreen으로 이름 변경
              ),
              // Legacy: /find → /match로 리다이렉트
              GoRoute(
                path: RoutePaths.find,
                redirect: (context, state) => RoutePaths.match,
              ),
            ],
          ),
          // 2: Market 탭 (멀티플랫폼 가격 비교)
          StatefulShellBranch(
            navigatorKey: marketNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.market,
                name: RoutePaths.market,
                builder: (context, state) => const MarketScreenV2(),
              ),
              // Legacy: /deals → /market로 리다이렉트
              GoRoute(
                path: RoutePaths.deals,
                redirect: (context, state) => RoutePaths.market,
              ),
            ],
          ),
          // 3: Alerts 탭 (알림, 기존 Watch)
          StatefulShellBranch(
            navigatorKey: alertsNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.alerts,
                name: RoutePaths.alerts,
                builder: (context, state) => const WatchScreen(),
              ),
              // Legacy: /watch → /alerts로 리다이렉트
              GoRoute(
                path: RoutePaths.watch,
                redirect: (context, state) => RoutePaths.alerts,
              ),
            ],
          ),
        ],
      ),
      
      // Legacy: Benefits와 More는 루트 라우트로 유지 (Home에서 접근)
      GoRoute(
        path: RoutePaths.benefits,
        name: RoutePaths.benefits,
        builder: (context, state) => const BenefitsScreen(),
      ),
      GoRoute(
        path: RoutePaths.me,
        name: RoutePaths.me,
        builder: (context, state) => const MyScreen(),
        routes: [
          GoRoute(
            path: 'account',
            builder: (context, state) => const AccountManageScreen(),
          ),
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
          GoRoute(
            path: 'recommendation-history',
            builder: (context, state) => const RecommendationHistoryScreen(),
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
