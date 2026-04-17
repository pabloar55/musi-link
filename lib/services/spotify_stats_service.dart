import 'dart:convert';

import 'package:musi_link/models/artist.dart' as app;
import 'package:musi_link/models/genre.dart';
import 'package:musi_link/models/track.dart' as app;
import 'package:musi_link/services/spotify_service.dart';
import 'package:musi_link/utils/error_reporter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotify/spotify.dart' show SearchType, TimeRange, Track;

/// Lanzada cuando no hay conexión y tampoco hay datos en caché local.
class OfflineNoDataException implements Exception {
  const OfflineNoDataException();
}

/// Obtiene estadísticas del usuario vía el paquete `spotify`.
///
/// Usa [SpotifyService.api] que ya maneja token refresh automáticamente.
/// Persiste el último resultado exitoso en [SharedPreferences] y lo devuelve
/// como fallback cuando no hay conexión a internet.
class SpotifyGetStats {
  SpotifyGetStats(this._spotifyService, this._prefs);

  final SpotifyService _spotifyService;
  final SharedPreferences _prefs;

  /// `true` si el último resultado provino del caché persistido (sin red).
  bool _lastServedFromCache = false;
  bool get lastServedFromCache => _lastServedFromCache;

  static const _cachePrefix = 'stats_cache_';
  static const _cacheTsPrefix = 'stats_cache_ts_';
  static const _staleDuration = Duration(hours: 48);

  DateTime? _lastCacheTimestamp;

  /// `true` when cached data is older than 48 hours (online or offline).
  bool get cacheIsStale {
    final ts = _lastCacheTimestamp;
    if (ts == null) return false;
    return DateTime.now().difference(ts) > _staleDuration;
  }

  static const _timeRangeMap = {
    'short_term': TimeRange.shortTerm,
    'medium_term': TimeRange.mediumTerm,
    'long_term': TimeRange.longTerm,
  };

  Future<void> _saveCache(String key, List<Map<String, dynamic>> data) async {
    await _prefs.setString('$_cachePrefix$key', jsonEncode(data));
    await _prefs.setString('$_cacheTsPrefix$key', DateTime.now().toIso8601String());
  }

  Future<List<Map<String, dynamic>>?> _loadCache(String key) async {
    final raw = _prefs.getString('$_cachePrefix$key');
    if (raw == null) return null;
    final tsRaw = _prefs.getString('$_cacheTsPrefix$key');
    _lastCacheTimestamp = tsRaw != null ? DateTime.tryParse(tsRaw) : null;
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  static bool _isNetworkError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('network is unreachable') ||
        msg.contains('clientexception');
  }

  Future<List<app.Track>> getTopTracks(int limit, String timeRange) async {
    final cacheKey = 'tracks_${timeRange}_$limit';
    try {
      final api = _spotifyService.api;
      final tr = _timeRangeMap[timeRange] ?? TimeRange.mediumTerm;
      final pages = api.me.topTracks(timeRange: tr);
      final page = await pages.first(limit);

      final result = page.items?.map((t) {
            final images = t.album?.images;
            final imageUrl = (images != null && images.isNotEmpty)
                ? images.first.url ?? ''
                : '';
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

      _lastServedFromCache = false;
      await _saveCache(cacheKey, result.map((t) => t.toMap()).toList());
      return result;
    } catch (e, stack) {
      if (_isNetworkError(e)) {
        final cached = await _loadCache(cacheKey);
        if (cached != null) {
          _lastServedFromCache = true;
          return cached.map(app.Track.fromMap).toList();
        }
        throw const OfflineNoDataException();
      }
      await reportError(e, stack);
      rethrow;
    }
  }

  Future<List<app.Artist>> getTopArtists(int limit, String timeRange) async {
    final cacheKey = 'artists_${timeRange}_$limit';
    try {
      final api = _spotifyService.api;
      final tr = _timeRangeMap[timeRange] ?? TimeRange.mediumTerm;
      final pages = api.me.topArtists(timeRange: tr);
      final page = await pages.first(limit);

      final result = page.items?.map((a) {
            final images = a.images;
            final imageUrl = (images != null && images.isNotEmpty)
                ? images.first.url ?? ''
                : '';
            return app.Artist(
              name: a.name ?? 'Artista desconocido',
              imageUrl: imageUrl,
              genres: a.genres?.toList() ?? [],
            );
          }).toList() ??
          [];

      _lastServedFromCache = false;
      await _saveCache(cacheKey, result.map((a) => a.toMap()).toList());
      return result;
    } catch (e, stack) {
      if (_isNetworkError(e)) {
        final cached = await _loadCache(cacheKey);
        if (cached != null) {
          _lastServedFromCache = true;
          return cached.map(app.Artist.fromMap).toList();
        }
        throw const OfflineNoDataException();
      }
      await reportError(e, stack);
      rethrow;
    }
  }

  List<Genre> getTopGenresFromArtists(List<app.Artist> artists, int limit) {
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

  Future<List<Genre>> getTopGenres(int limit, String timeRange) async {
    final cacheKey = 'genres_${timeRange}_$limit';
    try {
      final artists = await getTopArtists(50, timeRange);
      final artistsFromCache = _lastServedFromCache;

      final genreCount = <String, int>{};
      for (final artist in artists) {
        for (final genre in artist.genres) {
          genreCount[genre] = (genreCount[genre] ?? 0) + 1;
        }
      }

      if (genreCount.isEmpty) {
        _lastServedFromCache = artistsFromCache;
        return [];
      }

      final sorted = genreCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final totalMentions = sorted.fold<int>(0, (sum, e) => sum + e.value);

      final result = sorted.take(limit).map((entry) {
        return Genre(
          name: entry.key,
          count: entry.value,
          percentage: (entry.value / totalMentions) * 100,
        );
      }).toList();

      _lastServedFromCache = artistsFromCache;
      if (!artistsFromCache) {
        await _saveCache(cacheKey, result.map((g) => g.toMap()).toList());
      }
      return result;
    } catch (e, stack) {
      if (e is OfflineNoDataException || _isNetworkError(e)) {
        final cached = await _loadCache(cacheKey);
        if (cached != null) {
          _lastServedFromCache = true;
          return cached.map(Genre.fromMap).toList();
        }
        throw const OfflineNoDataException();
      }
      await reportError(e, stack);
      rethrow;
    }
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
    } catch (e, stack) {
      await reportError(e, stack);
      rethrow;
    }
  }
}
