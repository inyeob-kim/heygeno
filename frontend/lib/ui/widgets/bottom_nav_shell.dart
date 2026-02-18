import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import 'app_bottom_tab_bar.dart';
import '../../core/providers/modal_visibility_provider.dart';

/// 하단 네비게이션 셸 위젯
class BottomNavShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNavShell({
    super.key,
    required this.navigationShell,
  });

  /// 탭 인덱스를 브랜치 인덱스로 매핑
  /// BottomNavigationBar: [0: 홈, 1: 관심, 2: 검색, 3: 혜택, 4: 더보기]
  /// Branches: [0: 홈, 1: 관심, 2: 마켓, 3: 혜택, 4: 더보기]
  /// 탭 인덱스와 브랜치 인덱스가 1:1로 매핑됨
  static const int _branchCount = 5; // 브랜치 개수: 홈, 관심, 마켓, 혜택, 더보기
  
  void _onTabTapped(int tabIndex, BuildContext context) {
    // 범위 체크
    if (tabIndex < 0 || tabIndex >= _branchCount) {
      debugPrint('⚠️ 잘못된 탭 인덱스: $tabIndex (브랜치 개수: $_branchCount)');
      return;
    }
    
    // 탭 인덱스와 브랜치 인덱스가 동일하므로 직접 사용
    try {
      navigationShell.goBranch(
        tabIndex,
        initialLocation: tabIndex == navigationShell.currentIndex,
      );
    } catch (e) {
      debugPrint('⚠️ goBranch 에러: $e (탭 인덱스: $tabIndex)');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 현재 브랜치 인덱스를 탭 인덱스로 변환 (안전하게 범위 체크)
    final currentBranchIndex = navigationShell.currentIndex;
    final safeTabIndex = (currentBranchIndex >= 0 && currentBranchIndex < _branchCount)
        ? currentBranchIndex
        : 0; // 기본값은 0 (홈)
    
    // 모달 표시 여부 확인 (모달이 표시되면 바텀탭 숨기기)
    final isModalVisible = ref.watch(modalVisibilityProvider);
    
    return PopScope(
      canPop: false, // 바텀 탭에서는 뒤로가기로 탭 간 이동 불가
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        
        // 현재 브랜치의 Navigator가 pop 가능하면 (서브 페이지가 있으면) pop
        // navigationShell의 현재 브랜치 Navigator를 확인
        final navigator = Navigator.maybeOf(context);
        if (navigator != null && navigator.canPop()) {
          navigator.pop();
        }
        // 루트에 있으면 아무것도 하지 않음 (앱 종료는 시스템이 처리)
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: navigationShell,
        bottomNavigationBar: isModalVisible
            ? null // 모달이 표시되면 바텀탭 숨기기
            : AppBottomTabBar(
                currentIndex: safeTabIndex,
                onTap: (index) => _onTabTapped(index, context),
              ),
      ),
    );
  }
}
