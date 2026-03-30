import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:musi_link/models/app_user.dart';
import 'package:musi_link/models/track.dart';
import 'package:musi_link/utils/firestore_collections.dart';

/// Servicio para gestionar perfiles de usuario en Firestore.
class UserService {
  UserService({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;
  late final CollectionReference<Map<String, dynamic>> _usersRef =
      _firestore.collection(FirestoreCollections.users);

  /// Crea un perfil de usuario nuevo en Firestore.
  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    try {
      final now = DateTime.now();
      final user = AppUser(
        uid: uid,
        email: email,
        displayName: displayName,
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

  /// Vincula datos de Spotify (id y foto de perfil) al usuario.
  Future<void> linkSpotifyProfile(
    String uid, {
    required String spotifyId,
    required String photoUrl,
  }) async {
    try {
      final updates = <String, dynamic>{
        'spotifyId': spotifyId,
      };
      if (photoUrl.trim().isNotEmpty) {
        updates['photoUrl'] = photoUrl;
      }

      await _usersRef.doc(uid).update(updates);
    } catch (e) {
      debugPrint("❌ Error al vincular perfil de Spotify: $e");
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
      if (displayName != null) {
        updates['displayName'] = displayName;
        updates['displayNameLower'] = displayName.toLowerCase();
      }
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      if (updates.isNotEmpty) {
        await _usersRef.doc(uid).update(updates);
      }
    } catch (e) {
      debugPrint("❌ Error al actualizar perfil: $e");
    }
  }

  /// Busca usuarios por nombre
  /// Excluye al usuario con [excludeUid] de los resultados. (el que hace la búsqueda)
  Future<List<AppUser>> searchUsers(String query,
      {String? excludeUid}) async {
    try {
      if (query.trim().isEmpty) return [];
      final lowerQuery = query.trim().toLowerCase();
      final snapshot = await _usersRef
          .where('displayNameLower',
              isGreaterThanOrEqualTo: lowerQuery)
          .where('displayNameLower',
              isLessThanOrEqualTo: '$lowerQuery\uf8ff')
          .limit(20)
          .get();
      return snapshot.docs
          .map(AppUser.fromFirestore)
          .where((u) => u.uid != excludeUid)
          .toList();
    } catch (e) {
      debugPrint("❌ Error al buscar usuarios: $e");
      return [];
    }
  }

  /// Establece la canción del día del usuario.
  Future<void> setDailySong(String uid, Track track) async {
    try {
      await _usersRef.doc(uid).update({
        'dailySong': track.toMap(),
        'dailySongUpdatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint("❌ Error al establecer canción del día: $e");
    }
  }

  /// Actualiza la canción que el usuario está escuchando ahora.
  Future<void> updateNowPlaying(String uid, Track? track) async {
    try {
      final updates = <String, dynamic>{
        'nowPlaying': track?.toMap(),
        'nowPlayingUpdatedAt': track != null ? Timestamp.fromDate(DateTime.now()) : null,
      };
      await _usersRef.doc(uid).update(updates);
    } catch (e) {
      debugPrint("❌ Error al actualizar nowPlaying: $e");
    }
  }

  /// Obtiene los usuarios correspondientes a una lista de UIDs.
  Future<List<AppUser>> getUsersByIds(List<String> uids) async {
    if (uids.isEmpty) return [];
    try {
      final List<AppUser> users = [];
      // Firestore whereIn soporta máximo 10 elementos por consulta
      for (var i = 0; i < uids.length; i += 10) {
        final chunk = uids.sublist(i, i + 10 > uids.length ? uids.length : i + 10);
        final snapshot = await _usersRef
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        users.addAll(snapshot.docs.map(AppUser.fromFirestore));
      }
      return users;
    } catch (e) {
      debugPrint("❌ Error al obtener usuarios por IDs: $e");
      return [];
    }
  }
}
