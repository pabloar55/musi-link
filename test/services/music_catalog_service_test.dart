import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musi_link/models/artist.dart';
import 'package:musi_link/services/last_fm_service.dart';
import 'package:musi_link/services/music_catalog_service.dart';
import 'package:musi_link/services/spotify_cloud_service.dart';

class MockSpotifyCloudService extends Mock implements SpotifyCloudService {}

class MockLastFmService extends Mock implements LastFmService {}

void main() {
  group('MusicCatalogService.getTopGenresFromArtists', () {
    late MusicCatalogService service;

    setUp(() {
      service = MusicCatalogService(
        MockSpotifyCloudService(),
        MockLastFmService(),
      );
    });

    test('normalizes aliases, removes noisy tags, and deduplicates counts', () {
      final genres = service.getTopGenresFromArtists(const [
        Artist(
          name: 'Artist A',
          imageUrl: '',
          genres: ['Hip-Hop', 'Canadian', 'seen live', 'R&B'],
        ),
        Artist(
          name: 'Artist B',
          imageUrl: '',
          genres: ['rap', 'rhythm and blues', '80s', 'electro'],
        ),
      ], 10);

      expect(genres.map((genre) => genre.name), [
        'hip hop',
        'r&b',
        'electronic',
      ]);
      expect(genres.map((genre) => genre.count), [2, 2, 1]);
    });

    test('honors the requested genre limit after normalization', () {
      final genres = service.getTopGenresFromArtists(const [
        Artist(name: 'Artist A', imageUrl: '', genres: ['rock', 'pop', 'jazz']),
      ], 2);

      expect(genres.map((genre) => genre.name), ['rock', 'pop']);
    });
  });
}
