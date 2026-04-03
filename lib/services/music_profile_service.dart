import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:musi_link/models/app_user.dart';
import 'package:musi_link/models/discovery_result.dart';
import 'package:musi_link/services/spotify_stats_service.dart';
import 'package:musi_link/utils/error_reporter.dart';
import 'package:musi_link/utils/firestore_collections.dart';

class MusicProfileService {
  MusicProfileService(
    this._spotifyGetStats, {
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  final SpotifyGetStats _spotifyGetStats;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  late final CollectionReference<Map<String, dynamic>> _usersRef =
      _firestore.collection(FirestoreCollections.users);

  // --- Discovery cache & pagination state ---
  List<DiscoveryResult>? _cachedResults;
  int _displayedCount = 0;
  DateTime? _cacheTime;

  static const _cacheTtl = Duration(minutes: 5);
  static const _pageSize = 20;
  static const _queryLimit = 100;

  bool get hasMoreDiscoveryUsers =>
      _cachedResults != null && _displayedCount < _cachedResults!.length;

  bool get _isCacheValid =>
      _cachedResults != null &&
      _cacheTime != null &&
      DateTime.now().difference(_cacheTime!) < _cacheTtl;

  /// Returns the UID of the currently authenticated user.
  /// Throws [StateError] instead of crashing if the session is lost.
  String get _currentUid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('MusicProfileService: no authenticated user.');
    return uid;
  }

  /// Sincroniza los datos musicales del usuario desde Spotify a Firestore.
  /// Aplica un cooldown de 24h para evitar llamadas innecesarias.
  Future<void> syncMusicProfile(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final lastSync = (data['musicDataUpdatedAt'] as Timestamp?)?.toDate();
      if (lastSync != null &&
          DateTime.now().difference(lastSync).inHours < 24) {
        return;
      }

      final artists =
          await _spotifyGetStats.getTopArtists(15, 'medium_term');
      final genres =
          await _spotifyGetStats.getTopGenres(10, 'medium_term');

      await _usersRef.doc(uid).update({
        'topArtists': artists.map((a) => a.toMap()).toList(),
        'topGenres': genres.map((g) => g.toMap()).toList(),
        'topArtistNames': artists.map((a) => a.name).toList(),
        'topGenreNames': genres.map((g) => g.name).toList(),
        'musicDataUpdatedAt': Timestamp.now(),
      });
    } catch (e, stack) {
      await reportError(e, stack);
    }
  }

  /// Obtiene la primera página de usuarios para el feed de descubrimiento.
  /// Usa caché con TTL de 5 minutos. Pasa [forceRefresh] para invalidarlo.
  Future<List<DiscoveryResult>> getDiscoveryUsers({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _isCacheValid) {
      return List<DiscoveryResult>.unmodifiable(
        _cachedResults!.take(_displayedCount),
      );
    }

    try {
      _cachedResults = null;
      _displayedCount = 0;

      final myDoc = await _usersRef.doc(_currentUid).get();
      if (!myDoc.exists) {
        return [];
      }

      final myUser = AppUser.fromFirestore(myDoc);
      if (myUser == null) return [];
      if (myUser.topArtistNames.isEmpty && myUser.topGenreNames.isEmpty) {
        return [];
      }

      final results = await _fetchRelevantUsers(myUser);
      _cachedResults = results;
      _cacheTime = DateTime.now();
      _displayedCount = results.length.clamp(0, _pageSize);
      return List<DiscoveryResult>.unmodifiable(
        results.take(_displayedCount),
      );
    } catch (e, stack) {
      await reportError(e, stack);
      return [];
    }
  }

  /// Devuelve la siguiente página desde el caché local (0 Firestore reads).
  Future<(List<DiscoveryResult>, bool hasMore)> loadMoreDiscoveryUsers() async {
    if (_cachedResults == null || _displayedCount >= _cachedResults!.length) {
      return (List<DiscoveryResult>.unmodifiable(_cachedResults ?? []), false);
    }

    _displayedCount =
        (_displayedCount + _pageSize).clamp(0, _cachedResults!.length);
    return (
      List<DiscoveryResult>.unmodifiable(_cachedResults!.take(_displayedCount)),
      _displayedCount < _cachedResults!.length,
    );
  }

  /// Lanza dos queries en paralelo usando arrayContainsAny para traer
  /// solo usuarios que comparten al menos un artista o género.
  /// Máximo ~200 reads (100 por query) en vez de escanear toda la colección.
  Future<List<DiscoveryResult>> _fetchRelevantUsers(AppUser myUser) async {
    final artistNames = myUser.topArtistNames.take(10).toList();
    final genreNames = myUser.topGenreNames.take(10).toList();

    // Lanzar ambas queries en paralelo
    final artistFuture = artistNames.isNotEmpty
        ? _usersRef
            .where('topArtistNames', arrayContainsAny: artistNames)
            .limit(_queryLimit)
            .get()
        : null;

    final genreFuture = genreNames.isNotEmpty
        ? _usersRef
            .where('topGenreNames', arrayContainsAny: genreNames)
            .limit(_queryLimit)
            .get()
        : null;

    final seen = <String>{_currentUid};
    final allDocs = <DocumentSnapshot<Map<String, dynamic>>>[];

    if (artistFuture != null) {
      for (final doc in (await artistFuture).docs) {
        if (seen.add(doc.id)) allDocs.add(doc);
      }
    }

    if (genreFuture != null) {
      for (final doc in (await genreFuture).docs) {
        if (seen.add(doc.id)) allDocs.add(doc);
      }
    }

    final results = <DiscoveryResult>[];
    for (final doc in allDocs) {
      final user = AppUser.fromFirestore(doc);
      if (user == null) continue;
      if (user.topArtistNames.isEmpty && user.topGenreNames.isEmpty) continue;

      results.add(calculateCompatibility(
        myArtistNames: myUser.topArtistNames,
        myGenreNames: myUser.topGenreNames,
        otherUser: user,
      ));
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  /// Calcula la compatibilidad entre el usuario actual y otro usuario.
  Future<DiscoveryResult> getCompatibilityWith(AppUser otherUser) async {
    final myDoc = await _usersRef.doc(_currentUid).get();
    if (!myDoc.exists) {
      return DiscoveryResult(
        user: otherUser,
        score: 0,
        sharedArtistNames: [],
        sharedGenreNames: [],
      );
    }

    final myUser = AppUser.fromFirestore(myDoc);
    if (myUser == null) {
      return DiscoveryResult(
        user: otherUser,
        score: 0,
        sharedArtistNames: [],
        sharedGenreNames: [],
      );
    }
    return MusicProfileService.calculateCompatibility(
      myArtistNames: myUser.topArtistNames,
      myGenreNames: myUser.topGenreNames,
      otherUser: otherUser,
    );
  }

  @visibleForTesting
  static DiscoveryResult calculateCompatibility({
    required List<String> myArtistNames,
    required List<String> myGenreNames,
    required AppUser otherUser,
  }) {
    final sharedArtists = myArtistNames
        .toSet()
        .intersection(otherUser.topArtistNames.toSet())
        .toList();

    final sharedGenres = myGenreNames
        .toSet()
        .intersection(otherUser.topGenreNames.toSet())
        .toList();
    // Con 5 artistas en común ya se llega al máximo de 70 puntos, y con 5 géneros se llega al máximo de 30 puntos.
    // 5*14 = 70 puntos de artistas, y 5*6 = 30 puntos de géneros, para un total de 100 puntos.
    // El clamp asegura que no se pase de esos máximos aunque haya más coincidencias.
    final artistScore = (sharedArtists.length * 14.0).clamp(0.0, 70.0);
    final genreScore = (sharedGenres.length * 6.0).clamp(0.0, 30.0);

    return DiscoveryResult(
      user: otherUser,
      score: artistScore + genreScore,
      sharedArtistNames: sharedArtists,
      sharedGenreNames: sharedGenres,
    );
  }
}
