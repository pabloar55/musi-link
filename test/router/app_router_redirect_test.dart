// ignore_for_file: subtype_of_sealed_class
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musi_link/router/app_router.dart';

import '../helpers/mocks.dart';

void main() {
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late StreamController<User?> authStream;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    authStream = StreamController<User?>.broadcast();
    when(() => mockAuth.authStateChanges())
        .thenAnswer((_) => authStream.stream);
  });

  tearDown(() => authStream.close());

  AppRouterNotifier buildNotifier() => AppRouterNotifier(auth: mockAuth);

  // ── Estado 1: app no inicializada ──────────────────────────────

  group('not initialized', () {
    test('cualquier ruta → /splash', () {
      final n = buildNotifier();
      expect(appRedirect(n, '/'), '/splash');
      expect(appRedirect(n, '/auth'), '/splash');
      expect(appRedirect(n, '/main'), '/splash');
      n.dispose();
    });

    test('ya en /splash → sin redirect', () {
      final n = buildNotifier();
      expect(appRedirect(n, '/splash'), isNull);
      n.dispose();
    });
  });

  // ── Estado 2: inicializado, no autenticado ─────────────────────

  group('not logged in', () {
    setUp(() => when(() => mockAuth.currentUser).thenReturn(null));

    test('cualquier ruta → /auth', () {
      final n = buildNotifier()
        ..setInitialized(spotifyConnected: false, onboardingDone: false);
      expect(appRedirect(n, '/'), '/auth');
      expect(appRedirect(n, '/splash'), '/auth');
      n.dispose();
    });

    test('ya en /auth → sin redirect', () {
      final n = buildNotifier()
        ..setInitialized(spotifyConnected: false, onboardingDone: false);
      expect(appRedirect(n, '/auth'), isNull);
      n.dispose();
    });
  });

  // ── Estado 3: autenticado, sin Spotify ────────────────────────

  group('logged in, no Spotify', () {
    setUp(() => when(() => mockAuth.currentUser).thenReturn(mockUser));

    test('cualquier ruta → /spotify-connect', () {
      final n = buildNotifier()
        ..setInitialized(spotifyConnected: false, onboardingDone: false);
      expect(appRedirect(n, '/'), '/spotify-connect');
      expect(appRedirect(n, '/auth'), '/spotify-connect');
      n.dispose();
    });

    test('ya en /spotify-connect → sin redirect', () {
      final n = buildNotifier()
        ..setInitialized(spotifyConnected: false, onboardingDone: false);
      expect(appRedirect(n, '/spotify-connect'), isNull);
      n.dispose();
    });
  });

  // ── Estado 4: Spotify listo, sin onboarding ───────────────────

  group('logged in + Spotify, no onboarding', () {
    setUp(() => when(() => mockAuth.currentUser).thenReturn(mockUser));

    test('cualquier ruta → /onboarding', () {
      final n = buildNotifier()
        ..setInitialized(spotifyConnected: true, onboardingDone: false);
      expect(appRedirect(n, '/'), '/onboarding');
      n.dispose();
    });

    test('ya en /onboarding → sin redirect', () {
      final n = buildNotifier()
        ..setInitialized(spotifyConnected: true, onboardingDone: false);
      expect(appRedirect(n, '/onboarding'), isNull);
      n.dispose();
    });
  });

  // ── Estado 5: usuario completo ────────────────────────────────

  group('fully ready', () {
    setUp(() => when(() => mockAuth.currentUser).thenReturn(mockUser));

    test('pantallas de setup → /', () {
      final n = buildNotifier()
        ..setInitialized(spotifyConnected: true, onboardingDone: true);
      expect(appRedirect(n, '/splash'), '/');
      expect(appRedirect(n, '/auth'), '/');
      expect(appRedirect(n, '/spotify-connect'), '/');
      expect(appRedirect(n, '/onboarding'), '/');
      n.dispose();
    });

    test('pantallas normales → sin redirect', () {
      final n = buildNotifier()
        ..setInitialized(spotifyConnected: true, onboardingDone: true);
      expect(appRedirect(n, '/'), isNull);
      expect(appRedirect(n, '/settings'), isNull);
      expect(appRedirect(n, '/search'), isNull);
      expect(appRedirect(n, '/chat'), isNull);
      n.dispose();
    });
  });

  // ── Transiciones de estado ─────────────────────────────────────

  group('state transitions', () {
    setUp(() => when(() => mockAuth.currentUser).thenReturn(mockUser));

    test('setSpotifyConnected avanza al paso de onboarding', () {
      final n = buildNotifier()
        ..setInitialized(spotifyConnected: false, onboardingDone: false)
        ..setSpotifyConnected(onboardingDone: false);
      expect(appRedirect(n, '/'), '/onboarding');
      n.dispose();
    });

    test('setOnboardingDone avanza a main y desbloquea app', () {
      final n = buildNotifier()
        ..setInitialized(spotifyConnected: true, onboardingDone: false)
        ..setOnboardingDone();
      expect(appRedirect(n, '/onboarding'), '/');
      expect(appRedirect(n, '/'), isNull);
      n.dispose();
    });

    test('sign-out resetea flags de spotify y onboarding', () async {
      final n = buildNotifier()
        ..setInitialized(spotifyConnected: true, onboardingDone: true);

      expect(n.spotifyConnected, isTrue);
      expect(n.onboardingDone, isTrue);

      // El usuario cierra sesión: el stream emite null
      authStream.add(null);
      await Future.microtask(() {});

      expect(n.spotifyConnected, isFalse);
      expect(n.onboardingDone, isFalse);

      // Con currentUser = null, isLoggedIn = false → redirige a /auth
      when(() => mockAuth.currentUser).thenReturn(null);
      expect(appRedirect(n, '/'), '/auth');
      n.dispose();
    });
  });
}
