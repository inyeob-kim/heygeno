import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'router/app_router.dart';
import '../design_system/theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Pet Food App',
      // 스타일 Theme 적용
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      // i18n 설정 (영어 기본)
      locale: const Locale('en', 'US'),
      supportedLocales: const [
        Locale('en', 'US'), // 영어 (기본)
        Locale('ko', 'KR'), // 한국어
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
