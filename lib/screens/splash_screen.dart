import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:musi_link/providers/firebase_providers.dart';
import 'package:musi_link/providers/service_providers.dart';
import 'package:musi_link/router/go_router_provider.dart';
import 'package:musi_link/screens/onboarding_screen.dart';
import 'package:musi_link/utils/error_reporter.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _animController.forward();
    _initialize();
  }

  Future<void> _initialize() async {
    final minSplash = Future.delayed(const Duration(milliseconds: 500));

    unawaited(FirebaseAnalytics.instance.logEvent(name: 'app_open'));

    try {
      // Cold-start: capturar notificación que abrió la app
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        ref
            .read(pendingNotificationProvider.notifier)
            .setValue(initialMessage.data);
      }

      // Ejecutar checks en paralelo con el tiempo mínimo de splash
      final spotifyFuture = ref.read(spotifyServiceProvider).tryRestoreSession();
      final prefsFuture = SharedPreferences.getInstance();

      final spotifyConnected = await spotifyFuture;
      final prefs = await prefsFuture;
      final onboardingDone =
          prefs.getBool(OnboardingScreen.onboardingCompletedKey) ?? false;

      // Si Spotify está conectado, sincronizar perfil musical en background
      if (spotifyConnected && mounted) {
        final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
        if (uid != null) {
          ref.read(musicProfileServiceProvider).syncMusicProfile(uid).ignore();
        }
      }

      // Esperar duración mínima de splash si aún no ha pasado
      await minSplash;

      if (mounted) {
        ref.read(appRouterNotifierProvider).setInitialized(
          spotifyConnected: spotifyConnected,
          onboardingDone: onboardingDone,
        );
      }
    } catch (e, st) {
      reportError(e, st).ignore();
      await minSplash;
      if (mounted) {
        ref.read(appRouterNotifierProvider).setInitialized(
          spotifyConnected: false,
          onboardingDone: false,
        );
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),

            // Logo with fade + scale animation
            FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 220,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Circular progress indicator
            FadeTransition(
              opacity: _fadeAnim,
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                ),
              ),
            ),

            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}
