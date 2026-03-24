import 'package:flutter/foundation.dart';
import 'package:musi_link/models/artist.dart' as app;
import 'package:musi_link/models/genre.dart';
import 'package:musi_link/models/track.dart' as app;
import 'package:musi_link/services/spotify_service.dart';
import 'package:spotify/spotify.dart' show SearchType, TimeRange, Track;

/// Obtiene estadísticas del usuario vía el paquete `spotify`.
///
/// Usa [SpotifyService.api] que ya maneja token refresh automáticamente.
class SpotifyGetStats {
  SpotifyGetStats(this._spotifyService);

  final SpotifyService _spotifyService;

  static const _timeRangeMap = {
    'short_term': TimeRange.shortTerm,
    'medium_term': TimeRange.mediumTerm,
    'long_term': TimeRange.longTerm,
  };

  Future<List<app.Track>> getTopTracks(int limit, String timeRange) async {
    try {
      debugPrint("----------Obteniendo top tracks...---------");
      final api = _spotifyService.api;
      final tr = _timeRangeMap[timeRange] ?? TimeRange.mediumTerm;
      final pages = api.me.topTracks(timeRange: tr);
      final page = await pages.first(limit);

      return page.items?.map((t) {
            final images = t.album?.images;
            final imageUrl =
                (images != null && images.isNotEmpty) ? images.first.url ?? '' : '';
            final artistName = (t.artists != null && t.artists!.isNotEmpty)
                ? t.artists!.first.name ?? 'Artista desconocido'
                : 'Artista desconocido';
            return app.Track(
              title: t.name ?? 'Sin título',
              artist: artistName,
              imageUrl: imageUrl,
              spotifyUrl: (t.id != null && t.id!.isNotEmpty)
                  ? 'https://open.spotify.com/track/${t.id}'
                  : '',
            );
          }).toList() ??
          [];
    } catch (e) {
      debugPrint("❌ Error al obtener top tracks: $e");
      return [];
    }
  }

  Future<List<app.Artist>> getTopArtists(int limit, String timeRange) async {
    try {
      debugPrint("----------Obteniendo top artists...---------");
      final api = _spotifyService.api;
      final tr = _timeRangeMap[timeRange] ?? TimeRange.mediumTerm;
      final pages = api.me.topArtists(timeRange: tr);
      final page = await pages.first(limit);

      return page.items?.map((a) {
            final images = a.images;
            final imageUrl =
                (images != null && images.isNotEmpty) ? images.first.url ?? '' : '';
            return app.Artist(
              name: a.name ?? 'Artista desconocido',
              imageUrl: imageUrl,
              genres: a.genres?.toList() ?? [],
            );
          }).toList() ??
          [];
    } catch (e) {
      debugPrint("❌ Error al obtener top artists: $e");
      return [];
    }
  }

  Future<List<Genre>> getTopGenres(int limit, String timeRange) async {
    final artists = await getTopArtists(50, timeRange);

    final genreCount = <String, int>{};
    for (final artist in artists) {
      for (final genre in artist.genres) {
        genreCount[genre] = (genreCount[genre] ?? 0) + 1;
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

  /// Busca canciones en Spotify por nombre.
  Future<List<app.Track>> searchTracks(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) return [];
    try {
      final api = _spotifyService.api;
      final results = api.search.get(query, types: [SearchType.track]);
      final page = await results.first(limit);

      final tracks = <app.Track>[];
      for (final pages in page) {
        if (pages.items == null) continue;
        for (final item in pages.items!) {
          if (item is Track) {
            final images = item.album?.images;
            final imageUrl = (images != null && images.isNotEmpty)
                ? images.first.url ?? ''
                : '';
            final artistName =
                (item.artists != null && item.artists!.isNotEmpty)
                    ? item.artists!.first.name ?? 'Artista desconocido'
                    : 'Artista desconocido';
            tracks.add(app.Track(
              title: item.name ?? 'Sin título',
              artist: artistName,
              imageUrl: imageUrl,
              spotifyUrl: (item.id != null && item.id!.isNotEmpty)
                  ? 'https://open.spotify.com/track/${item.id}'
                  : '',
            ));
          }
        }
      }
      return tracks;
    } catch (e) {
      debugPrint("Error al buscar tracks: $e");
      return [];
    }
  }
}