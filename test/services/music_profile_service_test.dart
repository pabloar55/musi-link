// ignore_for_file: avoid_redundant_argument_values
import 'package:flutter_test/flutter_test.dart';
import 'package:musi_link/models/app_user.dart';
import 'package:musi_link/services/music_profile_service.dart';

void main() {
  group('MusicProfileService.calculateCompatibility', () {
    AppUser createUser({
      String uid = 'other',
      List<String> topArtistNames = const [],
      List<String> topGenreNames = const [],
    }) {
      return AppUser(
        uid: uid,
        email: 'test@test.com',
        displayName: 'Test',
        createdAt: DateTime(2025, 1, 1),
        lastLogin: DateTime(2025, 1, 1),
        topArtistNames: topArtistNames,
        topGenreNames: topGenreNames,
      );
    }

    test('sin coincidencias devuelve score 0', () {
      final result = MusicProfileService.calculateCompatibility(
        myArtistNames: ['Queen', 'Radiohead'],
        myGenreNames: ['rock', 'alternative'],
        otherUser: createUser(
          topArtistNames: ['Bad Bunny', 'Shakira'],
          topGenreNames: ['reggaeton', 'pop'],
        ),
      );

      expect(result.score, 0.0);
      expect(result.sharedArtistNames, isEmpty);
      expect(result.sharedGenreNames, isEmpty);
    });

    test('1 artista en común = 14 puntos', () {
      final result = MusicProfileService.calculateCompatibility(
        myArtistNames: ['Queen', 'Radiohead'],
        myGenreNames: [],
        otherUser: createUser(
          topArtistNames: ['Queen', 'Bad Bunny'],
        ),
      );

      expect(result.score, 14.0);
      expect(result.sharedArtistNames, ['Queen']);
    });

    test('1 género en común = 6 puntos', () {
      final result = MusicProfileService.calculateCompatibility(
        myArtistNames: [],
        myGenreNames: ['rock', 'jazz'],
        otherUser: createUser(
          topGenreNames: ['rock', 'reggaeton'],
        ),
      );

      expect(result.score, 6.0);
      expect(result.sharedGenreNames, ['rock']);
    });

    test('3 artistas + 2 géneros = 42 + 12 = 54 puntos', () {
      final result = MusicProfileService.calculateCompatibility(
        myArtistNames: ['Queen', 'Radiohead', 'Muse', 'Coldplay'],
        myGenreNames: ['rock', 'alternative', 'pop'],
        otherUser: createUser(
          topArtistNames: ['Queen', 'Radiohead', 'Muse', 'Bad Bunny'],
          topGenreNames: ['rock', 'alternative', 'reggaeton'],
        ),
      );

      expect(result.score, 54.0);
      expect(result.sharedArtistNames.length, 3);
      expect(result.sharedGenreNames.length, 2);
    });

    test('máximo de artistas (5+) se limita a 70 puntos', () {
      final result = MusicProfileService.calculateCompatibility(
        myArtistNames: ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
        myGenreNames: [],
        otherUser: createUser(
          topArtistNames: ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
        ),
      );

      expect(result.score, 70.0);
    });

    test('máximo de géneros (5+) se limita a 30 puntos', () {
      final result = MusicProfileService.calculateCompatibility(
        myArtistNames: [],
        myGenreNames: ['g1', 'g2', 'g3', 'g4', 'g5', 'g6', 'g7'],
        otherUser: createUser(
          topGenreNames: ['g1', 'g2', 'g3', 'g4', 'g5', 'g6', 'g7'],
        ),
      );

      expect(result.score, 30.0);
    });

    test('compatibilidad máxima (100 puntos) con 5 artistas y 5 géneros', () {
      final result = MusicProfileService.calculateCompatibility(
        myArtistNames: ['A1', 'A2', 'A3', 'A4', 'A5'],
        myGenreNames: ['G1', 'G2', 'G3', 'G4', 'G5'],
        otherUser: createUser(
          topArtistNames: ['A1', 'A2', 'A3', 'A4', 'A5'],
          topGenreNames: ['G1', 'G2', 'G3', 'G4', 'G5'],
        ),
      );

      expect(result.score, 100.0);
    });

    test('el resultado incluye el usuario correcto', () {
      final otherUser = createUser(
        uid: 'other123',
        topArtistNames: ['Queen'],
        topGenreNames: ['rock'],
      );

      final result = MusicProfileService.calculateCompatibility(
        myArtistNames: ['Queen'],
        myGenreNames: ['rock'],
        otherUser: otherUser,
      );

      expect(result.user.uid, 'other123');
    });

    test('listas vacías para ambos usuarios devuelve score 0', () {
      final result = MusicProfileService.calculateCompatibility(
        myArtistNames: [],
        myGenreNames: [],
        otherUser: createUser(),
      );

      expect(result.score, 0.0);
    });
  });
}
