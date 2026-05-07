import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:musi_link/models/app_user.dart';
import 'package:musi_link/models/artist.dart' as app;
import 'package:musi_link/models/discovery_result.dart';
import 'package:musi_link/services/authenticated_service.dart';
import 'package:musi_link/services/music_catalog_service.dart';
import 'package:musi_link/utils/error_reporter.dart';
import 'package:musi_link/utils/firestore_collections.dart';
import 'package:musi_link/utils/genre_normalizer.dart';

class MusicProfileService with AuthenticatedService {
  MusicProfileService(
    this._musicCatalogService, {
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  final MusicCatalogService _musicCatalogService;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  FirebaseAuth get auth => _auth;

  late final CollectionReference<Map<String, dynamic>> _usersRef = _firestore
      .collection(FirestoreCollections.users);
  late final CollectionReference<Map<String, dynamic>> _privateUsersRef =
      _firestore.collection(FirestoreCollections.userPrivate);

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
  static const _recommendationRefreshTimeout = Duration(seconds: 60);
  static const _artistScoreWeight = 70.0;
  static const _genreScoreWeight = 30.0;
  static const _artistEvidenceTarget = 7.0;
  static const _genreEvidenceTarget = 4.0;

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
      final artists = await _hydrateMissingArtistDetails(
        selectedArtists.take(50).toList(),
      );
      final genres = _musicCatalogService.getTopGenresFromArtists(artists, 10);

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

  Future<List<app.Artist>> _hydrateMissingArtistDetails(
    List<app.Artist> artists,
  ) {
    return Future.wait(artists.map(_hydrateMissingArtistDetailsFor));
  }

  Future<app.Artist> _hydrateMissingArtistDetailsFor(app.Artist artist) async {
    if (artist.imageUrl.trim().isNotEmpty) return artist;

    try {
      final results = await _musicCatalogService.searchArtists(
        artist.name,
        limit: 1,
      );
      if (results.isEmpty) return artist;

      final enriched = results.first;
      if (_normalizedMusicKey(enriched.name) !=
          _normalizedMusicKey(artist.name)) {
        return artist;
      }

      return app.Artist(
        name: artist.name,
        imageUrl: enriched.imageUrl.isNotEmpty
            ? enriched.imageUrl
            : artist.imageUrl,
        genres: enriched.genres.isNotEmpty ? enriched.genres : artist.genres,
        spotifyId: enriched.spotifyId ?? artist.spotifyId,
      );
    } catch (_) {
      return artist;
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

      final results = await _fetchStoredRecommendations() ?? [];
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
      final userRef = _usersRef.doc(currentUid);
      await userRef.update({
        'recommendationsRefreshRequestedAt': FieldValue.serverTimestamp(),
      });

      await userRef
          .snapshots()
          .where((snapshot) {
            final data = snapshot.data();
            final requestedAt =
                data?['recommendationsRefreshRequestedAt'] as Timestamp?;
            final generatedAt =
                data?['recommendationsGeneratedAt'] as Timestamp?;
            return requestedAt != null &&
                generatedAt != null &&
                generatedAt.compareTo(requestedAt) >= 0;
          })
          .first
          .timeout(_recommendationRefreshTimeout);
    } on TimeoutException {
      // Keep the previous recommendations visible if the refresh completion
      // signal is delayed by network conditions or a slow Cloud Function.
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

      try {
        final privateDoc = await _privateUsersRef.doc(currentUid).get(options);
        final blockedUids = Set<String>.from(
          (privateDoc.data()?['blockedUsers'] as List?)?.map(
                (e) => e.toString(),
              ) ??
              [],
        );
        if (blockedUids.isNotEmpty) {
          results.removeWhere((r) => blockedUids.contains(r.user.uid));
        }
      } catch (_) {
        // non-fatal: discovery proceeds without block filtering
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
    final myUniqueArtistNames = _uniqueMusicNames(myArtistNames);
    final otherUniqueArtistNames = _uniqueMusicNames(otherUser.topArtistNames);
    final myUniqueGenreNames = _uniqueGenreNames(myGenreNames);
    final otherUniqueGenreNames = _uniqueGenreNames(otherUser.topGenreNames);
    final myArtists = myUniqueArtistNames.map(_normalizedMusicKey).toSet();
    final myGenres = myUniqueGenreNames.map(_normalizedMusicKey).toSet();
    final sharedArtists = otherUniqueArtistNames
        .where((artist) => myArtists.contains(_normalizedMusicKey(artist)))
        .toList();
    final sharedGenres = otherUniqueGenreNames
        .where((genre) => myGenres.contains(_normalizedMusicKey(genre)))
        .toList();

    final artistScore = _similarityScore(
      sharedCount: sharedArtists.length,
      leftCount: myUniqueArtistNames.length,
      rightCount: otherUniqueArtistNames.length,
      evidenceTarget: _artistEvidenceTarget,
      weight: _artistScoreWeight,
    );
    final genreScore = _similarityScore(
      sharedCount: sharedGenres.length,
      leftCount: myUniqueGenreNames.length,
      rightCount: otherUniqueGenreNames.length,
      evidenceTarget: _genreEvidenceTarget,
      weight: _genreScoreWeight,
    );

    return DiscoveryResult(
      user: otherUser,
      score: (artistScore + genreScore).roundToDouble(),
      sharedArtistNames: sharedArtists,
      sharedGenreNames: sharedGenres,
    );
  }

  static String _normalizedMusicKey(String value) => value.trim().toLowerCase();

  static List<String> _uniqueMusicNames(List<String> values) {
    final namesByKey = <String, String>{};
    for (final value in values) {
      final trimmed = value.trim();
      final key = _normalizedMusicKey(trimmed);
      if (key.isNotEmpty && !namesByKey.containsKey(key)) {
        namesByKey[key] = trimmed;
      }
    }
    return namesByKey.values.toList(growable: false);
  }

  static List<String> _uniqueGenreNames(List<String> values) =>
      normalizeGenreNames(values);

  static double _similarityScore({
    required int sharedCount,
    required int leftCount,
    required int rightCount,
    required double evidenceTarget,
    required double weight,
  }) {
    if (sharedCount == 0) return 0.0;

    final comparableCount = leftCount < rightCount ? leftCount : rightCount;
    final coverage = comparableCount == 0 ? 0.0 : sharedCount / comparableCount;
    final evidence = (sharedCount / evidenceTarget).clamp(0.0, 1.0);
    final similarity = coverage > evidence ? coverage : evidence;
    return similarity * weight;
  }
}
