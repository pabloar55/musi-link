import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musi_link/models/app_user.dart';
import 'package:musi_link/models/discovery_result.dart';
import 'package:musi_link/widgets/user_discovery_card.dart';

void main() {
  group('UserDiscoveryCard', () {
    testWidgets('no falla con mas de cinco artistas compartidos', (
      tester,
    ) async {
      const result = DiscoveryResult(
        user: AppUser(
          uid: 'user-1',
          displayName: 'Test User',
          topArtistNames: [
            'Artist 1',
            'Artist 2',
            'Artist 3',
            'Artist 4',
            'Artist 5',
            'Artist 6',
          ],
        ),
        score: 92,
        sharedArtistNames: [
          'Artist 1',
          'Artist 2',
          'Artist 3',
          'Artist 4',
          'Artist 5',
          'Artist 6',
        ],
        sharedGenreNames: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserDiscoveryCard(result: result, onTap: () {}),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Test User'), findsOneWidget);
    });
  });
}
