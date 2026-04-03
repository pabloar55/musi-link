import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Notifier que dispara los redirects de GoRouter cuando cambia
/// el estado de autenticación o cuando la app termina la inicialización.
class AppRouterNotifier extends ChangeNotifier {
  final FirebaseAuth _auth;

  AppRouterNotifier({required FirebaseAuth auth}) : _auth = auth;

  StreamSubscription<User?>? _sub;
  bool _initialized = false;
  bool _spotifyConnected = false;
  bool _onboardingDone = false;

  bool get isInitialized => _initialized;
  bool get isLoggedIn => _auth.currentUser != null;
  bool get spotifyConnected => _spotifyConnected;
  bool get onboardingDone => _onboardingDone;

  /// Llamar desde el SplashScreen una vez que la app ha terminado de
  /// inicializarse. Inicia la escucha de authStateChanges y dispara el
  /// primer redirect.
  void setInitialized({
    required bool spotifyConnected,
    required bool onboardingDone,
  }) {
    _initialized = true;
    _spotifyConnected = spotifyConnected;
    _onboardingDone = onboardingDone;
    _sub = _auth.authStateChanges().listen((user) {
      if (user == null) {
        _spotifyConnected = false;
        _onboardingDone = false;
      }
      notifyListeners();
    });
  }

  /// Llamar después de conectar Spotify con éxito para que el router
  /// re-evalúe y navegue automáticamente al siguiente paso.
  void setSpotifyConnected({required bool onboardingDone}) {
    _spotifyConnected = true;
    _onboardingDone = onboardingDone;
    notifyListeners();
  }

  /// Llamar al completar el onboarding para que el router re-evalúe
  /// y navegue automáticamente a MainScreen.
  void setOnboardingDone() {
    _onboardingDone = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
