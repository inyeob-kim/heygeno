import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../domain/services/onboarding_service.dart';
import '../../../../app/router/route_paths.dart';

/// 앱 시작 시 첫 번째로 표시되는 헤이제노 스플래시 스크린 (3초)
/// 온보딩 완료 여부를 확인하여 적절한 화면으로 이동
class InitialSplashScreen extends ConsumerStatefulWidget {
  const InitialSplashScreen({super.key});

  @override
  ConsumerState<InitialSplashScreen> createState() => _InitialSplashScreenState();
}

class _InitialSplashScreenState extends ConsumerState<InitialSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // 애니메이션 컨트롤러
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // 페이드 인 애니메이션
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    // 스케일 애니메이션
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    // 애니메이션 시작
    _controller.forward();

    // 3초 후 온보딩 완료 여부 확인 및 이동
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    // 최소 3초 대기
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;

    // 온보딩 서비스를 통해 완료 여부 확인
    final onboardingService = ref.read(onboardingServiceProvider);
    final isCompleted = await onboardingService.isOnboardingCompleted();

    if (!mounted) return;

    // 온보딩 완료 → 홈 화면
    // 온보딩 미완료 → 온보딩 플로우
    if (isCompleted) {
      context.go(RoutePaths.home);
    } else {
      context.go(RoutePaths.onboarding);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 헤이제노 로고 이미지
                  Image.asset(
                    'assets/images/logo/heygeno-logo.png',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // 이미지가 없을 경우 플레이스홀더
                      return Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.pets,
                          size: 80,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
