import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:musi_link/models/app_user.dart';
import 'package:musi_link/models/artist.dart' as app;
import 'package:musi_link/models/discovery_result.dart';
import 'package:musi_link/services/authenticated_service.dart';
import 'package:musi_link/services/spotify_stats_service.dart';
import 'package:musi_link/utils/error_reporter.dart';
import 'package:musi_link/utils/firestore_collections.dart';

class MusicProfileService with AuthenticatedService {
  MusicProfileService(
    this._spotifyGetStats, {
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  final SpotifyGetStats _spotifyGetStats;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  FirebaseAuth get auth => _auth;

  late final CollectionReference<Map<String, dynamic>> _usersRef = _firestore
      .collection(FirestoreCollections.users);

  List<DiscoveryResult>? _cachedResults;
  int _displayedCount = 0;
  DateTime? _cacheTime;

  void clearCache() {
    _cachedResults = null;
    _displayedCount = 0;
    _cacheTime = null;
  }

  static const _cacheTtl = Duration(minutes: 30);
  static const _pageSize = 20;
  static const _recommendationLimit = 100;
  static const _recommendationRefreshRetryDelay = Duration(seconds: 2);

  bool get hasMoreDiscoveryUsers =>
      _cachedResults != null && _displayedCount < _cachedResults!.length;

  bool get _isCacheValid =>
      _cachedResults != null &&
      _cacheTime != null &&
      DateTime.now().difference(_cacheTime!) < _cacheTtl;

  Future<void> saveManualArtists(
    String uid,
    List<app.Artist> selectedArtists,
  ) async {
    try {
      final artists = selectedArtists.take(15).toList();
      final genres = _spotifyGetStats.getTopGenresFromArtists(artists, 10);

      await _usersRef.doc(uid).update({
        'topArtists': artists.map((a) => a.toMap()).toList(),
        'topGenres': genres.map((g) => g.toMap()).toList(),
        'topArtistNames': artists.map((a) => a.name).toList(),
        'topGenreNames': genres.map((g) => g.name).toList(),
        'musicDataUpdatedAt': Timestamp.now(),
      });
      clearCache();
    } catch (e, stack) {
      await reportError(e, stack);
      rethrow;
    }
  }

  Future<List<DiscoveryResult>?> getDiscoveryUsersFromCache() async {
    if (_isCacheValid) {
      return List<DiscoveryResult>.unmodifiable(
        _cachedResults!.take(_displayedCount),
      );
    }

    try {
      const opts = GetOptions(source: Source.cache);

      final myDoc = await _usersRef.doc(currentUid).get(opts);
      if (!myDoc.exists) return null;

      final myUser = AppUser.fromFirestore(myDoc);
      if (myUser == null) return null;
      if (myUser.topArtistNames.isEmpty && myUser.topGenreNames.isEmpty) {
        return null;
      }

      final results = await _fetchStoredRecommendations(options: opts);
      if (results == null) return null;

      _cachedResults = results;
      _cacheTime = DateTime.now();
      _displayedCount = results.length.clamp(0, _pageSize);
      return List<DiscoveryResult>.unmodifiable(results.take(_displayedCount));
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') return null;
      await reportError(e, StackTrace.current);
      return null;
    } catch (_) {
      return null;
    }
  }

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

      final myDoc = await _usersRef.doc(currentUid).get();
      if (!myDoc.exists) return [];

      final myUser = AppUser.fromFirestore(myDoc);
      if (myUser == null) return [];
      if (myUser.topArtistNames.isEmpty && myUser.topGenreNames.isEmpty) {
        return [];
      }

      if (forceRefresh) {
        await _requestRecommendationRefresh();
      }

      var results = await _fetchStoredRecommendations() ?? [];
      if (forceRefresh && results.isEmpty) {
        await Future<void>.delayed(_recommendationRefreshRetryDelay);
        results = await _fetchStoredRecommendations() ?? [];
      }
      _cachedResults = results;
      _cacheTime = DateTime.now();
      _displayedCount = results.length.clamp(0, _pageSize);
      return List<DiscoveryResult>.unmodifiable(results.take(_displayedCount));
    } catch (e, stack) {
      await reportError(e, stack);
      return [];
    }
  }

  Future<void> _requestRecommendationRefresh() async {
    try {
      await _usersRef.doc(currentUid).update({
        'recommendationsRefreshRequestedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      await reportError(e, stack);
    }
  }

  Future<(List<DiscoveryResult>, bool hasMore)> loadMoreDiscoveryUsers() async {
    if (_cachedResults == null || _displayedCount >= _cachedResults!.length) {
      return (List<DiscoveryResult>.unmodifiable(_cachedResults ?? []), false);
    }

    _displayedCount = (_displayedCount + _pageSize).clamp(
      0,
      _cachedResults!.length,
    );
    return (
      List<DiscoveryResult>.unmodifiable(_cachedResults!.take(_displayedCount)),
      _displayedCount < _cachedResults!.length,
    );
  }

  Future<List<DiscoveryResult>?> _fetchStoredRecommendations({
    GetOptions? options,
  }) async {
    try {
      final snapshot = await _usersRef
          .doc(currentUid)
          .collection(FirestoreCollections.recommendations)
          .orderBy('score', descending: true)
          .limit(_recommendationLimit)
          .get(options);

      if (snapshot.docs.isEmpty) return null;

      final recommendationDocs = snapshot.docs;
      final orderedIds = recommendationDocs
          .map((doc) => (doc.data()['userId'] ?? doc.id).toString())
          .where((uid) => uid.isNotEmpty && uid != currentUid)
          .toList();

      if (orderedIds.isEmpty) return null;

      final usersById = <String, AppUser>{};
      for (var i = 0; i < orderedIds.length; i += 10) {
        final chunk = orderedIds.sublist(
          i,
          (i + 10).clamp(0, orderedIds.length),
        );
        final usersSnapshot = await _usersRef
            .where(FieldPath.documentId, whereIn: chunk)
            .get(options);
        for (final doc in usersSnapshot.docs) {
          final user = AppUser.fromFirestore(doc);
          if (user != null) usersById[user.uid] = user;
        }
      }

      final results = <DiscoveryResult>[];
      for (final doc in recommendationDocs) {
        final data = doc.data();
        final uid = (data['userId'] ?? doc.id).toString();
        final user = usersById[uid];
        if (user == null) continue;
        if (user.topArtistNames.isEmpty && user.topGenreNames.isEmpty) continue;

        results.add(
          DiscoveryResult(
            user: user,
            score: ((data['score'] as num?) ?? 0).toDouble(),
            sharedArtistNames:
                (data['sharedArtistNames'] as List<dynamic>?)
                    ?.map((value) => value.toString())
                    .toList() ??
                const [],
            sharedGenreNames:
                (data['sharedGenreNames'] as List<dynamic>?)
                    ?.map((value) => value.toString())
                    .toList() ??
                const [],
          ),
        );
      }

      return results.isEmpty ? null : results;
    } on FirebaseException catch (e) {
      if (options?.source == Source.cache && e.code == 'unavailable') {
        return null;
      }
      await reportError(e, StackTrace.current);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<DiscoveryResult> getCompatibilityWith(
    AppUser myUser,
    AppUser otherUser,
  ) async {
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
