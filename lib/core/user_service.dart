import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:musi_link/core/models/app_user.dart';

/// Servicio para gestionar perfiles de usuario en Firestore.
class UserService {
  UserService._();
  static final UserService instance = UserService._();

  final CollectionReference<Map<String, dynamic>> _usersRef =
      FirebaseFirestore.instance.collection('users');

  /// Crea un perfil de usuario nuevo en Firestore.
  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String displayName,
    String photoUrl = '',
  }) async {
    try {
      final now = DateTime.now();
      final user = AppUser(
        uid: uid,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        createdAt: now,
        lastLogin: now,
      );
      await _usersRef.doc(uid).set(user.toFirestore());
    } catch (e) {
      debugPrint("❌ Error al crear perfil: $e");
      rethrow;
    }
  }

  /// Obtiene el perfil de un usuario por su UID.
  Future<AppUser?> getUser(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc);
    } catch (e) {
      debugPrint("❌ Error al obtener usuario: $e");
      return null;
    }
  }

  /// Comprueba si un usuario existe en Firestore.
  Future<bool> userExists(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      return doc.exists;
    } catch (e) {
      debugPrint("❌ Error al verificar usuario: $e");
      return false;
    }
  }

  /// Actualiza la fecha de último login.
  Future<void> updateLastLogin(String uid) async {
    try {
      await _usersRef.doc(uid).update({
        'lastLogin': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint("❌ Error al actualizar lastLogin: $e");
    }
  }

  /// Vincula el Spotify ID al perfil del usuario.
  Future<void> linkSpotifyId(String uid, String spotifyId) async {
    try {
      await _usersRef.doc(uid).update({'spotifyId': spotifyId});
    } catch (e) {
      debugPrint("❌ Error al vincular Spotify ID: $e");
    }
  }

  /// Actualiza campos del perfil de usuario.
  Future<void> updateProfile(
    String uid, {
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      if (updates.isNotEmpty) {
        await _usersRef.doc(uid).update(updates);
      }
    } catch (e) {
      debugPrint("❌ Error al actualizar perfil: $e");
    }
  }
}
