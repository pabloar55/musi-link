import 'package:flutter_test/flutter_test.dart';
import 'package:musi_link/models/track.dart';

void main() {
  group('Track', () {
    group('constructor', () {
      test('crea Track con todos los campos', () {
        const track = Track(
          title: 'Bohemian Rhapsody',
          artist: 'Queen',
          imageUrl: 'https://example.com/image.jpg',
          spotifyUrl: 'https://open.spotify.com/track/123',
        );

        expect(track.title, 'Bohemian Rhapsody');
        expect(track.artist, 'Queen');
        expect(track.imageUrl, 'https://example.com/image.jpg');
        expect(track.spotifyUrl, 'https://open.spotify.com/track/123');
      });

      test('spotifyUrl tiene valor por defecto vacío', () {
        const track = Track(
          title: 'Test',
          artist: 'Test Artist',
          imageUrl: '',
        );

        expect(track.spotifyUrl, '');
      });
    });

    group('fromJson (Spotify API)', () {
      test('parsea respuesta completa de Spotify', () {
        final json = {
          'name': 'Bohemian Rhapsody',
          'id': 'abc123',
          'artists': [
            {'name': 'Queen'},
            {'name': 'Freddie Mercury'},
          ],
          'album': {
            'images': [
              {'url': 'https://example.com/large.jpg'},
              {'url': 'https://example.com/small.jpg'},
            ],
          },
        };

        final track = Track.fromJson(json);

        expect(track.title, 'Bohemian Rhapsody');
        expect(track.artist, 'Queen');
        expect(track.imageUrl, 'https://example.com/large.jpg');
        expect(track.spotifyUrl, 'https://open.spotify.com/track/abc123');
      });

      test('maneja JSON sin artistas', () {
        final json = {
          'name': 'Track sin artista',
          'id': '123',
          'artists': <dynamic>[],
          'album': {
            'images': [
              {'url': 'https://example.com/img.jpg'}
            ],
          },
        };

        final track = Track.fromJson(json);
        expect(track.artist, 'Artista desconocido');
      });

      test('maneja JSON sin imágenes', () {
        final json = {
          'name': 'Track sin imagen',
          'id': '123',
          'artists': [
            {'name': 'Artista'}
          ],
          'album': {'images': <dynamic>[]},
        };

        final track = Track.fromJson(json);
        expect(track.imageUrl, '');
      });

      test('maneja JSON con campos nulos', () {
        final json = <String, dynamic>{
          'name': null,
          'id': null,
          'artists': null,
          'album': null,
        };

        final track = Track.fromJson(json);
        expect(track.title, 'Sin título');
        expect(track.artist, 'Artista desconocido');
        expect(track.imageUrl, '');
        expect(track.spotifyUrl, '');
      });

      test('maneja JSON completamente vacío', () {
        final track = Track.fromJson(<String, dynamic>{});

        expect(track.title, 'Sin título');
        expect(track.artist, 'Artista desconocido');
        expect(track.imageUrl, '');
        expect(track.spotifyUrl, '');
      });
    });

    group('toMap / fromMap (Firestore)', () {
      test('serialización ida y vuelta conserva datos', () {
        const original = Track(
          title: 'Stairway to Heaven',
          artist: 'Led Zeppelin',
          imageUrl: 'https://example.com/img.jpg',
          spotifyUrl: 'https://open.spotify.com/track/xyz',
        );

        final map = original.toMap();
        final restored = Track.fromMap(map);

        expect(restored.title, original.title);
        expect(restored.artist, original.artist);
        expect(restored.imageUrl, original.imageUrl);
        expect(restored.spotifyUrl, original.spotifyUrl);
      });

      test('toMap genera las claves correctas', () {
        const track = Track(
          title: 'Test',
          artist: 'Test Artist',
          imageUrl: 'url',
          spotifyUrl: 'spotify_url',
        );

        final map = track.toMap();
        expect(map, {
          'title': 'Test',
          'artist': 'Test Artist',
          'imageUrl': 'url',
          'spotifyUrl': 'spotify_url',
        });
      });

      test('fromMap con valores nulos devuelve strings vacíos', () {
        final track = Track.fromMap(<String, dynamic>{});

        expect(track.title, '');
        expect(track.artist, '');
        expect(track.imageUrl, '');
        expect(track.spotifyUrl, '');
      });
    });
  });
}
