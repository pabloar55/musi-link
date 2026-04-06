import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musi_link/models/track.dart' as app;
import 'package:musi_link/services/spotify_service.dart';

import '../helpers/mocks.dart';

void main() {
  late MockFirebaseAuth mockAuth;
  late MockUserService mockUserService;
  late SpotifyService service;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockUserService = MockUserService();
    service = SpotifyService(
      userService: mockUserService,
      auth: mockAuth,
    );
  });

  group('SpotifyService', () {
    group('estado inicial', () {
      test('isInitialized es false antes de conectar', () {
        expect(service.isInitialized, isFalse);
      });

      test('api lanza StateError si no está inicializado', () {
        expect(() => service.api, throwsA(isA<StateError>()));
      });
    });

    group('getCurrentlyPlayingTrack', () {
      test('retorna null cuando _api es null', () async {
        final result = await service.getCurrentlyPlayingTrack();
        expect(result, isNull);
      });
    });

    group('fórmula de backoff', () {
      // _intervalIdle = 60 s; techo = 8 min = 480 s
      // ms = 60000 * (1 << errors.clamp(0,8)); capped a 480 000 ms

      test('0 errores → intervalo idle (60 s)', () {
        expect(service.backoffForErrors(0), const Duration(seconds: 60));
      });

      test('1 error → 120 s (duplica el intervalo)', () {
        expect(service.backoffForErrors(1), const Duration(seconds: 120));
      });

      test('3 errores → 480 s (justo en el techo de 8 min)', () {
        // 60 000 * 2^3 = 480 000 ms == _maxBackoff → no supera → devuelve exactamente 8 min
        expect(service.backoffForErrors(3), const Duration(minutes: 8));
      });

      test('errores altos → techo en 8 minutos', () {
        expect(service.backoffForErrors(10), const Duration(minutes: 8));
      });
    });

    group('disconnect', () {
      test('llama updateNowPlaying(uid, null) cuando hay usuario autenticado',
          () async {
        final mockUser = MockUser();
        when(() => mockUser.uid).thenReturn('uid_test');
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockUserService.updateNowPlaying(any(), any<app.Track?>()))
            .thenAnswer((_) async {});

        await service.disconnect();

        verify(() => mockUserService.updateNowPlaying('uid_test', null))
            .called(1);
      });

      test('no llama updateNowPlaying si no hay usuario autenticado', () async {
        when(() => mockAuth.currentUser).thenReturn(null);

        await service.disconnect();

        verifyNever(() => mockUserService.updateNowPlaying(any(), any()));
      });
    });
  });
}
