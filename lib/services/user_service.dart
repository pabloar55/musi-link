import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:musi_link/utils/error_reporter.dart';
import 'package:musi_link/models/app_user.dart';
import 'package:musi_link/models/track.dart';
import 'package:musi_link/utils/firestore_collections.dart';

/// Excepción lanzada cuando se intenta vincular un Spotify ID
/// que ya está asociado a otra cuenta de usuario.
class SpotifyAlreadyLinkedException implements Exception {
  const SpotifyAlreadyLinkedException();
}

/// Servicio para gestionar perfiles de usuario en Firestore.
class UserService {
  UserService({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;
  late final CollectionReference<Map<String, dynamic>> _usersRef =
      _firestore.collection(FirestoreCollections.users);

  Timer? _searchDebounce;
  Completer<List<AppUser>>? _pendingSearch;

  static const _userCacheTtl = Duration(minutes: 10);
  final Map<String, ({AppUser user, DateTime cachedAt})> _userCache = {};

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
    } catch (e, stack) {
      await reportError(e, stack);
      rethrow;
    }
  }

  /// Obtiene el perfil de un usuario por su UID.
  /// Resultado cacheado en memoria por [_userCacheTtl] para evitar reads
  /// repetidas desde discovery, chats y amigos.
  Future<AppUser?> getUser(String uid) async {
    final cached = _userCache[uid];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) < _userCacheTtl) {
      return cached.user;
    }
    try {
      final doc = await _usersRef.doc(uid).get();
      if (!doc.exists) return null;
      final user = AppUser.fromFirestore(doc);
      if (user != null) {
        _userCache[uid] = (user: user, cachedAt: DateTime.now());
      }
      return user;
    } catch (e, stack) {
      await reportError(e, stack);
      rethrow;
    }
  }

  /// Comprueba si un usuario existe en Firestore.
  Future<bool> userExists(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      return doc.exists;
    } catch (e, stack) {
      await reportError(e, stack);
      rethrow;
    }
  }

  /// Actualiza la fecha de último login.
  Future<void> updateLastLogin(String uid) async {
    try {
      await _usersRef.doc(uid).update({
        'lastLogin': Timestamp.fromDate(DateTime.now()),
      });
      _userCache.remove(uid);
    } catch (e, stack) {
      await reportError(e, stack);
    }
  }

  /// Vincula datos de Spotify (id y foto de perfil) al usuario.
  /// Lanza [SpotifyAlreadyLinkedException] si el [spotifyId] ya está
  /// vinculado a una cuenta diferente.
  Future<void> linkSpotifyProfile(
    String uid, {
    required String spotifyId,
    required String photoUrl,
  }) async {
    if (spotifyId.isNotEmpty) {
      final existing = await _usersRef
          .where('spotifyId', isEqualTo: spotifyId)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty && existing.docs.first.id != uid) {
        throw const SpotifyAlreadyLinkedException();
      }
    }

    try {
      final updates = <String, dynamic>{
        'spotifyId': spotifyId,
      };
      if (photoUrl.trim().isNotEmpty) {
        updates['photoUrl'] = photoUrl;
      }

      await _usersRef.doc(uid).update(updates);
      _userCache.remove(uid);
    } catch (e, stack) {
      if (e is SpotifyAlreadyLinkedException) rethrow;
      await reportError(e, stack);
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
        _userCache.remove(uid);
      }
    } catch (e, stack) {
      await reportError(e, stack);
      rethrow;
    }
  }

  /// Busca usuarios por nombre con debounce interno de 300 ms.
  /// Excluye al usuario con [excludeUid] de los resultados. (el que hace la búsqueda)
  /// Si llega una nueva llamada antes de que expire el timer, la anterior
  /// se resuelve con [] (fue superada) y el timer se reinicia.
  Future<List<AppUser>> searchUsers(String query,
      {String? excludeUid}) async {
    _searchDebounce?.cancel();

    final pending = _pendingSearch;
    if (pending != null && !pending.isCompleted) {
      pending.complete([]);
    }

    if (query.trim().isEmpty) return [];

    final completer = Completer<List<AppUser>>();
    _pendingSearch = completer;

    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final lowerQuery = query.trim().toLowerCase();
        final snapshot = await _usersRef
            .where('displayNameLower',
                isGreaterThanOrEqualTo: lowerQuery)
            .where('displayNameLower',
                isLessThanOrEqualTo: '$lowerQuery\uf8ff')
            .limit(20)
            .get();
        if (!completer.isCompleted) {
          completer.complete(snapshot.docs
              .map(AppUser.fromFirestore)
              .whereType<AppUser>()
              .where((u) => u.uid != excludeUid)
              .toList());
        }
      } catch (e, stack) {
        await reportError(e, stack);
        if (!completer.isCompleted) completer.completeError(e, stack);
      }
    });

    return completer.future;
  }

  /// Establece la canción del día del usuario.
  Future<void> setDailySong(String uid, Track track) async {
    try {
      await _usersRef.doc(uid).update({
        'dailySong': track.toMap(),
        'dailySongUpdatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e, stack) {
      await reportError(e, stack);
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
    } catch (e, stack) {
      await reportError(e, stack);
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
        users.addAll(snapshot.docs.map(AppUser.fromFirestore).whereType<AppUser>());
      }
      return users;
    } catch (e, stack) {
      await reportError(e, stack);
      rethrow;
    }
  }
}
