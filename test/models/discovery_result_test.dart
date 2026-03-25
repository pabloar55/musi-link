import 'package:flutter_test/flutter_test.dart';
import 'package:musi_link/models/app_user.dart';
import 'package:musi_link/models/discovery_result.dart';

void main() {
  group('DiscoveryResult', () {
    final testUser = AppUser(
      uid: 'uid1',
      email: 'test@test.com',
      displayName: 'Test',
      createdAt: DateTime(2025, 1, 1),
      lastLogin: DateTime(2025, 1, 1),
    );

    test('crea DiscoveryResult con todos los campos', () {
      final result = DiscoveryResult(
        user: testUser,
        score: 85.0,
        sharedArtistNames: ['Queen', 'Radiohead'],
        sharedGenreNames: ['rock'],
      );

      expect(result.user.uid, 'uid1');
      expect(result.score, 85.0);
      expect(result.sharedArtistNames, ['Queen', 'Radiohead']);
      expect(result.sharedGenreNames, ['rock']);
    });

    test('score puede ser 0', () {
      final result = DiscoveryResult(
        user: testUser,
        score: 0,
        sharedArtistNames: [],
        sharedGenreNames: [],
      );

      expect(result.score, 0);
      expect(result.sharedArtistNames, isEmpty);
      expect(result.sharedGenreNames, isEmpty);
    });

    test('score puede ser 100', () {
      final result = DiscoveryResult(
        user: testUser,
        score: 100,
        sharedArtistNames: ['A', 'B', 'C', 'D', 'E'],
        sharedGenreNames: ['g1', 'g2', 'g3', 'g4', 'g5'],
      );

      expect(result.score, 100);
    });
  });
}
