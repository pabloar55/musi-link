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
  bool _usernameSet = false;
  bool _artistsSelected = false;
  bool _onboardingDone = false;
  bool _photoSetupDone = false;

  bool get isInitialized => _initialized;
  bool get isLoggedIn => _auth.currentUser != null;
  bool get usernameSet => _usernameSet;
  bool get artistsSelected => _artistsSelected;
  bool get onboardingDone => _onboardingDone;
  bool get photoSetupDone => _photoSetupDone;

  Future<
      ({
        bool usernameSet,
        bool artistsSelected,
        bool onboardingDone,
        bool photoSetupDone,
      })>
      Function(String uid)? _fetchUserState;

  /// Llamar desde el SplashScreen una vez que la app ha terminado de
  /// inicializarse. Inicia la escucha de authStateChanges y dispara el
  /// primer redirect.
  void setInitialized({
    required bool usernameSet,
    required bool artistsSelected,
    required bool onboardingDone,
    required bool photoSetupDone,
    Future<
            ({
              bool usernameSet,
              bool artistsSelected,
              bool onboardingDone,
              bool photoSetupDone,
            })>
        Function(String uid)? fetchUserState,
  }) {
    _initialized = true;
    _usernameSet = usernameSet;
    _artistsSelected = artistsSelected;
    _onboardingDone = onboardingDone;
    _photoSetupDone = photoSetupDone;
    _fetchUserState = fetchUserState;
    _sub = _auth.authStateChanges().listen((user) async {
      if (user == null) {
        _usernameSet = false;
        _artistsSelected = false;
        _onboardingDone = false;
        _photoSetupDone = false;
        notifyListeners();
      } else if (_fetchUserState != null && !_usernameSet) {
        // Re-consultar Firestore al hacer login para evitar que usuarios
        // existentes (que reinstalaron la app) pasen por el flujo de setup.
        try {
          final state = await _fetchUserState!(user.uid);
          _usernameSet = state.usernameSet;
          _artistsSelected = state.artistsSelected;
          _onboardingDone = state.onboardingDone;
          _photoSetupDone = state.photoSetupDone;
        } catch (_) {}
        notifyListeners();
      } else {
        notifyListeners();
      }
    });
  }

  /// Llamar desde UsernameSetupScreen tras guardar el username.
  void setUsernameSet() {
    _usernameSet = true;
    notifyListeners();
  }

  /// Llamar después de seleccionar artistas para que el router re-evalúe
  /// y navegue automáticamente al siguiente paso.
  void setArtistsSelected() {
    _artistsSelected = true;
    notifyListeners();
  }

  /// Llamar al completar el onboarding para que el router re-evalúe
  /// y navegue automáticamente a la pantalla de foto de perfil.
  void setOnboardingDone() {
    _onboardingDone = true;
    notifyListeners();
  }

  /// Llamar al completar (o saltar) la configuración de foto de perfil.
  void setPhotoSetupDone() {
    _photoSetupDone = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// Lógica de redirect centralizada y testeable de forma independiente.
/// Devuelve la ruta destino o null si no hay que redirigir.
String? appRedirect(AppRouterNotifier notifier, String location) {
  if (!notifier.isInitialized) {
    return location == '/splash' ? null : '/splash';
  }
  if (!notifier.isLoggedIn) {
    return location == '/auth' ? null : '/auth';
  }
  if (!notifier.onboardingDone) {
    return location == '/onboarding' ? null : '/onboarding';
  }
  if (!notifier.usernameSet) {
    return location == '/username-setup' ? null : '/username-setup';
  }
  if (!notifier.photoSetupDone) {
    return location == '/photo-setup' ? null : '/photo-setup';
  }
  if (!notifier.artistsSelected) {
    return location == '/artist-select' ? null : '/artist-select';
  }
  // Usuario listo: evitar que se quede en pantallas de setup
  if (location == '/splash' ||
      location == '/auth' ||
      location == '/onboarding' ||
      location == '/username-setup' ||
      location == '/photo-setup' ||
      location == '/artist-select') {
    return '/';
  }
  return null;
}
