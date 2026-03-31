import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musi_link/models/genre.dart';
import 'package:musi_link/widgets/genre_tile.dart';

void main() {
  group('GenreTile', () {
    testWidgets('muestra nombre del género y ranking', (tester) async {
      const genre = Genre(name: 'rock', count: 10, percentage: 45.5);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GenreTile(genre: genre, rank: 1),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('rock'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
    });

    testWidgets('muestra porcentaje formateado', (tester) async {
      const genre = Genre(name: 'pop', count: 5, percentage: 33.3);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GenreTile(genre: genre, rank: 2),
          ),
        ),
      );
      
      await tester.pump(const Duration(milliseconds: 100));
  
      await tester.pumpAndSettle();

      expect(find.text('33.3%'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
    });

    testWidgets('muestra LinearProgressIndicator', (tester) async {
      const genre = Genre(name: 'jazz', count: 3, percentage: 20.0);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GenreTile(genre: genre, rank: 3),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 150));

      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('porcentaje 0 muestra 0.0%', (tester) async {
      const genre = Genre(name: 'blues', count: 0, percentage: 0.0);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GenreTile(genre: genre, rank: 5),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 250));

      await tester.pumpAndSettle();
      
      expect(find.text('0.0%'), findsOneWidget);
    });
  });
}
