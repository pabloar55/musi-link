import 'package:flutter_test/flutter_test.dart';
import 'package:musi_link/models/app_user.dart';
import 'package:musi_link/models/artist.dart';
import 'package:musi_link/models/genre.dart';
import 'package:musi_link/models/track.dart';

void main() {
  group('AppUser', () {
    final now = DateTime(2025, 6, 15, 10, 0);

    AppUser createTestUser({
      String uid = 'uid1',
      String email = 'test@example.com',
      String displayName = 'Test User',
      String photoUrl = '',
      String? spotifyId,
      List<Artist> topArtists = const [],
      List<Genre> topGenres = const [],
      List<String> topArtistNames = const [],
      List<String> topGenreNames = const [],
      List<String> friends = const [],
      Track? dailySong,
      Track? nowPlaying,
    }) {
      return AppUser(
        uid: uid,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        spotifyId: spotifyId,
        createdAt: now,
        lastLogin: now,
        topArtists: topArtists,
        topGenres: topGenres,
        topArtistNames: topArtistNames,
        topGenreNames: topGenreNames,
        friends: friends,
        dailySong: dailySong,
        nowPlaying: nowPlaying,
      );
    }

    group('constructor', () {
      test('crea AppUser con campos requeridos y valores por defecto', () {
        final user = AppUser(
          uid: 'uid1',
          email: 'test@example.com',
          displayName: 'Test User',
          createdAt: now,
          lastLogin: now,
        );

        expect(user.uid, 'uid1');
        expect(user.email, 'test@example.com');
        expect(user.displayName, 'Test User');
        expect(user.photoUrl, '');
        expect(user.spotifyId, isNull);
        expect(user.topArtists, isEmpty);
        expect(user.topGenres, isEmpty);
        expect(user.topArtistNames, isEmpty);
        expect(user.topGenreNames, isEmpty);
        expect(user.friends, isEmpty);
        expect(user.dailySong, isNull);
        expect(user.nowPlaying, isNull);
      });
    });

    group('toFirestore', () {
      test('serializa los campos básicos', () {
        final user = createTestUser(
          displayName: 'Pablo García',
          spotifyId: 'spotify123',
        );

        final map = user.toFirestore();

        expect(map['email'], 'test@example.com');
        expect(map['displayName'], 'Pablo García');
        expect(map['displayNameLower'], 'pablo garcía');
        expect(map['spotifyId'], 'spotify123');
        expect(map.containsKey('uid'), false);
      });

      test('displayNameLower se genera en minúsculas', () {
        final user = createTestUser(displayName: 'Juan PÉREZ');
        final map = user.toFirestore();

        expect(map['displayNameLower'], 'juan pérez');
      });
    });

    group('copyWith', () {
      test('actualiza displayName manteniendo otros campos', () {
        final original = createTestUser(displayName: 'Original');
        final updated = original.copyWith(displayName: 'Nuevo Nombre');

        expect(updated.displayName, 'Nuevo Nombre');
        expect(updated.uid, original.uid);
        expect(updated.email, original.email);
        expect(updated.createdAt, original.createdAt);
      });

      test('actualiza spotifyId', () {
        final original = createTestUser();
        final updated = original.copyWith(spotifyId: 'spotify456');

        expect(updated.spotifyId, 'spotify456');
      });

      test('actualiza listas de artistas y géneros', () {
        final original = createTestUser();
        final updated = original.copyWith(
          topArtistNames: ['Queen', 'Radiohead'],
          topGenreNames: ['rock', 'alternative'],
        );

        expect(updated.topArtistNames, ['Queen', 'Radiohead']);
        expect(updated.topGenreNames, ['rock', 'alternative']);
        expect(original.topArtistNames, isEmpty);
      });

      test('actualiza friends', () {
        final original = createTestUser();
        final updated = original.copyWith(friends: ['friend1', 'friend2']);

        expect(updated.friends, ['friend1', 'friend2']);
        expect(original.friends, isEmpty);
      });

      test('actualiza dailySong', () {
        final original = createTestUser();
        const track = Track(
          title: 'New Song',
          artist: 'New Artist',
          imageUrl: 'url',
        );
        final updated = original.copyWith(dailySong: track);

        expect(updated.dailySong, isNotNull);
        expect(updated.dailySong!.title, 'New Song');
        expect(original.dailySong, isNull);
      });

      test('actualiza nowPlaying', () {
        final original = createTestUser();
        const track = Track(
          title: 'Playing Now',
          artist: 'Current Artist',
          imageUrl: 'url',
        );
        final updated = original.copyWith(nowPlaying: track);

        expect(updated.nowPlaying, isNotNull);
        expect(updated.nowPlaying!.title, 'Playing Now');
      });

      test('mantiene todos los campos si no se pasan parámetros', () {
        final original = createTestUser(
          displayName: 'Keep This',
          spotifyId: 'keep_spotify',
          topArtistNames: ['Keep Artist'],
          friends: ['keep_friend'],
        );

        final copy = original.copyWith();

        expect(copy.displayName, original.displayName);
        expect(copy.spotifyId, original.spotifyId);
        expect(copy.topArtistNames, original.topArtistNames);
        expect(copy.friends, original.friends);
      });
    });
  });
}
