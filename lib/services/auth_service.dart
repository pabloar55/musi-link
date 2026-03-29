import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:musi_link/services/user_service.dart';

/// Servicio de autenticación con Firebase Auth.
/// Soporta email+contraseña y Google Sign-In.
class AuthService {
  AuthService(this._userService, {required FirebaseAuth auth, required GoogleSignIn googleSignIn})
      : _auth = auth,
        _googleSignIn = googleSignIn;

  final UserService _userService;
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  bool _googleInitialized = false;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await _googleSignIn.initialize();
    _googleInitialized = true;
  }

  /// Usuario actual de Firebase
  User? get currentUser => _auth.currentUser;

  /// Registra un nuevo usuario con email y contraseña.
  /// Crea también su perfil en Firestore.
  Future<User?> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await _userService.createUserProfile(
          uid: user.uid,
          email: email,
          displayName: displayName,
        );
      }
      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ Error registro email: ${e.code} - ${e.message}");
      rethrow;
    }
  }

  /// Inicia sesión con email y contraseña.
  /// Actualiza lastLogin en Firestore.
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        await _userService.updateLastLogin(user.uid);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ Error login email: ${e.code} - ${e.message}");
      rethrow;
    }
  }

  /// Inicia sesión con Google.
  /// Si es la primera vez, crea el perfil en Firestore.
  Future<User?> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();

      final googleUser = _googleSignIn.supportsAuthenticate()
          ? await _googleSignIn.authenticate()
          : await _googleSignIn.attemptLightweightAuthentication();

      if (googleUser == null) return null; // Usuario canceló

      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final exists = await _userService.userExists(user.uid);
        if (!exists) {
          await _userService.createUserProfile(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? googleUser.displayName ?? '',
          );
        } else {
          await _userService.updateLastLogin(user.uid);
        }
      }
      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ Error Google sign-in: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("❌ Error Google sign-in: $e");
      rethrow;
    }
  }

  /// Cierra sesión de Firebase y Google
  Future<void> signOut() async {
    await _ensureGoogleInitialized();
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
