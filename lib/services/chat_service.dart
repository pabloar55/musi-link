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

  /// Returns the UID of the currently authenticated user.
  /// Throws [StateError] instead of crashing if the session is lost.
  String get _currentUid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('ChatService: no authenticated user.');
    return uid;
  }

  // ─── Chats ────────────────────────────────────────────────

  /// Crea un chat entre el usuario actual y [otherUid].
  /// Si ya existe un chat entre ambos, devuelve el existente.
  Future<Chat> getOrCreateChat(String otherUid) async {
    try {
      // Buscar si ya existe un chat entre los dos usuarios
      final existing = await _chatsRef
          .where('participants', arrayContains: _currentUid)
          .get();

      for (final doc in existing.docs) {
        final participants = List<String>.from(doc['participants'] ?? []);
        if (participants.contains(otherUid)) {
          return Chat.fromFirestore(doc);
        }
      }

      // Crear un chat nuevo
      final now = DateTime.now();
      final chat = Chat(
        id: '',
        participants: [_currentUid, otherUid],
        lastMessageTime: now,
        createdAt: now,
      );

      final docRef = await _chatsRef.add(chat.toFirestore());
      final newDoc = await docRef.get();
      return Chat.fromFirestore(newDoc);
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
        .handleError(reportError)
        .map((snapshot) =>
            snapshot.docs.map(Chat.fromFirestore).toList());
  }

  /// Elimina un chat y todos sus mensajes.
  Future<void> deleteChat(String chatId) async {
    try {
      // Eliminar todos los mensajes de la subcolección
      final messages =
          await _chatsRef.doc(chatId).collection(FirestoreCollections.messages).get();
      final batch = _firestore.batch();
      for (final doc in messages.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_chatsRef.doc(chatId));
      await batch.commit();
    } catch (e, stack) {
      await reportError(e, stack);
      rethrow;
    }
  }

  //  Mensajes

  /// Envía un mensaje de texto en un chat.
  Future<void> sendMessage(String chatId, String text) async {
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

      // Actualizar último mensaje en el documento del chat
      batch.update(_chatsRef.doc(chatId), {
        'lastMessage': text,
        'lastMessageTime': Timestamp.fromDate(now),
      });

      await batch.commit();
    } catch (e, stack) {
      await reportError(e, stack);
      rethrow;
    }
  }

  /// Stream de mensajes de un chat, ordenados cronológicamente.
  Stream<List<Message>> getMessages(String chatId) {
    return _chatsRef
        .doc(chatId)
        .collection(FirestoreCollections.messages)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(Message.fromFirestore).toList());
  }

  /// Marca todos los mensajes no leídos del otro usuario como leídos.
  Future<void> markMessagesAsRead(String chatId) async {
    try {
      final unread = await _chatsRef
          .doc(chatId)
          .collection(FirestoreCollections.messages)
          .where('read', isEqualTo: false)
          .where('senderId', isNotEqualTo: _currentUid)
          .get();

      if (unread.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e, stack) {
      await reportError(e, stack);
    }
  }

  /// Cuenta los mensajes no leídos del usuario actual en un chat.
  Stream<int> getUnreadCount(String chatId) {
    return _chatsRef
        .doc(chatId)
        .collection(FirestoreCollections.messages)
        .where('read', isEqualTo: false)
        .where('senderId', isNotEqualTo: _currentUid)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Envía una canción como mensaje en un chat.
  Future<void> sendTrackMessage(String chatId, Track track) async {
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
