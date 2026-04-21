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
        ..setInitialized(
            artistsSelected: false,
            onboardingDone: false,
            photoSetupDone: false);
      expect(appRedirect(n, '/'), '/auth');
      expect(appRedirect(n, '/splash'), '/auth');
      n.dispose();
    });

    test('ya en /auth → sin redirect', () {
      final n = buildNotifier()
        ..setInitialized(
            artistsSelected: false,
            onboardingDone: false,
            photoSetupDone: false);
      expect(appRedirect(n, '/auth'), isNull);
      n.dispose();
    });
  });

  // ── Estado 3: autenticado, sin artistas ───────────────────────

  group('logged in, no artists selected', () {
    setUp(() => when(() => mockAuth.currentUser).thenReturn(mockUser));

    test('cualquier ruta → /artist-select', () {
      final n = buildNotifier()
        ..setInitialized(
            artistsSelected: false,
            onboardingDone: false,
            photoSetupDone: false);
      expect(appRedirect(n, '/'), '/artist-select');
      expect(appRedirect(n, '/auth'), '/artist-select');
      n.dispose();
    });

    test('ya en /artist-select → sin redirect', () {
      final n = buildNotifier()
        ..setInitialized(
            artistsSelected: false,
            onboardingDone: false,
            photoSetupDone: false);
      expect(appRedirect(n, '/artist-select'), isNull);
      n.dispose();
    });
  });

  // ── Estado 4: artistas seleccionados, sin onboarding ──────────

  group('logged in + artists, no onboarding', () {
    setUp(() => when(() => mockAuth.currentUser).thenReturn(mockUser));

    test('cualquier ruta → /onboarding', () {
      final n = buildNotifier()
        ..setInitialized(
            artistsSelected: true,
            onboardingDone: false,
            photoSetupDone: false);
      expect(appRedirect(n, '/'), '/onboarding');
      n.dispose();
    });

    test('ya en /onboarding → sin redirect', () {
      final n = buildNotifier()
        ..setInitialized(
            artistsSelected: true,
            onboardingDone: false,
            photoSetupDone: false);
      expect(appRedirect(n, '/onboarding'), isNull);
      n.dispose();
    });
  });

  // ── Estado 5: onboarding completado, sin foto de perfil ────────

  group('logged in + onboarding done, no photo setup', () {
    setUp(() => when(() => mockAuth.currentUser).thenReturn(mockUser));

    test('cualquier ruta → /photo-setup', () {
      final n = buildNotifier()
        ..setInitialized(
            artistsSelected: true,
            onboardingDone: true,
            photoSetupDone: false);
      expect(appRedirect(n, '/'), '/photo-setup');
      n.dispose();
    });

    test('ya en /photo-setup → sin redirect', () {
      final n = buildNotifier()
        ..setInitialized(
            artistsSelected: true,
            onboardingDone: true,
            photoSetupDone: false);
      expect(appRedirect(n, '/photo-setup'), isNull);
      n.dispose();
    });
  });

  // ── Estado 6: usuario completo ────────────────────────────────

  group('fully ready', () {
    setUp(() => when(() => mockAuth.currentUser).thenReturn(mockUser));

    test('pantallas de setup → /', () {
      final n = buildNotifier()
        ..setInitialized(
            artistsSelected: true,
            onboardingDone: true,
            photoSetupDone: true);
      expect(appRedirect(n, '/splash'), '/');
      expect(appRedirect(n, '/auth'), '/');
      expect(appRedirect(n, '/artist-select'), '/');
      expect(appRedirect(n, '/onboarding'), '/');
      expect(appRedirect(n, '/photo-setup'), '/');
      n.dispose();
    });

    test('pantallas normales → sin redirect', () {
      final n = buildNotifier()
        ..setInitialized(
            artistsSelected: true,
            onboardingDone: true,
            photoSetupDone: true);
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

    test('setArtistsSelected avanza al paso de onboarding', () {
      final n = buildNotifier()
        ..setInitialized(
            artistsSelected: false,
            onboardingDone: false,
            photoSetupDone: false)
        ..setArtistsSelected(onboardingDone: false);
      expect(appRedirect(n, '/'), '/onboarding');
      n.dispose();
    });

    test('setOnboardingDone avanza a /photo-setup', () {
      final n = buildNotifier()
        ..setInitialized(
            artistsSelected: true,
            onboardingDone: false,
            photoSetupDone: false)
        ..setOnboardingDone();
      expect(appRedirect(n, '/onboarding'), '/photo-setup');
      expect(appRedirect(n, '/photo-setup'), isNull);
      n.dispose();
    });

    test('setPhotoSetupDone avanza a main y desbloquea app', () {
      final n = buildNotifier()
        ..setInitialized(
            artistsSelected: true,
            onboardingDone: true,
            photoSetupDone: false)
        ..setPhotoSetupDone();
      expect(appRedirect(n, '/photo-setup'), '/');
      expect(appRedirect(n, '/'), isNull);
      n.dispose();
    });

    test('sign-out resetea todos los flags de setup', () async {
      final n = buildNotifier()
        ..setInitialized(
            artistsSelected: true,
            onboardingDone: true,
            photoSetupDone: true);

      expect(n.artistsSelected, isTrue);
      expect(n.onboardingDone, isTrue);
      expect(n.photoSetupDone, isTrue);

      authStream.add(null);
      await Future.microtask(() {});

      expect(n.artistsSelected, isFalse);
      expect(n.onboardingDone, isFalse);
      expect(n.photoSetupDone, isFalse);

      when(() => mockAuth.currentUser).thenReturn(null);
      expect(appRedirect(n, '/'), '/auth');
      n.dispose();
    });
  });
}
