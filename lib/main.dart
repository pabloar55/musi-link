import 'package:flutter/material.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/theme/app_theme.dart';
import 'package:musi_link/theme/theme_mode_controller.dart';
import 'package:musi_link/router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeModeController.instance,
      builder: (context, themeMode, _) => MaterialApp.router(
        themeMode: themeMode,
        darkTheme: AppTheme.darkTheme,
        theme: AppTheme.lightTheme,
        themeAnimationDuration: const Duration(milliseconds: 200),
        themeAnimationCurve: Curves.easeInOut,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: AppRouter.router,
      ),
    );
  }
}

