// ignore_for_file: subtype_of_sealed_class
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:musi_link/models/artist.dart' as app;
import 'package:musi_link/services/spotify_service.dart';
import 'package:musi_link/services/spotify_stats_service.dart';

class MockSpotifyService extends Mock implements SpotifyService {}

/// Subclase de prueba que permite inyectar artistas directamente,
/// sin pasar por la SpotifyApi. Así se puede testear la lógica de
/// agregación de géneros de forma aislada.
class _FakeStats extends SpotifyGetStats {
  _FakeStats(super.spotifyService, super.prefs);

  List<app.Artist>? _artists;
  Object? _error;

  void stubArtists(List<app.Artist> artists) {
    _artists = artists;
    _error = null;
  }

  void stubNetworkError() {
    _error = Exception('SocketException: failed host lookup');
    _artists = null;
  }

  @override
  Future<List<app.Artist>> getTopArtists(int limit, String timeRange) async {
    if (_error != null) throw _error!;
    return _artists ?? [];
  }
}

void main() {
  late MockSpotifyService mockSpotify;
  late _FakeStats stats;

  setUp(() async {
    mockSpotify = MockSpotifyService();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    stats = _FakeStats(mockSpotify, prefs);
  });

  // ── Aggregation algorithm ─────────────────────────────────────────────────

  group('SpotifyGetStats.getTopGenres — agregación de géneros', () {
    test('sin artistas devuelve lista vacía', () async {
      stats.stubArtists([]);

      final genres = await stats.getTopGenres(10, 'medium_term');

      expect(genres, isEmpty);
    });

    test('artistas sin géneros devuelve lista vacía', () async {
      stats.stubArtists([
        const app.Artist(name: 'A', imageUrl: '', genres: []),
        const app.Artist(name: 'B', imageUrl: '', genres: []),
      ]);

      final genres = await stats.getTopGenres(10, 'medium_term');

      expect(genres, isEmpty);
    });

    test('un solo género → count 1, percentage 100%', () async {
      stats.stubArtists([
        const app.Artist(name: 'A', imageUrl: '', genres: ['rock']),
      ]);

      final genres = await stats.getTopGenres(10, 'medium_term');

      expect(genres.length, 1);
      expect(genres.first.name, 'rock');
      expect(genres.first.count, 1);
      expect(genres.first.percentage, closeTo(100.0, 0.001));
    });

    test('el mismo género en varios artistas acumula el count', () async {
      stats.stubArtists([
        const app.Artist(name: 'A', imageUrl: '', genres: ['rock', 'indie']),
        const app.Artist(name: 'B', imageUrl: '', genres: ['rock']),
        const app.Artist(name: 'C', imageUrl: '', genres: ['pop']),
      ]);

      final genres = await stats.getTopGenres(10, 'medium_term');

      final rock = genres.firstWhere((g) => g.name == 'rock');
      expect(rock.count, 2);
    });

    test('géneros ordenados por frecuencia descendente', () async {
      stats.stubArtists([
        const app.Artist(name: 'A', imageUrl: '', genres: ['pop']),
        const app.Artist(name: 'B', imageUrl: '', genres: ['pop']),
        const app.Artist(name: 'C', imageUrl: '', genres: ['pop']),
        const app.Artist(name: 'D', imageUrl: '', genres: ['rock', 'indie']),
        const app.Artist(name: 'E', imageUrl: '', genres: ['rock']),
      ]);

      final genres = await stats.getTopGenres(10, 'medium_term');

      expect(genres[0].name, 'pop');   // count 3
      expect(genres[1].name, 'rock');  // count 2
      expect(genres[2].name, 'indie'); // count 1
    });

    test('los percentages de todos los géneros suman 100%', () async {
      stats.stubArtists([
        const app.Artist(name: 'A', imageUrl: '', genres: ['rock']),
        const app.Artist(name: 'B', imageUrl: '', genres: ['rock']),
        const app.Artist(name: 'C', imageUrl: '', genres: ['pop']),
      ]);

      final genres = await stats.getTopGenres(10, 'medium_term');

      final totalPct = genres.fold<double>(0, (sum, g) => sum + g.percentage);
      expect(totalPct, closeTo(100.0, 0.001));
    });

    test('el porcentaje de cada género es proporcional a su count', () async {
      // 2 rock + 1 pop = 3 menciones totales
      stats.stubArtists([
        const app.Artist(name: 'A', imageUrl: '', genres: ['rock']),
        const app.Artist(name: 'B', imageUrl: '', genres: ['rock']),
        const app.Artist(name: 'C', imageUrl: '', genres: ['pop']),
      ]);

      final genres = await stats.getTopGenres(10, 'medium_term');

      final rock = genres.firstWhere((g) => g.name == 'rock');
      final pop = genres.firstWhere((g) => g.name == 'pop');
      expect(rock.percentage, closeTo(66.67, 0.01));
      expect(pop.percentage, closeTo(33.33, 0.01));
    });

    test('limit trunca el número de géneros devueltos', () async {
      stats.stubArtists([
        const app.Artist(name: 'A', imageUrl: '', genres: ['rock']),
        const app.Artist(name: 'B', imageUrl: '', genres: ['pop']),
        const app.Artist(name: 'C', imageUrl: '', genres: ['indie']),
        const app.Artist(name: 'D', imageUrl: '', genres: ['jazz']),
      ]);

      final genres = await stats.getTopGenres(2, 'medium_term');

      expect(genres.length, 2);
    });

    test('limit mayor que géneros disponibles devuelve todos', () async {
      stats.stubArtists([
        const app.Artist(name: 'A', imageUrl: '', genres: ['rock']),
      ]);

      final genres = await stats.getTopGenres(50, 'medium_term');

      expect(genres.length, 1);
    });
  });

  // ── Offline fallback ──────────────────────────────────────────────────────

  group('SpotifyGetStats.getTopGenres — offline fallback', () {
    test('fetch exitoso marca lastServedFromCache como false', () async {
      stats.stubArtists([
        const app.Artist(name: 'A', imageUrl: '', genres: ['rock']),
      ]);

      await stats.getTopGenres(10, 'medium_term');

      expect(stats.lastServedFromCache, isFalse);
    });

    test('offline sin caché lanza OfflineNoDataException', () async {
      stats.stubNetworkError();

      expect(
        () => stats.getTopGenres(10, 'medium_term'),
        throwsA(isA<OfflineNoDataException>()),
      );
    });

    test('offline con caché devuelve datos persistidos', () async {
      // 1. Fetch exitoso → persiste en SharedPreferences
      stats.stubArtists([
        const app.Artist(name: 'A', imageUrl: '', genres: ['rock']),
      ]);
      await stats.getTopGenres(10, 'medium_term');

      // 2. Simular pérdida de conexión
      stats.stubNetworkError();

      final cached = await stats.getTopGenres(10, 'medium_term');

      expect(cached, isNotEmpty);
      expect(cached.first.name, 'rock');
      expect(stats.lastServedFromCache, isTrue);
    });
  });

  // ── searchTracks guard ────────────────────────────────────────────────────

  group('SpotifyGetStats.searchTracks', () {
    test('query vacío devuelve lista vacía sin llamar a la API', () async {
      final results = await stats.searchTracks('');

      expect(results, isEmpty);
      verifyNever(() => mockSpotify.api);
    });

    test('query solo espacios devuelve lista vacía', () async {
      final results = await stats.searchTracks('   ');

      expect(results, isEmpty);
      verifyNever(() => mockSpotify.api);
    });
  });
}
