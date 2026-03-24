import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
