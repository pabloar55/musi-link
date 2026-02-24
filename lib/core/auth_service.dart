import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:musi_link/core/user_service.dart';

/// Servicio de autenticación con Firebase Auth.
/// Soporta email+contraseña y Google Sign-In.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Usuario actual de Firebase
  User? get currentUser => _auth.currentUser;

  /// Stream de cambios en el estado de autenticación.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ---------------------------------------------------------------------------
  // Email + Contraseña
  // ---------------------------------------------------------------------------

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
        await UserService.instance.createUserProfile(
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
        await UserService.instance.updateLastLogin(user.uid);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ Error login email: ${e.code} - ${e.message}");
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Google Sign-In
  // ---------------------------------------------------------------------------

  /// Inicia sesión con Google.
  /// Si es la primera vez, crea el perfil en Firestore.
  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Usuario canceló

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final exists = await UserService.instance.userExists(user.uid);
        if (!exists) {
          await UserService.instance.createUserProfile(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? googleUser.displayName ?? '',
            photoUrl: user.photoURL ?? googleUser.photoUrl ?? '',
          );
        } else {
          await UserService.instance.updateLastLogin(user.uid);
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

  // ---------------------------------------------------------------------------
  // Cerrar sesión
  // ---------------------------------------------------------------------------

  /// Cierra sesión de Firebase y Google (si aplica).
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
