import 'package:musi_link/models/artist.dart' as app;
import 'package:musi_link/models/genre.dart';
import 'package:musi_link/models/track.dart' as app;
import 'package:musi_link/services/last_fm_service.dart';
import 'package:musi_link/services/spotify_cloud_service.dart';
import 'package:musi_link/utils/genre_normalizer.dart';

/// Búsqueda de catálogo musical y cálculo local del perfil musical manual.
class MusicCatalogService {
  MusicCatalogService(this._client, this._lastFm);

  final SpotifyCloudService _client;
  final LastFmService _lastFm;

  List<Genre> getTopGenresFromArtists(List<app.Artist> artists, int limit) {
    final genreCount = <String, int>{};
    for (final artist in artists) {
      for (final genre in artist.genres) {
        final normalizedGenre = normalizeGenreName(genre);
        if (normalizedGenre == null) continue;
        genreCount[normalizedGenre] = (genreCount[normalizedGenre] ?? 0) + 1;
      }
    }
    if (genreCount.isEmpty) return [];
    final sorted = genreCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalMentions = sorted.fold<int>(0, (sum, e) => sum + e.value);
    return sorted.take(limit).map((entry) {
      return Genre(
        name: entry.key,
        count: entry.value,
        percentage: (entry.value / totalMentions) * 100,
      );
    }).toList();
  }

  Future<List<app.Track>> searchTracks(String query, {int limit = 20}) =>
      _client.searchTracks(query, limit: limit);

  Future<List<app.Artist>> searchArtists(String query, {int limit = 20}) =>
      _client.searchArtists(query, limit: limit);

  Future<List<app.Artist>> getRelatedArtists(String artistName) =>
      _lastFm.getSimilarArtists(artistName);
}
