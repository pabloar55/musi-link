import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musi_link/models/artist.dart';
import 'package:musi_link/widgets/artist_tile.dart';

void main() {
  group('ArtistTile', () {
    testWidgets('muestra nombre del artista', (tester) async {
      const artist = Artist(
        name: 'Radiohead',
        imageUrl: '',
        genres: ['alternative rock'],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArtistTile(artist: artist),
          ),
        ),
      );

      expect(find.text('Radiohead'), findsOneWidget);
    });

    testWidgets('muestra icono cuando imageUrl está vacío', (tester) async {
      const artist = Artist(
        name: 'Test Artist',
        imageUrl: '',
        genres: [],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArtistTile(artist: artist),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

  });
}
