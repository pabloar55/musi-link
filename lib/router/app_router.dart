import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:musi_link/models/app_user.dart';
import 'package:musi_link/screens/auth_screen.dart';
import 'package:musi_link/screens/chat_screen.dart';
import 'package:musi_link/screens/main_screen.dart';
import 'package:musi_link/screens/onboarding_screen.dart';
import 'package:musi_link/screens/splash_screen.dart';
import 'package:musi_link/screens/spotify_connect_screen.dart';
import 'package:musi_link/screens/user_profile_screen.dart';
import 'package:musi_link/screens/user_search_screen.dart';

/// Notifier que dispara los redirects de GoRouter cuando cambia
/// el estado de autenticación o cuando la app termina la inicialización.
class AppRouterNotifier extends ChangeNotifier {
  StreamSubscription<User?>? _sub;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Llamar después de inicializar Firebase en el SplashScreen.
  /// Inicia la escucha de authStateChanges y dispara el primer redirect.
  void setInitialized() {
    _initialized = true;
    _sub = FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

class AppRouter {
  AppRouter._();

  static final notifier = AppRouterNotifier();

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: _redirect,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/spotify-connect',
        builder: (context, state) => const SpotifyConnectScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) =>
            UserProfileScreen(user: state.extra as AppUser),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) {
          final params = state.extra as Map<String, String>;
          return ChatScreen(
            chatId: params['chatId']!,
            otherUserName: params['otherUserName']!,
            otherUserId: params['otherUserId']!,
          );
        },
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const UserSearchScreen(),
      ),
    ],
  );

  static String? _redirect(BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;

    // Mientras no se haya inicializado Firebase, forzar splash
    if (!notifier.isInitialized) {
      return location == '/splash' ? null : '/splash';
    }

    final isLoggedIn = FirebaseAuth.instance.currentUser != null;

    // Si no está logueado, forzar pantalla de auth
    if (!isLoggedIn) {
      return location == '/auth' ? null : '/auth';
    }

    // Si está logueado y sigue en splash o auth, ir a conectar Spotify
    if (location == '/splash' || location == '/auth') {
      return '/spotify-connect';
    }

    return null;
  }
}
