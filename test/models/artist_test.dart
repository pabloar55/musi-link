import 'package:flutter_test/flutter_test.dart';
import 'package:musi_link/models/artist.dart';

void main() {
  group('Artist', () {
    group('constructor', () {
      test('crea Artist con todos los campos', () {
        const artist = Artist(
          name: 'Queen',
          imageUrl: 'https://example.com/queen.jpg',
          genres: ['rock', 'classic rock'],
        );

        expect(artist.name, 'Queen');
        expect(artist.imageUrl, 'https://example.com/queen.jpg');
        expect(artist.genres, ['rock', 'classic rock']);
      });
    });

    group('fromJson (Spotify API)', () {
      test('parsea respuesta completa de Spotify', () {
        final json = {
          'name': 'Radiohead',
          'images': [
            {'url': 'https://example.com/large.jpg'},
            {'url': 'https://example.com/medium.jpg'},
          ],
          'genres': ['alternative rock', 'art rock', 'electronic'],
        };

        final artist = Artist.fromJson(json);

        expect(artist.name, 'Radiohead');
        expect(artist.imageUrl, 'https://example.com/large.jpg');
        expect(artist.genres, ['alternative rock', 'art rock', 'electronic']);
      });

      test('maneja JSON sin imágenes', () {
        final json = {
          'name': 'Artista',
          'images': <dynamic>[],
          'genres': ['pop'],
        };

        final artist = Artist.fromJson(json);
        expect(artist.imageUrl, '');
      });

      test('maneja JSON con campos nulos', () {
        final json = <String, dynamic>{
          'name': null,
          'images': null,
          'genres': null,
        };

        final artist = Artist.fromJson(json);
        expect(artist.name, 'Artista desconocido');
        expect(artist.imageUrl, '');
        expect(artist.genres, isEmpty);
      });
    });

    group('toMap / fromMap (Firestore)', () {
      test('toMap genera las claves correctas', () {
        const artist = Artist(
          name: 'Queen',
          imageUrl: 'https://example.com/queen.jpg',
          genres: ['rock'],
        );

        final map = artist.toMap();
        expect(map, {
          'name': 'Queen',
          'imageUrl': 'https://example.com/queen.jpg',
        });
      });

      test('fromMap restaura name e imageUrl', () {
        final artist = Artist.fromMap({
          'name': 'Queen',
          'imageUrl': 'https://example.com/queen.jpg',
        });

        expect(artist.name, 'Queen');
        expect(artist.imageUrl, 'https://example.com/queen.jpg');
        expect(artist.genres, isEmpty);
      });

      test('fromMap con valores nulos devuelve strings vacíos', () {
        final artist = Artist.fromMap(<String, dynamic>{});

        expect(artist.name, '');
        expect(artist.imageUrl, '');
      });
    });
  });
}
