// ignore_for_file: subtype_of_sealed_class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musi_link/models/track.dart';
import 'package:musi_link/services/chat_service.dart';

import '../helpers/mocks.dart';

/// Mock para CollectionReference de subcollection (messages)
class MockMessagesCollectionRef extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockFirebaseAuth mockAuth;
  late MockCollectionReference mockChatsRef;
  late MockUser mockCurrentUser;
  late ChatService chatService;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockChatsRef = MockCollectionReference();
    mockCurrentUser = MockUser();

    when(() => mockFirestore.collection('chats')).thenReturn(mockChatsRef);
    when(() => mockAuth.currentUser).thenReturn(mockCurrentUser);
    when(() => mockCurrentUser.uid).thenReturn('current_uid');

    chatService = ChatService(firestore: mockFirestore, auth: mockAuth);
    registerFallbackValues();
  });

  group('ChatService', () {
    group('getOrCreateChat', () {
      test('devuelve chat existente si ya hay uno entre ambos', () async {
        final mockQuery = MockQuery();
        final mockSnapshot = MockQuerySnapshot();
        final mockDoc = MockQueryDocumentSnapshot();

        when(() => mockChatsRef.where('participants',
            arrayContains: 'current_uid')).thenReturn(mockQuery);
        when(() => mockQuery.get()).thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.docs).thenReturn([mockDoc]);
        when(() => mockDoc.id).thenReturn('chat_123');
        when(() => mockDoc['participants'])
            .thenReturn(['current_uid', 'other_uid']);
        when(() => mockDoc.data()).thenReturn({
          'participants': ['current_uid', 'other_uid'],
          'lastMessage': 'hello',
          'lastMessageTime': Timestamp.fromDate(DateTime(2025, 1, 1)),
          'createdAt': Timestamp.fromDate(DateTime(2025, 1, 1)),
        });

        final chat = await chatService.getOrCreateChat('other_uid');

        expect(chat.id, 'chat_123');
        expect(chat.participants, contains('other_uid'));
        // No se debería haber creado uno nuevo
        verifyNever(() => mockChatsRef.add(any()));
      });

      test('crea chat nuevo si no existe uno entre ambos', () async {
        final mockQuery = MockQuery();
        final mockSnapshot = MockQuerySnapshot();

        // No hay chats existentes
        when(() => mockChatsRef.where('participants',
            arrayContains: 'current_uid')).thenReturn(mockQuery);
        when(() => mockQuery.get()).thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.docs).thenReturn([]);

        // Crear nuevo
        final mockNewDocRef = MockDocumentReference();
        final mockNewDocSnap = MockDocumentSnapshot();
        when(() => mockChatsRef.add(any()))
            .thenAnswer((_) async => mockNewDocRef);
        when(() => mockNewDocRef.get())
            .thenAnswer((_) async => mockNewDocSnap);
        when(() => mockNewDocSnap.id).thenReturn('new_chat_id');
        when(() => mockNewDocSnap.data()).thenReturn({
          'participants': ['current_uid', 'other_uid'],
          'lastMessage': '',
          'lastMessageTime': Timestamp.fromDate(DateTime(2025, 1, 1)),
          'createdAt': Timestamp.fromDate(DateTime(2025, 1, 1)),
        });

        final chat = await chatService.getOrCreateChat('other_uid');

        expect(chat.id, 'new_chat_id');
        final captured =
            verify(() => mockChatsRef.add(captureAny())).captured.single
                as Map<String, dynamic>;
        expect(captured['participants'], ['current_uid', 'other_uid']);
      });
    });

    group('sendMessage', () {
      test('crea mensaje y actualiza lastMessage del chat', () async {
        final mockBatch = MockWriteBatch();
        final mockChatDocRef = MockDocumentReference();
        final mockMessagesCol = MockMessagesCollectionRef();
        final mockMsgDocRef = MockDocumentReference();

        when(() => mockFirestore.batch()).thenReturn(mockBatch);
        when(() => mockChatsRef.doc('chat_123')).thenReturn(mockChatDocRef);
        when(() => mockChatDocRef.collection('messages'))
            .thenReturn(mockMessagesCol);
        when(() => mockMessagesCol.doc()).thenReturn(mockMsgDocRef);
        when(() => mockBatch.set<Map<String, dynamic>>(any(), any(), any()))
            .thenReturn(null);
        when(() => mockBatch.update(any(), any())).thenReturn(null);
        when(() => mockBatch.commit()).thenAnswer((_) async {});

        await chatService.sendMessage('chat_123', 'Hello!');

        // Verificar que se creó el mensaje y se actualizó el chat
        final setCall = verify(() => mockBatch.set<Map<String, dynamic>>(
            mockMsgDocRef, captureAny(), any())).captured.single as Map;
        expect(setCall['text'], 'Hello!');
        expect(setCall['senderId'], 'current_uid');

        final updateCall = verify(
                () => mockBatch.update(mockChatDocRef, captureAny()))
            .captured.single as Map;
        expect(updateCall['lastMessage'], 'Hello!');

        verify(() => mockBatch.commit()).called(1);
      });
    });

    group('sendTrackMessage', () {
      test('envía mensaje de tipo track con datos de la canción', () async {
        final mockBatch = MockWriteBatch();
        final mockChatDocRef = MockDocumentReference();
        final mockMessagesCol = MockMessagesCollectionRef();
        final mockMsgDocRef = MockDocumentReference();

        when(() => mockFirestore.batch()).thenReturn(mockBatch);
        when(() => mockChatsRef.doc('chat_123')).thenReturn(mockChatDocRef);
        when(() => mockChatDocRef.collection('messages'))
            .thenReturn(mockMessagesCol);
        when(() => mockMessagesCol.doc()).thenReturn(mockMsgDocRef);
        when(() => mockBatch.set<Map<String, dynamic>>(any(), any(), any()))
            .thenReturn(null);
        when(() => mockBatch.update(any(), any())).thenReturn(null);
        when(() => mockBatch.commit()).thenAnswer((_) async {});

        const track = Track(
          title: 'Bohemian Rhapsody',
          artist: 'Queen',
          imageUrl: 'https://img.url',
          spotifyUrl: 'https://spotify.url',
        );

        await chatService.sendTrackMessage('chat_123', track);

        // Verificar mensaje tipo track
        final setCall = verify(() => mockBatch.set<Map<String, dynamic>>(
            mockMsgDocRef, captureAny(), any())).captured.single as Map;
        expect(setCall['type'], 'track');
        expect(setCall['text'], 'Bohemian Rhapsody - Queen');
        expect(setCall['trackData'], isNotNull);

        // Verificar lastMessage con emoji
        final updateCall = verify(
                () => mockBatch.update(mockChatDocRef, captureAny()))
            .captured.single as Map;
        expect(updateCall['lastMessage'], contains('Bohemian Rhapsody'));
      });
    });

    group('deleteChat', () {
      test('elimina todos los mensajes y el documento del chat', () async {
        final mockChatDocRef = MockDocumentReference();
        final mockMessagesCol = MockMessagesCollectionRef();
        final mockMsgSnapshot = MockQuerySnapshot();
        final mockBatch = MockWriteBatch();

        final mockMsgDoc1 = MockQueryDocumentSnapshot();
        final mockMsgDoc2 = MockQueryDocumentSnapshot();
        final mockMsgRef1 = MockDocumentReference();
        final mockMsgRef2 = MockDocumentReference();

        when(() => mockChatsRef.doc('chat_123')).thenReturn(mockChatDocRef);
        when(() => mockChatDocRef.collection('messages'))
            .thenReturn(mockMessagesCol);
        when(() => mockMessagesCol.get())
            .thenAnswer((_) async => mockMsgSnapshot);
        when(() => mockMsgSnapshot.docs).thenReturn([mockMsgDoc1, mockMsgDoc2]);
        when(() => mockMsgDoc1.reference).thenReturn(mockMsgRef1);
        when(() => mockMsgDoc2.reference).thenReturn(mockMsgRef2);

        when(() => mockFirestore.batch()).thenReturn(mockBatch);
        when(() => mockBatch.delete(any())).thenReturn(null);
        when(() => mockBatch.commit()).thenAnswer((_) async {});

        await chatService.deleteChat('chat_123');

        // 2 mensajes + 1 chat = 3 deletes
        verify(() => mockBatch.delete(mockMsgRef1)).called(1);
        verify(() => mockBatch.delete(mockMsgRef2)).called(1);
        verify(() => mockBatch.delete(mockChatDocRef)).called(1);
        verify(() => mockBatch.commit()).called(1);
      });

      test('elimina chat vacío (sin mensajes)', () async {
        final mockChatDocRef = MockDocumentReference();
        final mockMessagesCol = MockMessagesCollectionRef();
        final mockMsgSnapshot = MockQuerySnapshot();
        final mockBatch = MockWriteBatch();

        when(() => mockChatsRef.doc('chat_123')).thenReturn(mockChatDocRef);
        when(() => mockChatDocRef.collection('messages'))
            .thenReturn(mockMessagesCol);
        when(() => mockMessagesCol.get())
            .thenAnswer((_) async => mockMsgSnapshot);
        when(() => mockMsgSnapshot.docs).thenReturn([]);

        when(() => mockFirestore.batch()).thenReturn(mockBatch);
        when(() => mockBatch.delete(any())).thenReturn(null);
        when(() => mockBatch.commit()).thenAnswer((_) async {});

        await chatService.deleteChat('chat_123');

        verify(() => mockBatch.delete(mockChatDocRef)).called(1);
        verify(() => mockBatch.commit()).called(1);
      });
    });

    group('markMessagesAsRead', () {
      test('marca mensajes no leídos del otro usuario como leídos', () async {
        final mockChatDocRef = MockDocumentReference();
        final mockMessagesCol = MockMessagesCollectionRef();
        final mockQuery1 = MockQuery();
        final mockQuery2 = MockQuery();
        final mockSnapshot = MockQuerySnapshot();
        final mockBatch = MockWriteBatch();

        final mockMsgDoc = MockQueryDocumentSnapshot();
        final mockMsgRef = MockDocumentReference();

        when(() => mockChatsRef.doc('chat_123')).thenReturn(mockChatDocRef);
        when(() => mockChatDocRef.collection('messages'))
            .thenReturn(mockMessagesCol);
        when(() => mockMessagesCol.where('read', isEqualTo: false))
            .thenReturn(mockQuery1);
        when(() => mockQuery1.where('senderId', isNotEqualTo: 'current_uid'))
            .thenReturn(mockQuery2);
        when(() => mockQuery2.get()).thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.docs).thenReturn([mockMsgDoc]);
        when(() => mockMsgDoc.reference).thenReturn(mockMsgRef);

        when(() => mockFirestore.batch()).thenReturn(mockBatch);
        when(() => mockBatch.update(any(), any())).thenReturn(null);
        when(() => mockBatch.commit()).thenAnswer((_) async {});

        await chatService.markMessagesAsRead('chat_123');

        verify(() =>
            mockBatch.update(mockMsgRef, {'read': true})).called(1);
        verify(() => mockBatch.commit()).called(1);
      });

      test('no hace nada si no hay mensajes sin leer', () async {
        final mockChatDocRef = MockDocumentReference();
        final mockMessagesCol = MockMessagesCollectionRef();
        final mockQuery1 = MockQuery();
        final mockQuery2 = MockQuery();
        final mockSnapshot = MockQuerySnapshot();

        when(() => mockChatsRef.doc('chat_123')).thenReturn(mockChatDocRef);
        when(() => mockChatDocRef.collection('messages'))
            .thenReturn(mockMessagesCol);
        when(() => mockMessagesCol.where('read', isEqualTo: false))
            .thenReturn(mockQuery1);
        when(() => mockQuery1.where('senderId', isNotEqualTo: 'current_uid'))
            .thenReturn(mockQuery2);
        when(() => mockQuery2.get()).thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.docs).thenReturn([]);

        await chatService.markMessagesAsRead('chat_123');

        verifyNever(() => mockFirestore.batch());
      });
    });

    group('toggleReaction', () {
      test('añade reacción si el usuario no ha reaccionado', () async {
        final mockChatDocRef = MockDocumentReference();
        final mockMessagesCol = MockMessagesCollectionRef();
        final mockMsgRef = MockDocumentReference();
        final mockMsgSnap = MockDocumentSnapshot();

        when(() => mockChatsRef.doc('chat_123')).thenReturn(mockChatDocRef);
        when(() => mockChatDocRef.collection('messages'))
            .thenReturn(mockMessagesCol);
        when(() => mockMessagesCol.doc('msg_123')).thenReturn(mockMsgRef);
        when(() => mockMsgRef.get()).thenAnswer((_) async => mockMsgSnap);
        when(() => mockMsgSnap.exists).thenReturn(true);
        when(() => mockMsgSnap.data()).thenReturn({
          'reactions': <String, dynamic>{},
        });
        when(() => mockMsgRef.update(any())).thenAnswer((_) async {});

        await chatService.toggleReaction('chat_123', 'msg_123', '👍');

        final captured = Map<String, dynamic>.from(
            verify(() => mockMsgRef.update(captureAny())).captured.single
                as Map);
        final reactions =
            Map<String, dynamic>.from(captured['reactions'] as Map);
        expect(reactions['👍'], contains('current_uid'));
      });

      test('quita reacción si el usuario ya reaccionó', () async {
        final mockChatDocRef = MockDocumentReference();
        final mockMessagesCol = MockMessagesCollectionRef();
        final mockMsgRef = MockDocumentReference();
        final mockMsgSnap = MockDocumentSnapshot();

        when(() => mockChatsRef.doc('chat_123')).thenReturn(mockChatDocRef);
        when(() => mockChatDocRef.collection('messages'))
            .thenReturn(mockMessagesCol);
        when(() => mockMessagesCol.doc('msg_123')).thenReturn(mockMsgRef);
        when(() => mockMsgRef.get()).thenAnswer((_) async => mockMsgSnap);
        when(() => mockMsgSnap.exists).thenReturn(true);
        when(() => mockMsgSnap.data()).thenReturn({
          'reactions': {
            '👍': ['current_uid', 'other_uid']
          },
        });
        when(() => mockMsgRef.update(any())).thenAnswer((_) async {});

        await chatService.toggleReaction('chat_123', 'msg_123', '👍');

        final captured = Map<String, dynamic>.from(
            verify(() => mockMsgRef.update(captureAny())).captured.single
                as Map);
        final reactions =
            Map<String, dynamic>.from(captured['reactions'] as Map);
        final users = reactions['👍'] as List;
        expect(users, isNot(contains('current_uid')));
        expect(users, contains('other_uid'));
      });

      test('elimina emoji del mapa si ya no quedan usuarios', () async {
        final mockChatDocRef = MockDocumentReference();
        final mockMessagesCol = MockMessagesCollectionRef();
        final mockMsgRef = MockDocumentReference();
        final mockMsgSnap = MockDocumentSnapshot();

        when(() => mockChatsRef.doc('chat_123')).thenReturn(mockChatDocRef);
        when(() => mockChatDocRef.collection('messages'))
            .thenReturn(mockMessagesCol);
        when(() => mockMessagesCol.doc('msg_123')).thenReturn(mockMsgRef);
        when(() => mockMsgRef.get()).thenAnswer((_) async => mockMsgSnap);
        when(() => mockMsgSnap.exists).thenReturn(true);
        when(() => mockMsgSnap.data()).thenReturn({
          'reactions': {
            '👍': ['current_uid']
          },
        });
        when(() => mockMsgRef.update(any())).thenAnswer((_) async {});

        await chatService.toggleReaction('chat_123', 'msg_123', '👍');

        final captured = Map<String, dynamic>.from(
            verify(() => mockMsgRef.update(captureAny())).captured.single
                as Map);
        final reactions =
            Map<String, dynamic>.from(captured['reactions'] as Map);
        expect(reactions.containsKey('👍'), false);
      });

      test('no hace nada si el mensaje no existe', () async {
        final mockChatDocRef = MockDocumentReference();
        final mockMessagesCol = MockMessagesCollectionRef();
        final mockMsgRef = MockDocumentReference();
        final mockMsgSnap = MockDocumentSnapshot();

        when(() => mockChatsRef.doc('chat_123')).thenReturn(mockChatDocRef);
        when(() => mockChatDocRef.collection('messages'))
            .thenReturn(mockMessagesCol);
        when(() => mockMessagesCol.doc('msg_123')).thenReturn(mockMsgRef);
        when(() => mockMsgRef.get()).thenAnswer((_) async => mockMsgSnap);
        when(() => mockMsgSnap.exists).thenReturn(false);

        await chatService.toggleReaction('chat_123', 'msg_123', '👍');

        verifyNever(() => mockMsgRef.update(any()));
      });
    });
  });
}
