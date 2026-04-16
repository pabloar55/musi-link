import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:musi_link/utils/error_reporter.dart';
import 'package:musi_link/models/chat.dart';
import 'package:musi_link/models/message.dart';
import 'package:musi_link/models/track.dart';
import 'package:musi_link/utils/firestore_collections.dart';

/// Servicio para gestionar chats y mensajes en Firestore.
class ChatService {
  ChatService({required FirebaseFirestore firestore, required FirebaseAuth auth})
      : _firestore = firestore,
        _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  late final CollectionReference<Map<String, dynamic>> _chatsRef =
      _firestore.collection(FirestoreCollections.chats);

  // Cache por otherUid: evita re-query al abrir el mismo chat varias veces.
  final Map<String, Chat> _chatByOtherUid = {};

  /// Limpia la caché en memoria. Llamar al hacer logout.
  void clearCache() => _chatByOtherUid.clear();


  /// Returns the UID of the currently authenticated user.
  /// Throws [StateError] instead of crashing if the session is lost.
  String get _currentUid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('ChatService: no authenticated user.');
    return uid;
  }

  // ─── Chats ────────────────────────────────────────────────

  /// Returns a deterministic, content-addressed document ID for a chat between
  /// two users: the two UIDs joined by "_", sorted lexicographically so that
  /// _chatId(a, b) == _chatId(b, a) for any pair.
  static String _chatId(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// Crea un chat entre el usuario actual y [otherUid].
  /// Si ya existe un chat entre ambos, devuelve el existente.
  ///
  /// Usa un ID determinista (UIDs ordenados) y una transacción Firestore para
  /// garantizar idempotencia: si dos clientes llaman a este método al mismo
  /// tiempo, la transacción del segundo verá el documento ya creado y no
  /// generará un duplicado.
  Future<Chat> getOrCreateChat(String otherUid) async {
    final cached = _chatByOtherUid[otherUid];
    if (cached != null) return cached;

    try {
      final currentUid = _currentUid;
      final docRef = _chatsRef.doc(_chatId(currentUid, otherUid));

      late Chat chat;
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        if (snap.exists) {
          chat = Chat.fromFirestore(snap);
        } else {
          final now = DateTime.now();
          tx.set(docRef, {
            'participants': [currentUid, otherUid],
            'lastMessage': '',
            'lastMessageTime': Timestamp.fromDate(now),
            'createdAt': Timestamp.fromDate(now),
            'unreadCounts': {currentUid: 0, otherUid: 0},
          });
          chat = Chat(
            id: docRef.id,
            participants: [currentUid, otherUid],
            lastMessageTime: now,
            createdAt: now,
          );
        }
      });

      _chatByOtherUid[otherUid] = chat;
      return chat;
    } catch (e, stack) {
      await reportError(e, stack);
      rethrow;
    }
  }

  /// Stream de los chats del usuario actual, ordenados por último mensaje.
  Stream<List<Chat>> getChats() {
    return _chatsRef
        .where('participants', arrayContains: _currentUid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .handleError((e, st) => reportError(e, st).ignore())
        .map((snapshot) =>
            snapshot.docs.map(Chat.fromFirestore).toList());
  }

  static const int _deleteBatchSize = 499;

  /// Elimina un chat y todos sus mensajes.
  Future<void> deleteChat(String chatId) async {
    try {
      final messagesRef =
          _chatsRef.doc(chatId).collection(FirestoreCollections.messages);

      // Paginar el borrado para no superar el límite de 500 ops por batch.
      while (true) {
        final snapshot =
            await messagesRef.limit(_deleteBatchSize).get();
        if (snapshot.docs.isEmpty) break;

        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        if (snapshot.docs.length < _deleteBatchSize) break;
      }

      await _chatsRef.doc(chatId).delete();
      _chatByOtherUid.removeWhere((_, chat) => chat.id == chatId);
    } catch (e, stack) {
      await reportError(e, stack);
      rethrow;
    }
  }

  //  Mensajes

  /// Envía un mensaje de texto en un chat.
  static const int maxMessageLength = 2000;

  Future<void> sendMessage(
    String chatId,
    String text, {
    required String otherUid,
  }) async {
    if (text.trim().isEmpty || text.length > maxMessageLength) {
      throw ArgumentError('Invalid message');
    }
    try {
      final now = DateTime.now();
      final message = Message(
        id: '',
        senderId: _currentUid,
        text: text,
        timestamp: now,
      );

      final batch = _firestore.batch();

      // Añadir el mensaje a la subcolección
      final msgRef = _chatsRef.doc(chatId).collection(FirestoreCollections.messages).doc();
      batch.set(msgRef, message.toFirestore());

      // Actualizar último mensaje e incrementar el contador del destinatario
      batch.update(_chatsRef.doc(chatId), {
        'lastMessage': text,
        'lastMessageTime': Timestamp.fromDate(now),
        'unreadCounts.$otherUid': FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e, stack) {
      await reportError(e, stack);
      rethrow;
    }
  }

  static const int messagesPageSize = 30;

  /// Stream de los últimos [messagesPageSize] mensajes de un chat, en tiempo real.
  /// Los resultados se devuelven ordenados cronológicamente (ascendente).
  Stream<List<Message>> getMessages(String chatId) {
    return _chatsRef
        .doc(chatId)
        .collection(FirestoreCollections.messages)
        .orderBy('timestamp', descending: true)
        .limit(messagesPageSize)
        .snapshots()
        .handleError((e, st) => reportError(e, st).ignore())
        .map((snapshot) =>
            snapshot.docs.reversed.map(Message.fromFirestore).toList());
  }

  /// Carga mensajes anteriores a [before] para paginación inversa.
  /// Devuelve hasta [messagesPageSize] mensajes en orden cronológico ascendente.
  Future<List<Message>> loadOlderMessages(
    String chatId, {
    required DateTime before,
  }) async {
    try {
      final snapshot = await _chatsRef
          .doc(chatId)
          .collection(FirestoreCollections.messages)
          .where('timestamp', isLessThan: Timestamp.fromDate(before))
          .orderBy('timestamp', descending: true)
          .limit(messagesPageSize)
          .get();

      return snapshot.docs.reversed.map(Message.fromFirestore).toList();
    } catch (e, stack) {
      await reportError(e, stack);
      rethrow;
    }
  }

  /// Marca todos los mensajes no leídos del otro usuario como leídos y
  /// resetea el contador desnormalizado del usuario actual en el documento
  /// del chat.
  Future<void> markMessagesAsRead(String chatId) async {
    try {
      final currentUid = _currentUid;

      // Resetear el contador desnormalizado: una sola escritura, sin listeners.
      await _chatsRef.doc(chatId).update({'unreadCounts.$currentUid': 0});

      // Marcar mensajes individuales como leídos (impulsa los ticks de lectura).
      final messagesRef = _chatsRef
          .doc(chatId)
          .collection(FirestoreCollections.messages)
          .where('read', isEqualTo: false)
          .where('senderId', isNotEqualTo: currentUid)
          .limit(_deleteBatchSize);

      while (true) {
        final snapshot = await messagesRef.get();
        if (snapshot.docs.isEmpty) break;

        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.update(doc.reference, {'read': true});
        }
        await batch.commit();

        if (snapshot.docs.length < _deleteBatchSize) break;
      }
    } catch (e, stack) {
      await reportError(e, stack);
    }
  }

  /// Envía una canción como mensaje en un chat.
  Future<void> sendTrackMessage(
    String chatId,
    Track track, {
    required String otherUid,
  }) async {
    try {
      final now = DateTime.now();
      final message = Message(
        id: '',
        senderId: _currentUid,
        text: '${track.title} - ${track.artist}',
        timestamp: now,
        type: MessageType.track,
        trackData: track,
      );

      final batch = _firestore.batch();

      final msgRef = _chatsRef.doc(chatId).collection(FirestoreCollections.messages).doc();
      batch.set(msgRef, message.toFirestore());

      batch.update(_chatsRef.doc(chatId), {
        'lastMessage': '🎵 ${track.title}',
        'lastMessageTime': Timestamp.fromDate(now),
        'unreadCounts.$otherUid': FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e, stack) {
      await reportError(e, stack);
      rethrow;
    }
  }

  /// Añade o quita una reacción del usuario actual en un mensaje.
  /// Usa una transacción para evitar race conditions cuando varios
  /// usuarios reaccionan al mismo mensaje simultáneamente.
  Future<void> toggleReaction(
      String chatId, String messageId, String emoji) async {
    try {
      final msgRef =
          _chatsRef.doc(chatId).collection(FirestoreCollections.messages).doc(messageId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(msgRef);
        if (!doc.exists) return;

        final data = doc.data()!;
        final reactions =
            Map<String, dynamic>.from(data['reactions'] as Map? ?? {});
        final users = List<String>.from(reactions[emoji] as List? ?? []);

        if (users.contains(_currentUid)) {
          users.remove(_currentUid);
        } else {
          users.add(_currentUid);
        }

        if (users.isEmpty) {
          reactions.remove(emoji);
        } else {
          reactions[emoji] = users;
        }

        transaction.update(msgRef, {'reactions': reactions});
      });
    } catch (e, stack) {
      await reportError(e, stack);
    }
  }
}
