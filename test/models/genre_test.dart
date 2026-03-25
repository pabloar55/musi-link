import 'package:flutter_test/flutter_test.dart';
import 'package:musi_link/models/genre.dart';

void main() {
  group('Genre', () {
    group('constructor', () {
      test('crea Genre con todos los campos', () {
        const genre = Genre(name: 'rock', count: 10, percentage: 25.5);

        expect(genre.name, 'rock');
        expect(genre.count, 10);
        expect(genre.percentage, 25.5);
      });
    });

    group('toMap / fromMap', () {
      test('toMap genera las claves correctas', () {
        const genre = Genre(name: 'pop', count: 5, percentage: 33.3);

        final map = genre.toMap();
        expect(map, {'name': 'pop', 'percentage': 33.3});
      });

      test('fromMap restaura name y percentage', () {
        final genre = Genre.fromMap({
          'name': 'electronic',
          'percentage': 15.7,
        });

        expect(genre.name, 'electronic');
        expect(genre.percentage, 15.7);
        expect(genre.count, 0);
      });

      test('fromMap con valores nulos', () {
        final genre = Genre.fromMap(<String, dynamic>{});

        expect(genre.name, '');
        expect(genre.count, 0);
        expect(genre.percentage, 0.0);
      });

      test('fromMap acepta percentage como int', () {
        final genre = Genre.fromMap({
          'name': 'jazz',
          'percentage': 42,
        });

        expect(genre.percentage, 42.0);
      });

      test('serialización ida y vuelta conserva datos', () {
        const original = Genre(name: 'indie', count: 8, percentage: 20.0);

        final map = original.toMap();
        final restored = Genre.fromMap(map);

        expect(restored.name, original.name);
        expect(restored.percentage, original.percentage);
      });
    });
  });
}
