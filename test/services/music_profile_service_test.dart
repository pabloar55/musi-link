// ignore_for_file: avoid_redundant_argument_values, subtype_of_sealed_class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musi_link/models/app_user.dart';
import 'package:musi_link/services/music_profile_service.dart';
import 'package:musi_link/services/music_catalog_service.dart';

import '../helpers/mocks.dart';

class MockMusicCatalogService extends Mock implements MusicCatalogService {}

AppUser createUser({
  String uid = 'other',
  List<String> topArtistNames = const [],
  List<String> topGenreNames = const [],
}) {
  return AppUser(
    uid: uid,
    displayName: 'Test',
    topArtistNames: topArtistNames,
    topGenreNames: topGenreNames,
  );
}

MockQueryDocumentSnapshot buildUserDoc(
  String uid, {
  List<String> topArtistNames = const ['Artist A', 'Artist B'],
  List<String> topGenreNames = const ['rock'],
}) {
  final doc = MockQueryDocumentSnapshot();
  when(() => doc.id).thenReturn(uid);
  when(() => doc.data()).thenReturn({
    'email': '$uid@test.com',
    'displayName': 'User $uid',
    'photoUrl': '',
    'createdAt': Timestamp.fromDate(DateTime(2025, 1, 1)),
    'lastLogin': Timestamp.fromDate(DateTime(2025, 1, 1)),
    'topArtistNames': topArtistNames,
    'topGenreNames': topGenreNames,
  });
  return doc;
}

MockQueryDocumentSnapshot buildRecommendationDoc(
  String uid, {
  double score = 42,
  List<String> sharedArtistNames = const ['Artist A'],
  List<String> sharedGenreNames = const ['rock'],
}) {
  final doc = MockQueryDocumentSnapshot();
  when(() => doc.id).thenReturn(uid);
  when(() => doc.data()).thenReturn({
    'userId': uid,
    'score': score,
    'sharedArtistNames': sharedArtistNames,
    'sharedGenreNames': sharedGenreNames,
  });
  return doc;
}

MockQuerySnapshot buildSnapshot(List<MockQueryDocumentSnapshot> docs) {
  final snap = MockQuerySnapshot();
  when(() => snap.docs).thenReturn(docs);
  return snap;
}

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

    test('1 de 2 artistas en comun = 35 puntos', () {
      final result = MusicProfileService.calculateCompatibility(
        myArtistNames: ['Queen', 'Radiohead'],
        myGenreNames: [],
        otherUser: createUser(topArtistNames: ['Queen', 'Bad Bunny']),
      );

      expect(result.score, 35.0);
      expect(result.sharedArtistNames, ['Queen']);
    });

    test('1 de 2 generos en comun = 15 puntos', () {
      final result = MusicProfileService.calculateCompatibility(
        myArtistNames: [],
        myGenreNames: ['rock', 'jazz'],
        otherUser: createUser(topGenreNames: ['rock', 'reggaeton']),
      );

      expect(result.score, 15.0);
      expect(result.sharedGenreNames, ['rock']);
    });

    test('3 de 4 artistas + 2 de 3 generos = 73 puntos', () {
      final result = MusicProfileService.calculateCompatibility(
        myArtistNames: ['Queen', 'Radiohead', 'Muse', 'Coldplay'],
        myGenreNames: ['rock', 'alternative', 'pop'],
        otherUser: createUser(
          topArtistNames: ['Queen', 'Radiohead', 'Muse', 'Bad Bunny'],
          topGenreNames: ['rock', 'alternative', 'reggaeton'],
        ),
      );

      expect(result.score, 73.0);
      expect(result.sharedArtistNames.length, 3);
      expect(result.sharedGenreNames.length, 2);
    });

    test('5 artistas compartidos en perfiles grandes puntuan alto', () {
      final result = MusicProfileService.calculateCompatibility(
        myArtistNames: [
          'A1',
          'A2',
          'A3',
          'A4',
          'A5',
          'A6',
          'A7',
          'A8',
          'A9',
          'A10',
          'A11',
          'A12',
          'A13',
          'A14',
          'A15',
        ],
        myGenreNames: [],
        otherUser: createUser(
          topArtistNames: [
            'A1',
            'A2',
            'A3',
            'A4',
            'A5',
            'B6',
            'B7',
            'B8',
            'B9',
            'B10',
            'B11',
            'B12',
            'B13',
            'B14',
            'B15',
          ],
        ),
      );

      expect(result.score, 50.0);
      expect(result.sharedArtistNames, ['A1', 'A2', 'A3', 'A4', 'A5']);
    });

    test('5 artistas y 2 generos compartidos dan compatibilidad solida', () {
      final result = MusicProfileService.calculateCompatibility(
        myArtistNames: [
          'A1',
          'A2',
          'A3',
          'A4',
          'A5',
          'A6',
          'A7',
          'A8',
          'A9',
          'A10',
          'A11',
          'A12',
          'A13',
          'A14',
          'A15',
        ],
        myGenreNames: [
          'rock',
          'pop',
          'jazz',
          'metal',
          'folk',
          'indie',
          'soul',
          'punk',
        ],
        otherUser: createUser(
          topArtistNames: [
            'A1',
            'A2',
            'A3',
            'A4',
            'A5',
            'B6',
            'B7',
            'B8',
            'B9',
            'B10',
            'B11',
            'B12',
            'B13',
            'B14',
            'B15',
          ],
          topGenreNames: [
            'rock',
            'pop',
            'classical',
            'electronic',
            'hip hop',
            'latin',
            'blues',
            'ambient',
          ],
        ),
      );

      expect(result.score, 65.0);
    });

    test('todos los artistas en comun aportan 70 puntos', () {
      final result = MusicProfileService.calculateCompatibility(
        myArtistNames: ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
        myGenreNames: [],
        otherUser: createUser(
          topArtistNames: ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
        ),
      );

      expect(result.score, 70.0);
    });

    test('todos los generos en comun aportan 30 puntos', () {
      final result = MusicProfileService.calculateCompatibility(
        myArtistNames: [],
        myGenreNames: ['g1', 'g2', 'g3', 'g4', 'g5', 'g6', 'g7'],
        otherUser: createUser(
          topGenreNames: ['g1', 'g2', 'g3', 'g4', 'g5', 'g6', 'g7'],
        ),
      );

      expect(result.score, 30.0);
    });

    test('compatibilidad maxima (100 puntos) con 5 artistas y 5 generos', () {
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

    test(
      '3 artistas y 1 genero identicos en perfiles pequenos = 100 puntos',
      () {
        final result = MusicProfileService.calculateCompatibility(
          myArtistNames: ['A1', 'A2', 'A3'],
          myGenreNames: ['rock'],
          otherUser: createUser(
            topArtistNames: ['A1', 'A2', 'A3'],
            topGenreNames: ['rock'],
          ),
        );

        expect(result.score, 100.0);
      },
    );

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

    test('listas vacias para ambos usuarios devuelve score 0', () {
      final result = MusicProfileService.calculateCompatibility(
        myArtistNames: [],
        myGenreNames: [],
        otherUser: createUser(),
      );

      expect(result.score, 0.0);
    });

    test('normaliza mayusculas, espacios y duplicados al comparar', () {
      final result = MusicProfileService.calculateCompatibility(
        myArtistNames: [' Radiohead ', 'RADIOHEAD', 'Queen'],
        myGenreNames: [' Rock ', 'rock', 'jazz'],
        otherUser: createUser(
          topArtistNames: ['radiohead', 'queen', 'Muse'],
          topGenreNames: ['rock', 'pop'],
        ),
      );

      expect(result.score, 85.0);
      expect(result.sharedArtistNames, ['radiohead', 'queen']);
      expect(result.sharedGenreNames, ['rock']);
    });

    test('normaliza aliases de generos e ignora tags ruidosos al comparar', () {
      final result = MusicProfileService.calculateCompatibility(
        myArtistNames: [],
        myGenreNames: ['Hip-Hop', 'Canadian', 'seen live', 'R&B'],
        otherUser: createUser(
          topGenreNames: ['rap', 'rhythm and blues', '80s'],
        ),
      );

      expect(result.score, 30.0);
      expect(result.sharedGenreNames, ['hip hop', 'r&b']);
    });
  });

  group('MusicProfileService discovery (backend recommendations)', () {
    late MockFirebaseFirestore mockFirestore;
    late MockFirebaseAuth mockAuth;
    late MockUser mockCurrentUser;
    late MockCollectionReference mockUsersRef;
    late MockCollectionReference mockRecommendationsRef;
    late MockDocumentReference mockMyDocRef;
    late MockDocumentSnapshot mockMyDocSnap;
    late MockQuery mockRecommendationOrderQuery;
    late MockQuery mockRecommendationLimitQuery;
    late MockQuery mockUsersByIdQuery;
    late MusicProfileService service;

    const myUid = 'me';

    void stubMyUserDoc({
      List<String> topArtistNames = const ['Artist A'],
      List<String> topGenreNames = const ['rock'],
    }) {
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
        'topArtistNames': topArtistNames,
        'topGenreNames': topGenreNames,
      });
    }

    void stubStoredRecommendations({
      required List<MockQueryDocumentSnapshot> recommendationDocs,
      required List<MockQueryDocumentSnapshot> userDocs,
    }) {
      when(
        () => mockRecommendationLimitQuery.get(),
      ).thenAnswer((_) async => buildSnapshot(recommendationDocs));
      when(
        () => mockUsersByIdQuery.get(),
      ).thenAnswer((_) async => buildSnapshot(userDocs));
    }

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      mockCurrentUser = MockUser();
      mockUsersRef = MockCollectionReference();
      mockRecommendationsRef = MockCollectionReference();
      mockMyDocRef = MockDocumentReference();
      mockMyDocSnap = MockDocumentSnapshot();
      mockRecommendationOrderQuery = MockQuery();
      mockRecommendationLimitQuery = MockQuery();
      mockUsersByIdQuery = MockQuery();

      registerFallbackValues();
      registerFallbackValue(<Object?>[]);

      when(() => mockAuth.currentUser).thenReturn(mockCurrentUser);
      when(() => mockCurrentUser.uid).thenReturn(myUid);
      when(() => mockFirestore.collection(any())).thenReturn(mockUsersRef);

      stubMyUserDoc();
      when(() => mockMyDocRef.update(any())).thenAnswer((_) async {});

      when(
        () => mockMyDocRef.collection('recommendations'),
      ).thenReturn(mockRecommendationsRef);
      when(
        () => mockRecommendationsRef.orderBy('score', descending: true),
      ).thenReturn(mockRecommendationOrderQuery);
      when(
        () => mockRecommendationOrderQuery.limit(any()),
      ).thenReturn(mockRecommendationLimitQuery);
      when(
        () => mockUsersRef.where(any(), whereIn: any(named: 'whereIn')),
      ).thenReturn(mockUsersByIdQuery);

      service = MusicProfileService(
        MockMusicCatalogService(),
        firestore: mockFirestore,
        auth: mockAuth,
      );
    });

    group('getDiscoveryUsers', () {
      test(
        'more than 20 stored recommendations sets hasMoreDiscoveryUsers true',
        () async {
          final recommendations = List.generate(
            25,
            (i) => buildRecommendationDoc('user$i', score: 100 - i.toDouble()),
          );
          final users = List.generate(25, (i) => buildUserDoc('user$i'));
          stubStoredRecommendations(
            recommendationDocs: recommendations,
            userDocs: users,
          );

          final results = await service.getDiscoveryUsers();

          expect(results.length, 20);
          expect(service.hasMoreDiscoveryUsers, isTrue);
        },
      );

      test(
        'less than 20 stored recommendations sets hasMoreDiscoveryUsers false',
        () async {
          final recommendations = List.generate(
            15,
            (i) => buildRecommendationDoc('user$i'),
          );
          final users = List.generate(15, (i) => buildUserDoc('user$i'));
          stubStoredRecommendations(
            recommendationDocs: recommendations,
            userDocs: users,
          );

          final results = await service.getDiscoveryUsers();

          expect(results.length, 15);
          expect(service.hasMoreDiscoveryUsers, isFalse);
        },
      );

      test('empty recommendation collection returns empty discovery', () async {
        stubStoredRecommendations(recommendationDocs: [], userDocs: []);

        final results = await service.getDiscoveryUsers();

        expect(results, isEmpty);
        expect(service.hasMoreDiscoveryUsers, isFalse);
      });

      test('excludes current user from stored recommendations', () async {
        final recommendations = [
          buildRecommendationDoc(myUid),
          buildRecommendationDoc('other1'),
          buildRecommendationDoc('other2'),
        ];
        final users = [buildUserDoc('other1'), buildUserDoc('other2')];
        stubStoredRecommendations(
          recommendationDocs: recommendations,
          userDocs: users,
        );

        final results = await service.getDiscoveryUsers();

        expect(results.length, 2);
        expect(results.any((result) => result.user.uid == myUid), isFalse);
      });

      test('uses stored recommendation score and shared names', () async {
        final recommendations = [
          buildRecommendationDoc(
            'other1',
            score: 90,
            sharedArtistNames: ['A', 'B'],
            sharedGenreNames: ['rock'],
          ),
          buildRecommendationDoc(
            'other2',
            score: 20,
            sharedArtistNames: ['C'],
            sharedGenreNames: [],
          ),
        ];
        final users = [buildUserDoc('other1'), buildUserDoc('other2')];
        stubStoredRecommendations(
          recommendationDocs: recommendations,
          userDocs: users,
        );

        final results = await service.getDiscoveryUsers();

        expect(results.first.user.uid, 'other1');
        expect(results.first.score, 90);
        expect(results.first.sharedArtistNames, ['A', 'B']);
        expect(results.first.sharedGenreNames, ['rock']);
        expect(results.last.user.uid, 'other2');
      });

      test('second call without forceRefresh serves in-memory cache', () async {
        final recommendations = List.generate(
          5,
          (i) => buildRecommendationDoc('user$i'),
        );
        final users = List.generate(5, (i) => buildUserDoc('user$i'));
        stubStoredRecommendations(
          recommendationDocs: recommendations,
          userDocs: users,
        );

        await service.getDiscoveryUsers();
        await service.getDiscoveryUsers();

        verify(() => mockRecommendationLimitQuery.get()).called(1);
        verify(() => mockUsersByIdQuery.get()).called(1);
      });

      test(
        'forceRefresh invalidates cache and reads recommendations again',
        () async {
          final recommendations = List.generate(
            5,
            (i) => buildRecommendationDoc('user$i'),
          );
          final users = List.generate(5, (i) => buildUserDoc('user$i'));
          stubStoredRecommendations(
            recommendationDocs: recommendations,
            userDocs: users,
          );

          await service.getDiscoveryUsers(forceRefresh: true);
          await service.getDiscoveryUsers(forceRefresh: true);

          verify(() => mockRecommendationLimitQuery.get()).called(2);
          verify(() => mockUsersByIdQuery.get()).called(2);
        },
      );
    });

    group('loadMoreDiscoveryUsers', () {
      test('without previous load returns empty list', () async {
        final (results, hasMore) = await service.loadMoreDiscoveryUsers();

        expect(results, isEmpty);
        expect(hasMore, isFalse);
      });

      test(
        'when total <= pageSize, loadMore does not expand results',
        () async {
          final recommendations = List.generate(
            5,
            (i) => buildRecommendationDoc('user$i'),
          );
          final users = List.generate(5, (i) => buildUserDoc('user$i'));
          stubStoredRecommendations(
            recommendationDocs: recommendations,
            userDocs: users,
          );
          await service.getDiscoveryUsers();

          final (results, hasMore) = await service.loadMoreDiscoveryUsers();

          expect(results.length, 5);
          expect(hasMore, isFalse);
        },
      );

      test('returns next page from recommendation cache', () async {
        final recommendations = List.generate(
          25,
          (i) => buildRecommendationDoc('user$i'),
        );
        final users = List.generate(25, (i) => buildUserDoc('user$i'));
        stubStoredRecommendations(
          recommendationDocs: recommendations,
          userDocs: users,
        );

        await service.getDiscoveryUsers();
        expect(service.hasMoreDiscoveryUsers, isTrue);

        final (allResults, hasMore) = await service.loadMoreDiscoveryUsers();

        expect(allResults.length, 25);
        expect(hasMore, isFalse);
        verify(() => mockRecommendationLimitQuery.get()).called(1);
      });

      test('multiple loadMore calls page correctly from cache', () async {
        final recommendations = List.generate(
          50,
          (i) => buildRecommendationDoc('user$i'),
        );
        final users = List.generate(50, (i) => buildUserDoc('user$i'));
        stubStoredRecommendations(
          recommendationDocs: recommendations,
          userDocs: users,
        );

        await service.getDiscoveryUsers();
        expect(service.hasMoreDiscoveryUsers, isTrue);

        final (results1, hasMore1) = await service.loadMoreDiscoveryUsers();
        expect(results1.length, 40);
        expect(hasMore1, isTrue);

        final (results2, hasMore2) = await service.loadMoreDiscoveryUsers();
        expect(results2.length, 50);
        expect(hasMore2, isFalse);
      });
    });
  });
}
