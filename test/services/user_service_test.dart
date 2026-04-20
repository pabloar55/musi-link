// ignore_for_file: subtype_of_sealed_class, unnecessary_lambdas, avoid_redundant_argument_values
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musi_link/models/track.dart';
import 'package:musi_link/services/user_service.dart';

import '../helpers/mocks.dart';

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockUsersRef;
  late UserService userService;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockUsersRef = MockCollectionReference();
    when(() => mockFirestore.collection('users')).thenReturn(mockUsersRef);
    userService = UserService(firestore: mockFirestore);
    registerFallbackValues();
  });

  group('UserService', () {
    group('createUserProfile', () {
      test('crea perfil correctamente en Firestore', () async {
        final mockDocRef = MockDocumentReference();
        when(() => mockUsersRef.doc('uid123')).thenReturn(mockDocRef);
        when(() => mockDocRef.set(any())).thenAnswer((_) async {});

        await userService.createUserProfile(
          uid: 'uid123',
          email: 'test@test.com',
          displayName: 'Test User',
        );

        final captured =
            verify(() => mockDocRef.set(captureAny())).captured.single
                as Map<String, dynamic>;
        expect(captured['email'], 'test@test.com');
        expect(captured['displayName'], 'Test User');
        expect(captured['displayNameLower'], 'test user');
      });

      test('propaga error si Firestore falla', () async {
        final mockDocRef = MockDocumentReference();
        when(() => mockUsersRef.doc('uid123')).thenReturn(mockDocRef);
        when(() => mockDocRef.set(any()))
            .thenThrow(FirebaseException(plugin: 'firestore'));

        expect(
          () => userService.createUserProfile(
            uid: 'uid123',
            email: 'test@test.com',
            displayName: 'Test',
          ),
          throwsA(isA<FirebaseException>()),
        );
      });
    });

    group('getUser', () {
      test('devuelve AppUser si el documento existe', () async {
        final mockDocRef = MockDocumentReference();
        final mockDocSnap = MockDocumentSnapshot();
        when(() => mockUsersRef.doc('uid123')).thenReturn(mockDocRef);
        when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
        when(() => mockDocSnap.exists).thenReturn(true);
        when(() => mockDocSnap.id).thenReturn('uid123');
        when(() => mockDocSnap.data()).thenReturn({
          'email': 'test@test.com',
          'displayName': 'Test User',
          'photoUrl': '',
          'createdAt': Timestamp.fromDate(DateTime(2025, 1, 1)),
          'lastLogin': Timestamp.fromDate(DateTime(2025, 1, 1)),
        });

        final user = await userService.getUser('uid123');

        expect(user, isNotNull);
        expect(user!.uid, 'uid123');
        expect(user.email, 'test@test.com');
        expect(user.displayName, 'Test User');
      });

      test('devuelve null si el documento no existe', () async {
        final mockDocRef = MockDocumentReference();
        final mockDocSnap = MockDocumentSnapshot();
        when(() => mockUsersRef.doc('uid123')).thenReturn(mockDocRef);
        when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
        when(() => mockDocSnap.exists).thenReturn(false);

        final user = await userService.getUser('uid123');
        expect(user, isNull);
      });

      test('propaga error si Firestore falla', () async {
        final mockDocRef = MockDocumentReference();
        when(() => mockUsersRef.doc('uid123')).thenReturn(mockDocRef);
        when(() => mockDocRef.get())
            .thenThrow(FirebaseException(plugin: 'firestore'));

        expect(
          () => userService.getUser('uid123'),
          throwsA(isA<FirebaseException>()),
        );
      });
    });

    group('userExists', () {
      test('devuelve true si el usuario existe', () async {
        final mockDocRef = MockDocumentReference();
        final mockDocSnap = MockDocumentSnapshot();
        when(() => mockUsersRef.doc('uid123')).thenReturn(mockDocRef);
        when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
        when(() => mockDocSnap.exists).thenReturn(true);

        expect(await userService.userExists('uid123'), true);
      });

      test('devuelve false si no existe', () async {
        final mockDocRef = MockDocumentReference();
        final mockDocSnap = MockDocumentSnapshot();
        when(() => mockUsersRef.doc('uid123')).thenReturn(mockDocRef);
        when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
        when(() => mockDocSnap.exists).thenReturn(false);

        expect(await userService.userExists('uid123'), false);
      });

      test('propaga error si Firestore falla', () async {
        final mockDocRef = MockDocumentReference();
        when(() => mockUsersRef.doc('uid123')).thenReturn(mockDocRef);
        when(() => mockDocRef.get())
            .thenThrow(FirebaseException(plugin: 'firestore'));

        expect(
          () => userService.userExists('uid123'),
          throwsA(isA<FirebaseException>()),
        );
      });
    });

    group('updateLastLogin', () {
      test('actualiza el campo lastLogin', () async {
        final mockDocRef = MockDocumentReference();
        when(() => mockUsersRef.doc('uid123')).thenReturn(mockDocRef);
        when(() => mockDocRef.update(any())).thenAnswer((_) async {});

        await userService.updateLastLogin('uid123');

        final captured = Map<String, dynamic>.from(
            verify(() => mockDocRef.update(captureAny())).captured.single
                as Map);
        expect(captured.containsKey('lastLogin'), true);
        expect(captured['lastLogin'], isA<Timestamp>());
      });
    });

    group('updateProfile', () {
      test('actualiza displayName y su versión lowercase', () async {
        final mockDocRef = MockDocumentReference();
        when(() => mockUsersRef.doc('uid123')).thenReturn(mockDocRef);
        when(() => mockDocRef.update(any())).thenAnswer((_) async {});

        await userService.updateProfile('uid123', displayName: 'New Name');

        final captured =
            verify(() => mockDocRef.update(captureAny())).captured.single
                as Map<String, dynamic>;
        expect(captured['displayName'], 'New Name');
        expect(captured['displayNameLower'], 'new name');
      });

      test('actualiza solo photoUrl si no se pasa displayName', () async {
        final mockDocRef = MockDocumentReference();
        when(() => mockUsersRef.doc('uid123')).thenReturn(mockDocRef);
        when(() => mockDocRef.update(any())).thenAnswer((_) async {});

        await userService.updateProfile('uid123',
            photoUrl: 'https://new.photo');

        final captured =
            verify(() => mockDocRef.update(captureAny())).captured.single
                as Map<String, dynamic>;
        expect(captured.containsKey('displayName'), false);
        expect(captured['photoUrl'], 'https://new.photo');
      });

      test('no hace nada si no se pasan parámetros', () async {
        final mockDocRef = MockDocumentReference();
        when(() => mockUsersRef.doc('uid123')).thenReturn(mockDocRef);

        await userService.updateProfile('uid123');

        verifyNever(() => mockDocRef.update(any()));
      });
    });

    group('searchUsers', () {
      test('devuelve lista vacía con query vacío', () async {
        final result = await userService.searchUsers('');
        expect(result, isEmpty);
      });

      test('devuelve lista vacía con query de solo espacios', () async {
        final result = await userService.searchUsers('   ');
        expect(result, isEmpty);
      });

      test('busca por displayNameLower y excluye usuario actual', () async {
        final mockQuery1 = MockQuery();
        final mockQuery2 = MockQuery();
        final mockQuery3 = MockQuery();
        final mockQuerySnapshot = MockQuerySnapshot();

        final mockDoc = MockQueryDocumentSnapshot();
        when(() => mockDoc.id).thenReturn('other_uid');
        when(() => mockDoc.data()).thenReturn({
          'email': 'other@test.com',
          'displayName': 'Test User',
          'photoUrl': '',
          'createdAt': Timestamp.fromDate(DateTime(2025, 1, 1)),
          'lastLogin': Timestamp.fromDate(DateTime(2025, 1, 1)),
        });

        when(() => mockUsersRef.where('displayNameLower',
            isGreaterThanOrEqualTo: 'test')).thenReturn(mockQuery1);
        when(() =>
                mockQuery1.where('displayNameLower', isLessThanOrEqualTo: any(named: 'isLessThanOrEqualTo')))
            .thenReturn(mockQuery2);
        when(() => mockQuery2.limit(20)).thenReturn(mockQuery3);
        when(() => mockQuery3.get())
            .thenAnswer((_) async => mockQuerySnapshot);
        when(() => mockQuerySnapshot.docs).thenReturn([mockDoc]);

        final result =
            await userService.searchUsers('test', excludeUid: 'my_uid');

        expect(result, hasLength(1));
        expect(result.first.uid, 'other_uid');
      });
    });

    group('setDailySong', () {
      test('guarda la canción del día', () async {
        final mockDocRef = MockDocumentReference();
        when(() => mockUsersRef.doc('uid123')).thenReturn(mockDocRef);
        when(() => mockDocRef.update(any())).thenAnswer((_) async {});

        const track = Track(
          title: 'Bohemian Rhapsody',
          artist: 'Queen',
          imageUrl: 'https://img.url',
          spotifyUrl: 'https://spotify.url',
        );

        await userService.setDailySong('uid123', track);

        final captured = Map<String, dynamic>.from(
            verify(() => mockDocRef.update(captureAny())).captured.single
                as Map);
        final songData =
            Map<String, dynamic>.from(captured['dailySong'] as Map);
        expect(songData['title'], 'Bohemian Rhapsody');
        expect(songData['artist'], 'Queen');
        expect(captured.containsKey('dailySongUpdatedAt'), true);
      });
    });

    group('updateNowPlaying', () {
      test('actualiza con track', () async {
        final mockDocRef = MockDocumentReference();
        when(() => mockUsersRef.doc('uid123')).thenReturn(mockDocRef);
        when(() => mockDocRef.update(any())).thenAnswer((_) async {});

        const track = Track(
          title: 'Song',
          artist: 'Artist',
          imageUrl: 'https://img.url',
        );

        await userService.updateNowPlaying('uid123', track);

        final captured =
            verify(() => mockDocRef.update(captureAny())).captured.single
                as Map<String, dynamic>;
        expect(captured['nowPlaying'], isNotNull);
        expect(captured['nowPlayingUpdatedAt'], isA<Timestamp>());
      });

      test('limpia nowPlaying con null', () async {
        final mockDocRef = MockDocumentReference();
        when(() => mockUsersRef.doc('uid123')).thenReturn(mockDocRef);
        when(() => mockDocRef.update(any())).thenAnswer((_) async {});

        await userService.updateNowPlaying('uid123', null);

        final captured =
            verify(() => mockDocRef.update(captureAny())).captured.single
                as Map<String, dynamic>;
        expect(captured['nowPlaying'], isNull);
        expect(captured['nowPlayingUpdatedAt'], isNull);
      });
    });

    group('getUsersByIds', () {
      test('devuelve lista vacía con UIDs vacíos', () async {
        final result = await userService.getUsersByIds([]);
        expect(result, isEmpty);
      });

      test('hace una sola consulta con exactamente 10 UIDs (límite whereIn)',
          () async {
        final uids = List.generate(10, (i) => 'uid_$i');

        final mockQuery = MockQuery();
        final mockSnapshot = MockQuerySnapshot();

        when(() => mockUsersRef.where(FieldPath.documentId,
            whereIn: uids)).thenReturn(mockQuery);
        when(() => mockQuery.get()).thenAnswer((_) async => mockSnapshot);

        final mockDoc = MockQueryDocumentSnapshot();
        when(() => mockDoc.id).thenReturn('uid_0');
        when(() => mockDoc.data()).thenReturn({
          'email': 'u0@test.com',
          'displayName': 'User 0',
          'photoUrl': '',
          'createdAt': Timestamp.fromDate(DateTime(2025)),
          'lastLogin': Timestamp.fromDate(DateTime(2025)),
        });
        when(() => mockSnapshot.docs).thenReturn([mockDoc]);

        final result = await userService.getUsersByIds(uids);

        expect(result, hasLength(1));
        verify(() => mockQuery.get()).called(1);
      });

      test('hace chunks de 10 para consultas whereIn', () async {
        // Generar 15 UIDs para forzar 2 chunks
        final uids = List.generate(15, (i) => 'uid_$i');

        final mockQuery1 = MockQuery();
        final mockQuery2 = MockQuery();
        final mockSnapshot1 = MockQuerySnapshot();
        final mockSnapshot2 = MockQuerySnapshot();

        // Primer chunk (10 items)
        when(() => mockUsersRef.where(FieldPath.documentId,
            whereIn: uids.sublist(0, 10))).thenReturn(mockQuery1);
        when(() => mockQuery1.get())
            .thenAnswer((_) async => mockSnapshot1);

        // Segundo chunk (5 items)
        when(() => mockUsersRef.where(FieldPath.documentId,
            whereIn: uids.sublist(10, 15))).thenReturn(mockQuery2);
        when(() => mockQuery2.get())
            .thenAnswer((_) async => mockSnapshot2);

        // Docs para cada snapshot
        final mockDoc1 = MockQueryDocumentSnapshot();
        when(() => mockDoc1.id).thenReturn('uid_0');
        when(() => mockDoc1.data()).thenReturn({
          'email': 'u0@test.com',
          'displayName': 'User 0',
          'photoUrl': '',
          'createdAt': Timestamp.fromDate(DateTime(2025)),
          'lastLogin': Timestamp.fromDate(DateTime(2025)),
        });

        final mockDoc2 = MockQueryDocumentSnapshot();
        when(() => mockDoc2.id).thenReturn('uid_10');
        when(() => mockDoc2.data()).thenReturn({
          'email': 'u10@test.com',
          'displayName': 'User 10',
          'photoUrl': '',
          'createdAt': Timestamp.fromDate(DateTime(2025)),
          'lastLogin': Timestamp.fromDate(DateTime(2025)),
        });

        when(() => mockSnapshot1.docs).thenReturn([mockDoc1]);
        when(() => mockSnapshot2.docs).thenReturn([mockDoc2]);

        final result = await userService.getUsersByIds(uids);

        expect(result, hasLength(2));
        verify(() => mockQuery1.get()).called(1);
        verify(() => mockQuery2.get()).called(1);
      });
    });
  });
}
