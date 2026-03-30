// ignore_for_file: avoid_redundant_argument_values, subtype_of_sealed_class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musi_link/models/app_user.dart';
import 'package:musi_link/services/music_profile_service.dart';
import 'package:musi_link/services/spotify_stats_service.dart';

import '../helpers/mocks.dart';

class MockSpotifyGetStats extends Mock implements SpotifyGetStats {}

// ── Helpers ──────────────────────────────────────────────────────────────────

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

MockQueryDocumentSnapshot buildUserDoc(String uid) {
  final doc = MockQueryDocumentSnapshot();
  when(() => doc.id).thenReturn(uid);
  when(() => doc.data()).thenReturn({
    'email': '$uid@test.com',
    'displayName': 'User $uid',
    'photoUrl': '',
    'createdAt': Timestamp.fromDate(DateTime(2025, 1, 1)),
    'lastLogin': Timestamp.fromDate(DateTime(2025, 1, 1)),
    'topArtistNames': ['Artist A', 'Artist B'],
    'topGenreNames': ['rock'],
  });
  return doc;
}

MockQuerySnapshot buildSnapshot(List<MockQueryDocumentSnapshot> docs) {
  final snap = MockQuerySnapshot();
  when(() => snap.docs).thenReturn(docs);
  return snap;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('MusicProfileService.calculateCompatibility', () {
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
        otherUser: createUser(topArtistNames: ['Queen', 'Bad Bunny']),
      );

      expect(result.score, 14.0);
      expect(result.sharedArtistNames, ['Queen']);
    });

    test('1 género en común = 6 puntos', () {
      final result = MusicProfileService.calculateCompatibility(
        myArtistNames: [],
        myGenreNames: ['rock', 'jazz'],
        otherUser: createUser(topGenreNames: ['rock', 'reggaeton']),
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
        otherUser: createUser(topArtistNames: ['A', 'B', 'C', 'D', 'E', 'F', 'G']),
      );

      expect(result.score, 70.0);
    });

    test('máximo de géneros (5+) se limita a 30 puntos', () {
      final result = MusicProfileService.calculateCompatibility(
        myArtistNames: [],
        myGenreNames: ['g1', 'g2', 'g3', 'g4', 'g5', 'g6', 'g7'],
        otherUser: createUser(topGenreNames: ['g1', 'g2', 'g3', 'g4', 'g5', 'g6', 'g7']),
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

  // ── Paginación y caché ───────────────────────────────────────────────────

  group('MusicProfileService discovery (paginación y caché)', () {
    late MockFirebaseFirestore mockFirestore;
    late MockFirebaseAuth mockAuth;
    late MockUser mockCurrentUser;
    late MockCollectionReference mockUsersRef;
    late MockDocumentReference mockMyDocRef;
    late MockDocumentSnapshot mockMyDocSnap;
    late MockQuery mockQuery;
    late MusicProfileService service;

    const myUid = 'me';

    void stubMyUserDoc() {
      when(() => mockUsersRef.doc(myUid)).thenReturn(mockMyDocRef);
      when(() => mockMyDocRef.get()).thenAnswer((_) async => mockMyDocSnap);
      when(() => mockMyDocSnap.exists).thenReturn(true);
      when(() => mockMyDocSnap.id).thenReturn(myUid);
      when(() => mockMyDocSnap.data()).thenReturn({
        'email': 'me@test.com',
        'displayName': 'Me',
        'photoUrl': '',
        'createdAt': Timestamp.fromDate(DateTime(2025, 1, 1)),
        'lastLogin': Timestamp.fromDate(DateTime(2025, 1, 1)),
        'topArtistNames': ['Artist A'],
        'topGenreNames': ['rock'],
      });
    }

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      mockCurrentUser = MockUser();
      mockUsersRef = MockCollectionReference();
      mockMyDocRef = MockDocumentReference();
      mockMyDocSnap = MockDocumentSnapshot();
      mockQuery = MockQuery();

      registerFallbackValues();
      // Necesario para `startAfterDocument(any())`
      registerFallbackValue(MockDocumentSnapshot());

      when(() => mockAuth.currentUser).thenReturn(mockCurrentUser);
      when(() => mockCurrentUser.uid).thenReturn(myUid);
      when(() => mockFirestore.collection(any())).thenReturn(mockUsersRef);

      stubMyUserDoc();

      // Cadena de query sin cursor:
      // _usersRef.orderBy(...).limit(20)
      when(
        () => mockUsersRef.orderBy(
          'musicDataUpdatedAt',
          descending: true,
        ),
      ).thenReturn(mockQuery);
      when(() => mockQuery.limit(any())).thenReturn(mockQuery);

      service = MusicProfileService(
        MockSpotifyGetStats(),
        firestore: mockFirestore,
        auth: mockAuth,
      );
    });

    group('getDiscoveryUsers', () {
      test('Firestore devuelve 20 docs → hasMoreDiscoveryUsers es true', () async {
        final docs = List.generate(20, (i) => buildUserDoc('user$i'));
        when(() => mockQuery.get()).thenAnswer((_) async => buildSnapshot(docs));

        await service.getDiscoveryUsers();

        expect(service.hasMoreDiscoveryUsers, isTrue);
      });

      test('Firestore devuelve < 20 docs → hasMoreDiscoveryUsers es false', () async {
        final docs = List.generate(15, (i) => buildUserDoc('user$i'));
        when(() => mockQuery.get()).thenAnswer((_) async => buildSnapshot(docs));

        await service.getDiscoveryUsers();

        expect(service.hasMoreDiscoveryUsers, isFalse);
      });

      test('excluye al usuario actual de los resultados', () async {
        final docs = [
          buildUserDoc(myUid), // debe ser excluido
          buildUserDoc('other1'),
          buildUserDoc('other2'),
        ];
        when(() => mockQuery.get()).thenAnswer((_) async => buildSnapshot(docs));

        final results = await service.getDiscoveryUsers();

        expect(results.length, 2);
        expect(results.any((r) => r.user.uid == myUid), isFalse);
      });

      test('resultados se ordenan por score descendente', () async {
        // other1: comparte Artist A → 14 pts; other2: sin coincidencia → 0 pts
        final doc1 = MockQueryDocumentSnapshot();
        when(() => doc1.id).thenReturn('other1');
        when(() => doc1.data()).thenReturn({
          'email': 'other1@test.com',
          'displayName': 'Other 1',
          'photoUrl': '',
          'createdAt': Timestamp.fromDate(DateTime(2025, 1, 1)),
          'lastLogin': Timestamp.fromDate(DateTime(2025, 1, 1)),
          'topArtistNames': ['Artist A'], // coincide con myUser
          'topGenreNames': <String>[],
        });

        final doc2 = MockQueryDocumentSnapshot();
        when(() => doc2.id).thenReturn('other2');
        when(() => doc2.data()).thenReturn({
          'email': 'other2@test.com',
          'displayName': 'Other 2',
          'photoUrl': '',
          'createdAt': Timestamp.fromDate(DateTime(2025, 1, 1)),
          'lastLogin': Timestamp.fromDate(DateTime(2025, 1, 1)),
          'topArtistNames': ['Unknown Artist'],
          'topGenreNames': <String>[],
        });

        // Devuelve doc2 primero (menor score), doc1 segundo
        when(() => mockQuery.get()).thenAnswer(
          (_) async => buildSnapshot([doc2, doc1]),
        );

        final results = await service.getDiscoveryUsers();

        // Debe estar ordenado: other1 (14 pts) antes que other2 (0 pts)
        expect(results.first.user.uid, 'other1');
        expect(results.last.user.uid, 'other2');
      });

      test('segunda llamada sin forceRefresh sirve caché sin consultar Firestore', () async {
        final docs = List.generate(5, (i) => buildUserDoc('user$i'));
        when(() => mockQuery.get()).thenAnswer((_) async => buildSnapshot(docs));

        await service.getDiscoveryUsers();
        await service.getDiscoveryUsers(); // debe usar caché

        verify(() => mockQuery.get()).called(1);
      });

      test('forceRefresh invalida caché y vuelve a consultar Firestore', () async {
        final docs = List.generate(5, (i) => buildUserDoc('user$i'));
        when(() => mockQuery.get()).thenAnswer((_) async => buildSnapshot(docs));

        await service.getDiscoveryUsers(forceRefresh: true);
        await service.getDiscoveryUsers(forceRefresh: true);

        verify(() => mockQuery.get()).called(2);
      });
    });

    group('loadMoreDiscoveryUsers', () {
      test('sin carga previa devuelve lista vacía sin llamar a Firestore', () async {
        final (results, hasMore) = await service.loadMoreDiscoveryUsers();

        expect(results, isEmpty);
        expect(hasMore, isFalse);
        verifyNever(() => mockQuery.get());
      });

      test('si hasMoreDiscoveryUsers es false no llama a Firestore', () async {
        // Primera carga: 5 docs → hasMore = false
        final docs = List.generate(5, (i) => buildUserDoc('user$i'));
        when(() => mockQuery.get()).thenAnswer((_) async => buildSnapshot(docs));
        await service.getDiscoveryUsers();

        // loadMore no debe hacer nueva consulta
        await service.loadMoreDiscoveryUsers();

        verify(() => mockQuery.get()).called(1); // solo la primera carga
      });

      test('carga la segunda página usando startAfterDocument', () async {
        // Página 1: 20 docs (activa el cursor)
        final page1Docs = List.generate(20, (i) => buildUserDoc('user$i'));
        when(() => mockQuery.get()).thenAnswer((_) async => buildSnapshot(page1Docs));
        await service.getDiscoveryUsers();
        expect(service.hasMoreDiscoveryUsers, isTrue);

        // Stub del cursor: .startAfterDocument(lastDoc) devuelve mockQueryPage2
        final mockQueryPage2 = MockQuery();
        when(() => mockQuery.startAfterDocument(any())).thenReturn(mockQueryPage2);

        // Página 2: 5 docs
        final page2Docs = List.generate(5, (i) => buildUserDoc('page2user$i'));
        when(() => mockQueryPage2.get()).thenAnswer((_) async => buildSnapshot(page2Docs));

        final (allResults, hasMore) = await service.loadMoreDiscoveryUsers();

        expect(allResults.length, 25); // 20 (pág 1) + 5 (pág 2)
        expect(hasMore, isFalse); // 5 < 20
        verify(() => mockQuery.startAfterDocument(any())).called(1);
      });

      test('segunda página con 20 docs mantiene hasMore en true', () async {
        // Página 1: 20 docs
        final page1Docs = List.generate(20, (i) => buildUserDoc('user$i'));
        when(() => mockQuery.get()).thenAnswer((_) async => buildSnapshot(page1Docs));
        await service.getDiscoveryUsers();

        final mockQueryPage2 = MockQuery();
        when(() => mockQuery.startAfterDocument(any())).thenReturn(mockQueryPage2);

        // Página 2: también 20 docs
        final page2Docs = List.generate(20, (i) => buildUserDoc('page2user$i'));
        when(() => mockQueryPage2.get()).thenAnswer((_) async => buildSnapshot(page2Docs));

        final (_, hasMore) = await service.loadMoreDiscoveryUsers();

        expect(hasMore, isTrue);
      });
    });
  });
}
