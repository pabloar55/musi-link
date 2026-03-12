import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/firebase_options.dart';
import 'package:musi_link/theme/app_theme.dart';
import 'package:musi_link/theme/theme_mode_controller.dart';
import 'package:musi_link/screens/auth_screen.dart';
import 'package:musi_link/screens/spotify_connect_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  //FirebaseCrashlytics.instance.crash();
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  analytics.logEvent(name: 'app_open', parameters: null);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeModeController.instance,
      builder: (context, themeMode, _) => MaterialApp(
        themeMode: themeMode,
        darkTheme: AppTheme.darkTheme,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Si hay usuario de Firebase
            if (snapshot.hasData && snapshot.data != null) {
              return const SpotifyConnectScreen();
            }

            // Si no hay sesión de Firebase
            return const AuthScreen();
          },
        ),
      ),
    );
  }
}
