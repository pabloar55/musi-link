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
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark, // Define que la app es oscura
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1DB954),
          
          surface: Color(0xFF050505),
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface: Colors.white,
        ),
        // Estilo global de las Cards
        cardTheme: CardThemeData(
          color: const Color(0xFF181818),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1AA34A),
          secondary: Color(0xFFBA55D3),
          
          surface: Colors.white,
          onPrimary: Colors.white,
          onSurface: Color(0xFF121212),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F9FA),
          foregroundColor: Color(0xFF121212),
          elevation: 0,
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
