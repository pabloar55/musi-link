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
  bool _artistsSelected = false;
  bool _onboardingDone = false;

  bool get isInitialized => _initialized;
  bool get isLoggedIn => _auth.currentUser != null;
  bool get artistsSelected => _artistsSelected;
  bool get onboardingDone => _onboardingDone;

  Future<({bool artistsSelected, bool onboardingDone})> Function(
    String uid,
  )?
  _fetchUserState;

  /// Llamar desde el SplashScreen una vez que la app ha terminado de
  /// inicializarse. Inicia la escucha de authStateChanges y dispara el
  /// primer redirect.
  ///
  /// [fetchUserState] es un callback que re-consulta Firestore cuando el
  /// usuario hace login (necesario tras reinstalar la app, donde
  /// SharedPreferences se borra pero los datos en Firestore persisten).
  void setInitialized({
    required bool artistsSelected,
    required bool onboardingDone,
    Future<({bool artistsSelected, bool onboardingDone})> Function(
      String uid,
    )? fetchUserState,
  }) {
    _initialized = true;
    _artistsSelected = artistsSelected;
    _onboardingDone = onboardingDone;
    _fetchUserState = fetchUserState;
    _sub = _auth.authStateChanges().listen((user) async {
      if (user == null) {
        _artistsSelected = false;
        _onboardingDone = false;
        notifyListeners();
      } else if (_fetchUserState != null && !_artistsSelected) {
        // Re-consultar Firestore al hacer login para evitar que usuarios
        // existentes (que reinstalaron la app) pasen por el flujo de setup.
        try {
          final state = await _fetchUserState!(user.uid);
          _artistsSelected = state.artistsSelected;
          _onboardingDone = state.onboardingDone;
        } catch (_) {}
        notifyListeners();
      } else {
        notifyListeners();
      }
    });
  }

  /// Llamar después de seleccionar artistas para que el router re-evalúe
  /// y navegue automáticamente al siguiente paso.
  void setArtistsSelected({required bool onboardingDone}) {
    _artistsSelected = true;
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

/// Lógica de redirect centralizada y testeable de forma independiente.
/// Devuelve la ruta destino o null si no hay que redirigir.
String? appRedirect(AppRouterNotifier notifier, String location) {
  if (!notifier.isInitialized) {
    return location == '/splash' ? null : '/splash';
  }
  if (!notifier.isLoggedIn) {
    return location == '/auth' ? null : '/auth';
  }
  if (!notifier.artistsSelected) {
    return location == '/artist-select' ? null : '/artist-select';
  }
  if (!notifier.onboardingDone) {
    return location == '/onboarding' ? null : '/onboarding';
  }
  // Usuario listo: evitar que se quede en pantallas de setup
  if (location == '/splash' ||
      location == '/auth' ||
      location == '/artist-select' ||
      location == '/onboarding') {
    return '/';
  }
  return null;
}
