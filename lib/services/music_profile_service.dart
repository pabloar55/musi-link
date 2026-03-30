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
  DocumentSnapshot<Map<String, dynamic>>? _lastDocument;
  DateTime? _cacheTime;
  bool _hasMorePages = false;

  static const _cacheTtl = Duration(minutes: 5);
  static const _pageSize = 20;

  bool get hasMoreDiscoveryUsers => _hasMorePages;

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
          await _spotifyGetStats.getTopArtists(20, 'medium_term');
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
      return List<DiscoveryResult>.unmodifiable(_cachedResults!);
    }

    try {
      // Reset de paginación en cada carga fresca
      _lastDocument = null;
      _hasMorePages = false;
      _cachedResults = null;

      final myDoc = await _usersRef.doc(_currentUid).get();
      if (!myDoc.exists) {
        return [];
      }

      final myUser = AppUser.fromFirestore(myDoc);
      if (myUser.topArtistNames.isEmpty && myUser.topGenreNames.isEmpty) {
        return [];
      }

      final results = await _fetchPage(myUser);
      _cachedResults = results;
      _cacheTime = DateTime.now();
      return List<DiscoveryResult>.unmodifiable(results);
    } catch (e, stack) {
      await reportError(e, stack);
      return [];
    }
  }

  /// Carga la siguiente página y la añade al caché acumulado.
  /// Devuelve la lista completa actualizada y si quedan más páginas.
  Future<(List<DiscoveryResult>, bool hasMore)> loadMoreDiscoveryUsers() async {
    if (!_hasMorePages || _cachedResults == null) {
      return (List<DiscoveryResult>.unmodifiable(_cachedResults ?? []), false);
    }

    try {
      final myDoc = await _usersRef.doc(_currentUid).get();
      if (!myDoc.exists) {
        return (List<DiscoveryResult>.unmodifiable(_cachedResults!), false);
      }

      final myUser = AppUser.fromFirestore(myDoc);
      final newResults = await _fetchPage(myUser);

      _cachedResults = [..._cachedResults!, ...newResults];
      return (List<DiscoveryResult>.unmodifiable(_cachedResults!), _hasMorePages);
    } catch (e, stack) {
      await reportError(e, stack);
      return (List<DiscoveryResult>.unmodifiable(_cachedResults!), _hasMorePages);
    }
  }

  Future<List<DiscoveryResult>> _fetchPage(AppUser myUser) async {
    Query<Map<String, dynamic>> query = _usersRef
        .orderBy('musicDataUpdatedAt', descending: true)
        .limit(_pageSize);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isEmpty) {
      _hasMorePages = false;
      return [];
    }

    _lastDocument = snapshot.docs.last;
    _hasMorePages = snapshot.docs.length >= _pageSize;

    final results = <DiscoveryResult>[];
    for (final doc in snapshot.docs) {
      if (doc.id == _currentUid) continue;

      final user = AppUser.fromFirestore(doc);
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
