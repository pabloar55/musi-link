import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musi_link/models/app_user.dart';
import 'package:musi_link/providers/firebase_providers.dart';
import 'package:musi_link/router/app_router.dart';
import 'package:musi_link/screens/account_settings_screen.dart';
import 'package:musi_link/screens/auth_screen.dart';
import 'package:musi_link/screens/privacy_policy_screen.dart';
import 'package:musi_link/screens/chat_screen.dart';
import 'package:musi_link/screens/main_screen.dart';
import 'package:musi_link/screens/onboarding_screen.dart';
import 'package:musi_link/screens/splash_screen.dart';
import 'package:musi_link/screens/spotify_connect_screen.dart';
import 'package:musi_link/screens/user_profile_screen.dart';
import 'package:musi_link/screens/user_search_screen.dart';

// ── Router ──────────────────────────────────────────────────────

final appRouterNotifierProvider = Provider<AppRouterNotifier>((ref) {
  final notifier = AppRouterNotifier(auth: ref.watch(firebaseAuthProvider));
  ref.onDispose(notifier.dispose);
  return notifier;
});

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.read(appRouterNotifierProvider);
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) =>
        appRedirect(notifier, state.matchedLocation),
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
        redirect: (context, state) {
          if (state.extra is! AppUser) return '/';
          return null;
        },
        builder: (context, state) =>
            UserProfileScreen(user: state.extra! as AppUser),
      ),
      GoRoute(
        path: '/chat',
        redirect: (context, state) {
          final q = state.uri.queryParameters;
          if (q['chatId'] == null ||
              q['otherUserName'] == null ||
              q['otherUserId'] == null) {
            return '/';
          }
          return null;
        },
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return ChatScreen(
            chatId: q['chatId']!,
            otherUserName: q['otherUserName']!,
            otherUserId: q['otherUserId']!,
          );
        },
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const UserSearchScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const AccountSettingsScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
    ],
  );
});
