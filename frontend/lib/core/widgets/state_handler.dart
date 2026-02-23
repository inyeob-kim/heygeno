import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/app_spacing.dart';
import 'loading.dart';
import 'empty_state.dart';
import '../../ui/widgets/app_buttons.dart';
import 'package:pet_food_app/l10n/app_localizations.dart';

/// 공통 상태 처리 위젯 (로딩/에러/빈 상태/정상 상태)
/// 
/// 사용 예시:
/// ```dart
/// StateHandler(
///   isLoading: state.isLoading,
///   error: state.error,
///   isEmpty: state.products.isEmpty,
///   onRetry: () => ref.read(controllerProvider.notifier).load(),
///   emptyWidget: EmptyStateWidget(
///     title: '상품이 없습니다',
///     description: '새로운 상품을 추가해보세요',
///   ),
///   child: YourContentWidget(),
/// )
/// ```
class StateHandler extends StatelessWidget {
  /// 로딩 중 여부
  final bool isLoading;
  
  /// 에러 메시지 (null이면 에러 없음)
  final String? error;
  
  /// 빈 상태 여부 (데이터가 없을 때)
  final bool isEmpty;
  
  /// 정상 상태일 때 표시할 위젯
  final Widget child;
  
  /// 재시도 콜백 (에러 발생 시)
  final VoidCallback? onRetry;
  
  /// 빈 상태 위젯 (isEmpty가 true일 때 표시, null이면 기본 EmptyStateWidget 사용)
  final Widget? emptyWidget;
  
  /// 에러 발생 시 표시할 커스텀 위젯 (null이면 기본 에러 위젯 사용)
  final Widget? errorWidget;
  
  /// 로딩 중 표시할 위젯 (null이면 기본 LoadingWidget 사용)
  final Widget? loadingWidget;

  const StateHandler({
    super.key,
    required this.isLoading,
    this.error,
    this.isEmpty = false,
    required this.child,
    this.onRetry,
    this.emptyWidget,
    this.errorWidget,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    // 1. 로딩 중
    if (isLoading) {
      return loadingWidget ?? const LoadingWidget();
    }

    // 2. 에러 발생
    if (error != null) {
      return errorWidget ?? _buildErrorWidget(context);
    }

    // 3. 빈 상태
    if (isEmpty) {
      return emptyWidget ?? EmptyStateWidget(
        title: AppLocalizations.of(context)!.empty_noData,
      );
    }

    // 4. 정상 상태
    return child;
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.dangerRed.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              error!,
              style: AppTypography.body.copyWith(
                color: AppColors.dangerRed,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppPrimaryButton(
                text: AppLocalizations.of(context)!.action_tryAgain,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 간단한 상태 처리 위젯 (로딩/에러만 처리)
/// 
/// 사용 예시:
/// ```dart
/// SimpleStateHandler(
///   isLoading: state.isLoading,
///   error: state.error,
///   onRetry: () => ref.read(controllerProvider.notifier).load(),
///   child: YourContentWidget(),
/// )
/// ```
class SimpleStateHandler extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final Widget child;
  final VoidCallback? onRetry;

  const SimpleStateHandler({
    super.key,
    required this.isLoading,
    this.error,
    required this.child,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return StateHandler(
      isLoading: isLoading,
      error: error,
      isEmpty: false,
      onRetry: onRetry,
      child: child,
    );
  }
}
