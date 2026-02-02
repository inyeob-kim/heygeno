import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// 공통 Scaffold 위젯 (DESIGN_GUIDE.md 스타일)
class AppScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      appBar: appBar,
      body: SafeArea(
        top: false, // AppHeader가 SafeArea를 처리
        child: padding != null
            ? Padding(
                padding: padding!,
                child: body,
              )
            : body,
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}
