import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:musi_link/core/spotify_service.dart';
import 'package:musi_link/core/firebase_options.dart';
import 'package:musi_link/screens/login_screen.dart';
import 'package:musi_link/screens/main_screen.dart';

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

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late Future<bool> _isLoggedInFuture;

  @override
  void initState() {
    super.initState();
    // Verifica si el usuario estaba logueado
    _isLoggedInFuture = SpotifyService.isUserLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.system,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1DB954),       
          onPrimary: Colors.black,          // Texto sobre verde
          secondary: Color(0xFF1ED760),     // Verde más claro para acentos
          onSecondary: Colors.black,
          surface: Color(0xFF121212),        // Fondo principal oscuro
          onSurface: Colors.white,          // Texto sobre fondo
          surfaceContainerHighest: Color(0xFF2A2A2A), // Botones inactivos, cards
          error: Color(0xFFCF6679),
          onError: Colors.black,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF181818),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF181818),
          indicatorColor: Color(0xFF1DB954),
        ),
      ),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1AA34A),       // Verde Spotify (más oscuro para light)
          onPrimary: Colors.white,          // Texto sobre verde
          secondary: Color(0xFF1DB954),     // Verde para acentos
          onSecondary: Colors.white,
          surface: Colors.white,            // Fondo principal
          onSurface: Color(0xFF121212),     // Texto sobre fondo
          surfaceContainerHighest: Color(0xFFE8E8E8), // Botones inactivos, cards
          error: Color(0xFFB00020),
          onError: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F9FA),
          foregroundColor: Color(0xFF121212),
          elevation: 0,
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFFF8F9FA),
          indicatorColor: Color(0xFF1AA34A),
        ),
      ),
      home: FutureBuilder<bool>(
        future: _isLoggedInFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData && snapshot.data == true) {
            return const MainScreen();
          } else {
            return LoginScreen();
          }
        },
      ),
    );
  }
}
