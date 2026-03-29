import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musi_link/models/app_user.dart';
import 'package:musi_link/router/app_router.dart';
import 'package:musi_link/screens/auth_screen.dart';
import 'package:musi_link/screens/chat_screen.dart';
import 'package:musi_link/screens/main_screen.dart';
import 'package:musi_link/screens/onboarding_screen.dart';
import 'package:musi_link/screens/splash_screen.dart';
import 'package:musi_link/screens/spotify_connect_screen.dart';
import 'package:musi_link/screens/user_profile_screen.dart';
import 'package:musi_link/screens/user_search_screen.dart';
import 'package:musi_link/services/auth_service.dart';
import 'package:musi_link/services/chat_service.dart';
import 'package:musi_link/services/friend_service.dart';
import 'package:musi_link/services/music_profile_service.dart';
import 'package:musi_link/services/spotify_service.dart';
import 'package:musi_link/services/spotify_stats_service.dart';
import 'package:musi_link/services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// ── Providers Globales de Firebase ──────────────────────────────

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn.instance;
});

// ── Servicios sin dependencias ──────────────────────────────────

final userServiceProvider = Provider<UserService>((ref) {
  return UserService(firestore: ref.watch(firebaseFirestoreProvider));
});

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(
    firestore: ref.watch(firebaseFirestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
});

final friendServiceProvider = Provider<FriendService>((ref) {
  return FriendService(
    firestore: ref.watch(firebaseFirestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
});

// ── Servicios con dependencias ──────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(userServiceProvider),
    auth: ref.watch(firebaseAuthProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  );
});

final Provider<SpotifyService> spotifyServiceProvider =
    Provider<SpotifyService>((ref) {
  return SpotifyService(
    userService: ref.watch(userServiceProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
});

final Provider<MusicProfileService> musicProfileServiceProvider =
    Provider<MusicProfileService>((ref) {
  return MusicProfileService(
    ref.watch(spotifyStatsProvider),
    firestore: ref.watch(firebaseFirestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
});

final Provider<SpotifyGetStats> spotifyStatsProvider =
    Provider<SpotifyGetStats>((ref) {
  return SpotifyGetStats(ref.watch(spotifyServiceProvider));
});

// ── Theme ───────────────────────────────────────────────────────

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  bool get isDark {
    if (state == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return state == ThemeMode.dark;
  }

  void toggleDarkLight() {
    state = isDark ? ThemeMode.light : ThemeMode.dark;
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// Provider derivado que indica si el tema actual es oscuro.
/// Usar `ref.watch(isDarkProvider)` en lugar de acceder al notifier.
final isDarkProvider = Provider<bool>((ref) {
  final mode = ref.watch(themeModeProvider);
  if (mode == ThemeMode.system) {
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }
  return mode == ThemeMode.dark;
});

// ── Router ──────────────────────────────────────────────────────

final appRouterNotifierProvider = Provider<AppRouterNotifier>((ref) {
  final notifier = AppRouterNotifier();
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.read(appRouterNotifierProvider);
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final location = state.matchedLocation;

      if (!notifier.isInitialized) {
        return location == '/splash' ? null : '/splash';
      }

      final isLoggedIn = ref.read(firebaseAuthProvider).currentUser != null;

      if (!isLoggedIn) {
        return location == '/auth' ? null : '/auth';
      }

      if (location == '/splash' || location == '/auth') {
        return '/spotify-connect';
      }

      return null;
    },
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
});
