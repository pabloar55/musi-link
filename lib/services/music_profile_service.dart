import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:musi_link/models/app_user.dart';
import 'package:musi_link/models/discovery_result.dart';
import 'package:musi_link/services/spotify_stats_service.dart';

class MusicProfileService {
  MusicProfileService(this._spotifyGetStats);

  final SpotifyGetStats _spotifyGetStats;

  final CollectionReference<Map<String, dynamic>> _usersRef =
      FirebaseFirestore.instance.collection('users');

  String get _currentUid => FirebaseAuth.instance.currentUser!.uid;

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
    } catch (e) {
      debugPrint('Error sincronizando perfil musical: $e');
    }
  }

  /// Obtiene la lista de usuarios para el feed de descubrimiento,
  /// ordenados por compatibilidad musical con el usuario actual.
  Future<List<DiscoveryResult>> getDiscoveryUsers() async {
    try {
      final myDoc = await _usersRef.doc(_currentUid).get();
      if (!myDoc.exists) {
        debugPrint('Discovery: documento del usuario actual no existe');
        return [];
      }

      final myUser = AppUser.fromFirestore(myDoc);
      if (myUser.topArtistNames.isEmpty && myUser.topGenreNames.isEmpty) {
        debugPrint('Discovery: el usuario actual no tiene datos musicales en Firestore');
        return [];
      }

      final snapshot = await _usersRef
          .orderBy('musicDataUpdatedAt', descending: true)
          .limit(100)
          .get();

      debugPrint('Discovery: encontrados ${snapshot.docs.length} usuarios con datos musicales');

      final results = <DiscoveryResult>[];

      for (final doc in snapshot.docs) {
        if (doc.id == _currentUid) continue;

        final user = AppUser.fromFirestore(doc);
        if (user.topArtistNames.isEmpty && user.topGenreNames.isEmpty) {
          continue;
        }

        final result = MusicProfileService.calculateCompatibility(
          myArtistNames: myUser.topArtistNames,
          myGenreNames: myUser.topGenreNames,
          otherUser: user,
        );

        results.add(result);
      }

      debugPrint('Discovery: ${results.length} usuarios compatibles encontrados');
      results.sort((a, b) => b.score.compareTo(a.score));
      return results;
    } catch (e) {
      debugPrint('Error obteniendo usuarios para descubrimiento: $e');
      return [];
    }
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
