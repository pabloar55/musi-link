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

  bool get isInitialized => _initialized;

  /// Llamar desde el SplashScreen una vez que la app ha terminado de
  /// inicializarse (Firebase ya está listo desde main.dart).
  /// Inicia la escucha de authStateChanges y dispara el primer redirect.
  void setInitialized() {
    _initialized = true;
    _sub = _auth.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
