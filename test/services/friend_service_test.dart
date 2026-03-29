// ignore_for_file: subtype_of_sealed_class, unnecessary_lambdas, avoid_redundant_argument_values
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musi_link/services/friend_service.dart';

import '../helpers/mocks.dart';

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockFirebaseAuth mockAuth;
  late MockCollectionReference mockRequestsRef;
  late MockCollectionReference mockUsersRef;
  late MockUser mockCurrentUser;
  late FriendService friendService;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockRequestsRef = MockCollectionReference();
    mockUsersRef = MockCollectionReference();
    mockCurrentUser = MockUser();

    when(() => mockFirestore.collection('friend_requests'))
        .thenReturn(mockRequestsRef);
    when(() => mockFirestore.collection('users')).thenReturn(mockUsersRef);
    when(() => mockAuth.currentUser).thenReturn(mockCurrentUser);
    when(() => mockCurrentUser.uid).thenReturn('current_uid');

    friendService = FriendService(firestore: mockFirestore, auth: mockAuth);
    registerFallbackValues();
  });

  group('FriendService', () {
    group('sendRequest', () {
      test('crea un friend_request con status pending', () async {
        when(() => mockRequestsRef.add(any()))
            .thenAnswer((_) async => MockDocumentReference());

        await friendService.sendRequest('receiver_uid');

        final captured =
            verify(() => mockRequestsRef.add(captureAny())).captured.single
                as Map<String, dynamic>;
        expect(captured['senderId'], 'current_uid');
        expect(captured['receiverId'], 'receiver_uid');
        expect(captured['status'], 'pending');
        expect(captured['createdAt'], isA<Timestamp>());
        expect(captured['updatedAt'], isA<Timestamp>());
      });

      test('propaga error si Firestore falla', () async {
        when(() => mockRequestsRef.add(any()))
            .thenThrow(FirebaseException(plugin: 'firestore'));

        expect(
          () => friendService.sendRequest('receiver_uid'),
          throwsA(isA<FirebaseException>()),
        );
      });
    });

    group('acceptRequest', () {
      test('actualiza status y añade amigos a ambos usuarios', () async {
        final mockBatch = MockWriteBatch();
        when(() => mockFirestore.batch()).thenReturn(mockBatch);

        final mockRequestDoc = MockDocumentReference();
        when(() => mockRequestsRef.doc('req_123')).thenReturn(mockRequestDoc);

        final mockCurrentUserDoc = MockDocumentReference();
        final mockOtherUserDoc = MockDocumentReference();
        when(() => mockUsersRef.doc('current_uid'))
            .thenReturn(mockCurrentUserDoc);
        when(() => mockUsersRef.doc('other_uid'))
            .thenReturn(mockOtherUserDoc);

        when(() => mockBatch.update(any(), any())).thenReturn(null);
        when(() => mockBatch.commit()).thenAnswer((_) async {});

        await friendService.acceptRequest('req_123', 'other_uid');

        // Verificar que se actualizó el request
        verify(() => mockBatch.update(mockRequestDoc, any(
            that: predicate<Map<String, dynamic>>(
                (m) => m['status'] == 'accepted')))).called(1);

        // Verificar que se añadieron amigos a ambos usuarios
        verify(() => mockBatch.update(mockCurrentUserDoc, any(
            that: predicate<Map<String, dynamic>>(
                (m) => m.containsKey('friends'))))).called(1);
        verify(() => mockBatch.update(mockOtherUserDoc, any(
            that: predicate<Map<String, dynamic>>(
                (m) => m.containsKey('friends'))))).called(1);

        verify(() => mockBatch.commit()).called(1);
      });
    });

    group('rejectRequest', () {
      test('actualiza status a rejected', () async {
        final mockDocRef = MockDocumentReference();
        when(() => mockRequestsRef.doc('req_123')).thenReturn(mockDocRef);
        when(() => mockDocRef.update(any())).thenAnswer((_) async {});

        await friendService.rejectRequest('req_123');

        final captured = Map<String, dynamic>.from(
            verify(() => mockDocRef.update(captureAny())).captured.single
                as Map);
        expect(captured['status'], 'rejected');
        expect(captured['updatedAt'], isA<Timestamp>());
      });
    });

    group('cancelRequest', () {
      test('elimina el documento del request', () async {
        final mockDocRef = MockDocumentReference();
        when(() => mockRequestsRef.doc('req_123')).thenReturn(mockDocRef);
        when(() => mockDocRef.delete()).thenAnswer((_) async {});

        await friendService.cancelRequest('req_123');

        verify(() => mockDocRef.delete()).called(1);
      });
    });

    group('areFriends', () {
      test('devuelve true si otherUid está en la lista de friends', () async {
        final mockDocRef = MockDocumentReference();
        final mockDocSnap = MockDocumentSnapshot();
        when(() => mockUsersRef.doc('current_uid')).thenReturn(mockDocRef);
        when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
        when(() => mockDocSnap.exists).thenReturn(true);
        when(() => mockDocSnap.data())
            .thenReturn({'friends': ['other_uid', 'another_uid']});

        expect(await friendService.areFriends('other_uid'), true);
      });

      test('devuelve false si no están en la lista', () async {
        final mockDocRef = MockDocumentReference();
        final mockDocSnap = MockDocumentSnapshot();
        when(() => mockUsersRef.doc('current_uid')).thenReturn(mockDocRef);
        when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
        when(() => mockDocSnap.exists).thenReturn(true);
        when(() => mockDocSnap.data()).thenReturn({'friends': ['another_uid']});

        expect(await friendService.areFriends('other_uid'), false);
      });

      test('devuelve false si el documento no existe', () async {
        final mockDocRef = MockDocumentReference();
        final mockDocSnap = MockDocumentSnapshot();
        when(() => mockUsersRef.doc('current_uid')).thenReturn(mockDocRef);
        when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
        when(() => mockDocSnap.exists).thenReturn(false);

        expect(await friendService.areFriends('other_uid'), false);
      });

      test('devuelve false si friends es null', () async {
        final mockDocRef = MockDocumentReference();
        final mockDocSnap = MockDocumentSnapshot();
        when(() => mockUsersRef.doc('current_uid')).thenReturn(mockDocRef);
        when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
        when(() => mockDocSnap.exists).thenReturn(true);
        when(() => mockDocSnap.data()).thenReturn({});

        expect(await friendService.areFriends('other_uid'), false);
      });

      test('devuelve false si Firestore falla', () async {
        final mockDocRef = MockDocumentReference();
        when(() => mockUsersRef.doc('current_uid')).thenReturn(mockDocRef);
        when(() => mockDocRef.get())
            .thenThrow(FirebaseException(plugin: 'firestore'));

        expect(await friendService.areFriends('other_uid'), false);
      });
    });

    group('getRelationship', () {
      test('devuelve friends si están en la lista de amigos', () async {
        final mockDocRef = MockDocumentReference();
        final mockDocSnap = MockDocumentSnapshot();
        when(() => mockUsersRef.doc('current_uid')).thenReturn(mockDocRef);
        when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
        when(() => mockDocSnap.data())
            .thenReturn({'friends': ['other_uid']});

        final result = await friendService.getRelationship('other_uid');

        expect(result.status, RelationshipStatus.friends);
        expect(result.requestId, isNull);
      });

      test('devuelve requestSent si hay solicitud enviada pendiente',
          () async {
        // No son amigos
        final mockDocRef = MockDocumentReference();
        final mockDocSnap = MockDocumentSnapshot();
        when(() => mockUsersRef.doc('current_uid')).thenReturn(mockDocRef);
        when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
        when(() => mockDocSnap.data()).thenReturn({'friends': []});

        // Solicitud enviada
        final mockSentQuery1 = MockQuery();
        final mockSentQuery2 = MockQuery();
        final mockSentQuery3 = MockQuery();
        final mockSentSnapshot = MockQuerySnapshot();
        final mockSentDoc = MockQueryDocumentSnapshot();

        when(() => mockRequestsRef.where('senderId',
            isEqualTo: 'current_uid')).thenReturn(mockSentQuery1);
        when(() => mockSentQuery1.where('receiverId',
            isEqualTo: 'other_uid')).thenReturn(mockSentQuery2);
        when(() => mockSentQuery2.where('status', isEqualTo: 'pending'))
            .thenReturn(mockSentQuery3);
        when(() => mockSentQuery3.limit(1)).thenReturn(mockSentQuery3);
        when(() => mockSentQuery3.get())
            .thenAnswer((_) async => mockSentSnapshot);
        when(() => mockSentSnapshot.docs).thenReturn([mockSentDoc]);
        when(() => mockSentDoc.id).thenReturn('sent_req_id');

        final result = await friendService.getRelationship('other_uid');

        expect(result.status, RelationshipStatus.requestSent);
        expect(result.requestId, 'sent_req_id');
      });

      test('devuelve requestReceived si hay solicitud recibida pendiente',
          () async {
        // No son amigos
        final mockDocRef = MockDocumentReference();
        final mockDocSnap = MockDocumentSnapshot();
        when(() => mockUsersRef.doc('current_uid')).thenReturn(mockDocRef);
        when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
        when(() => mockDocSnap.data()).thenReturn({'friends': []});

        // No hay solicitud enviada
        final mockSentQuery1 = MockQuery();
        final mockSentQuery2 = MockQuery();
        final mockSentQuery3 = MockQuery();
        final mockSentSnapshot = MockQuerySnapshot();

        when(() => mockRequestsRef.where('senderId',
            isEqualTo: 'current_uid')).thenReturn(mockSentQuery1);
        when(() => mockSentQuery1.where('receiverId',
            isEqualTo: 'other_uid')).thenReturn(mockSentQuery2);
        when(() => mockSentQuery2.where('status', isEqualTo: 'pending'))
            .thenReturn(mockSentQuery3);
        when(() => mockSentQuery3.limit(1)).thenReturn(mockSentQuery3);
        when(() => mockSentQuery3.get())
            .thenAnswer((_) async => mockSentSnapshot);
        when(() => mockSentSnapshot.docs).thenReturn([]);

        // Solicitud recibida
        final mockRecvQuery1 = MockQuery();
        final mockRecvQuery2 = MockQuery();
        final mockRecvQuery3 = MockQuery();
        final mockRecvSnapshot = MockQuerySnapshot();
        final mockRecvDoc = MockQueryDocumentSnapshot();

        when(() => mockRequestsRef.where('senderId',
            isEqualTo: 'other_uid')).thenReturn(mockRecvQuery1);
        when(() => mockRecvQuery1.where('receiverId',
            isEqualTo: 'current_uid')).thenReturn(mockRecvQuery2);
        when(() => mockRecvQuery2.where('status', isEqualTo: 'pending'))
            .thenReturn(mockRecvQuery3);
        when(() => mockRecvQuery3.limit(1)).thenReturn(mockRecvQuery3);
        when(() => mockRecvQuery3.get())
            .thenAnswer((_) async => mockRecvSnapshot);
        when(() => mockRecvSnapshot.docs).thenReturn([mockRecvDoc]);
        when(() => mockRecvDoc.id).thenReturn('recv_req_id');

        final result = await friendService.getRelationship('other_uid');

        expect(result.status, RelationshipStatus.requestReceived);
        expect(result.requestId, 'recv_req_id');
      });

      test('devuelve none si no hay relación', () async {
        // No son amigos
        final mockDocRef = MockDocumentReference();
        final mockDocSnap = MockDocumentSnapshot();
        when(() => mockUsersRef.doc('current_uid')).thenReturn(mockDocRef);
        when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
        when(() => mockDocSnap.data()).thenReturn({'friends': []});

        // No hay solicitud enviada
        final mockSentQuery1 = MockQuery();
        final mockSentQuery2 = MockQuery();
        final mockSentQuery3 = MockQuery();
        final mockSentSnapshot = MockQuerySnapshot();

        when(() => mockRequestsRef.where('senderId',
            isEqualTo: 'current_uid')).thenReturn(mockSentQuery1);
        when(() => mockSentQuery1.where('receiverId',
            isEqualTo: 'other_uid')).thenReturn(mockSentQuery2);
        when(() => mockSentQuery2.where('status', isEqualTo: 'pending'))
            .thenReturn(mockSentQuery3);
        when(() => mockSentQuery3.limit(1)).thenReturn(mockSentQuery3);
        when(() => mockSentQuery3.get())
            .thenAnswer((_) async => mockSentSnapshot);
        when(() => mockSentSnapshot.docs).thenReturn([]);

        // No hay solicitud recibida
        final mockRecvQuery1 = MockQuery();
        final mockRecvQuery2 = MockQuery();
        final mockRecvQuery3 = MockQuery();
        final mockRecvSnapshot = MockQuerySnapshot();

        when(() => mockRequestsRef.where('senderId',
            isEqualTo: 'other_uid')).thenReturn(mockRecvQuery1);
        when(() => mockRecvQuery1.where('receiverId',
            isEqualTo: 'current_uid')).thenReturn(mockRecvQuery2);
        when(() => mockRecvQuery2.where('status', isEqualTo: 'pending'))
            .thenReturn(mockRecvQuery3);
        when(() => mockRecvQuery3.limit(1)).thenReturn(mockRecvQuery3);
        when(() => mockRecvQuery3.get())
            .thenAnswer((_) async => mockRecvSnapshot);
        when(() => mockRecvSnapshot.docs).thenReturn([]);

        final result = await friendService.getRelationship('other_uid');

        expect(result.status, RelationshipStatus.none);
        expect(result.requestId, isNull);
      });

      test('devuelve none si Firestore falla', () async {
        final mockDocRef = MockDocumentReference();
        when(() => mockUsersRef.doc('current_uid')).thenReturn(mockDocRef);
        when(() => mockDocRef.get())
            .thenThrow(FirebaseException(plugin: 'firestore'));

        final result = await friendService.getRelationship('other_uid');
        expect(result.status, RelationshipStatus.none);
      });
    });

    group('removeFriend', () {
      test('elimina a ambos de sus listas de amigos', () async {
        final mockBatch = MockWriteBatch();
        when(() => mockFirestore.batch()).thenReturn(mockBatch);

        final mockCurrentUserDoc = MockDocumentReference();
        final mockOtherUserDoc = MockDocumentReference();
        when(() => mockUsersRef.doc('current_uid'))
            .thenReturn(mockCurrentUserDoc);
        when(() => mockUsersRef.doc('other_uid'))
            .thenReturn(mockOtherUserDoc);

        when(() => mockBatch.update(any(), any())).thenReturn(null);
        when(() => mockBatch.commit()).thenAnswer((_) async {});

        await friendService.removeFriend('other_uid');

        verify(() => mockBatch.update(mockCurrentUserDoc, any(
            that: predicate<Map<String, dynamic>>(
                (m) => m.containsKey('friends'))))).called(1);
        verify(() => mockBatch.update(mockOtherUserDoc, any(
            that: predicate<Map<String, dynamic>>(
                (m) => m.containsKey('friends'))))).called(1);
        verify(() => mockBatch.commit()).called(1);
      });

      test('propaga error si batch falla', () async {
        final mockBatch = MockWriteBatch();
        when(() => mockFirestore.batch()).thenReturn(mockBatch);

        final mockCurrentUserDoc = MockDocumentReference();
        final mockOtherUserDoc = MockDocumentReference();
        when(() => mockUsersRef.doc('current_uid'))
            .thenReturn(mockCurrentUserDoc);
        when(() => mockUsersRef.doc('other_uid'))
            .thenReturn(mockOtherUserDoc);

        when(() => mockBatch.update(any(), any())).thenReturn(null);
        when(() => mockBatch.commit())
            .thenThrow(FirebaseException(plugin: 'firestore'));

        expect(
          () => friendService.removeFriend('other_uid'),
          throwsA(isA<FirebaseException>()),
        );
      });
    });
  });
}
