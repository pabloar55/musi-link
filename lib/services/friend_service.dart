import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:musi_link/utils/error_reporter.dart';
import 'package:musi_link/models/friend_request.dart';
import 'package:musi_link/utils/firestore_collections.dart';

/// Estado de la relación entre el usuario actual y otro usuario.
enum RelationshipStatus { none, requestSent, requestReceived, friends }

/// Resultado de consultar la relación con otro usuario.
class RelationshipResult {
  final RelationshipStatus status;
  final String? requestId; // ID del friend_request si existe
  const RelationshipResult(this.status, [this.requestId]);
}

/// Servicio para gestionar solicitudes de amistad y amigos en Firestore.
class FriendService {
  FriendService({required FirebaseFirestore firestore, required FirebaseAuth auth})
      : _firestore = firestore,
        _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  late final CollectionReference<Map<String, dynamic>> _requestsRef =
      _firestore.collection(FirestoreCollections.friendRequests);
  late final CollectionReference<Map<String, dynamic>> _usersRef =
      _firestore.collection(FirestoreCollections.users);

  /// Returns the UID of the currently authenticated user.
  /// Throws [StateError] instead of crashing with a null-dereference if the
  /// session has been lost (race condition during deep-link / session restore).
  String get _currentUid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('FriendService: no authenticated user.');
    return uid;
  }

  // ─── Solicitudes ────────────────────────────────────────

  /// Envía una solicitud de amistad a [receiverUid].
  Future<void> sendRequest(String receiverUid) async {
    try {
      final now = DateTime.now();
      final request = FriendRequest(
        id: '',
        senderId: _currentUid,
        receiverId: receiverUid,
        status: FriendRequestStatus.pending,
        createdAt: now,
        updatedAt: now,
      );
      await _requestsRef.add(request.toFirestore());
    } catch (e, stack) {
      await reportError(e, stack);
      rethrow;
    }
  }

  /// Acepta una solicitud de amistad.
  /// Actualiza el status y añade ambos UIDs a la lista de amigos de cada uno.
  /// Usa una transaction para evitar race conditions si dos dispositivos
  /// aceptan la misma solicitud simultáneamente.
  Future<void> acceptRequest(String requestId, String otherUid) async {
    try {
      await _firestore.runTransaction((tx) async {
        final requestDoc = await tx.get(_requestsRef.doc(requestId));

        if (!requestDoc.exists ||
            requestDoc['status'] != FriendRequestStatus.pending.name) {
          return; // ya fue aceptada o rechazada
        }

        final now = Timestamp.fromDate(DateTime.now());

        tx.update(_requestsRef.doc(requestId), {
          'status': FriendRequestStatus.accepted.name,
          'updatedAt': now,
        });
        tx.update(_usersRef.doc(_currentUid), {
          'friends': FieldValue.arrayUnion([otherUid]),
        });
        tx.update(_usersRef.doc(otherUid), {
          'friends': FieldValue.arrayUnion([_currentUid]),
        });
      });
    } catch (e, stack) {
      await reportError(e, stack);
      rethrow;
    }
  }

  /// Rechaza una solicitud de amistad.
  Future<void> rejectRequest(String requestId) async {
    try {
      await _requestsRef.doc(requestId).update({
        'status': FriendRequestStatus.rejected.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e, stack) {
      await reportError(e, stack);
      rethrow;
    }
  }

  /// Cancela (elimina) una solicitud de amistad enviada.
  Future<void> cancelRequest(String requestId) async {
    try {
      await _requestsRef.doc(requestId).delete();
    } catch (e, stack) {
      await reportError(e, stack);
      rethrow;
    }
  }

  // ─── Streams ────────────────────────────────────────────

  /// Stream de solicitudes de amistad recibidas pendientes.
  Stream<List<FriendRequest>> getReceivedRequests() {
    return _requestsRef
        .where('receiverId', isEqualTo: _currentUid)
        .where('status', isEqualTo: FriendRequestStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((e, st) => reportError(e, st).ignore())
        .map((snapshot) =>
            snapshot.docs.map(FriendRequest.fromFirestore).toList());
  }

  /// Stream de solicitudes de amistad enviadas pendientes.
  Stream<List<FriendRequest>> getSentRequests() {
    return _requestsRef
        .where('senderId', isEqualTo: _currentUid)
        .where('status', isEqualTo: FriendRequestStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((e, st) => reportError(e, st).ignore())
        .map((snapshot) =>
            snapshot.docs.map(FriendRequest.fromFirestore).toList());
  }

  /// Stream de la lista de amigos del usuario actual.
  Stream<List<String>> getFriendsStream() {
    return _usersRef
        .doc(_currentUid)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return <String>[];
          final data = doc.data();
          if (data == null) return <String>[];
          return List<String>.from(data['friends'] as List? ?? []);
        });
  }

  // ─── Consultas ──────────────────────────────────────────

  /// Comprueba si el usuario actual es amigo de [otherUid].
  Future<bool> areFriends(String otherUid) async {
    try {
      final doc = await _usersRef.doc(_currentUid).get();
      if (!doc.exists) return false;
      final friends = List<String>.from(doc.data()?['friends'] as List? ?? []);
      return friends.contains(otherUid);
    } catch (e, stack) {
      await reportError(e, stack);
      rethrow;
    }
  }

  /// Obtiene el estado de la relación con [otherUid].
  Future<RelationshipResult> getRelationship(String otherUid) async {
    try {
      // ¿Son amigos?
      final userDoc = await _usersRef.doc(_currentUid).get();
      final friends =
          List<String>.from(userDoc.data()?['friends'] as List? ?? []);
      if (friends.contains(otherUid)) {
        return const RelationshipResult(RelationshipStatus.friends);
      }

      // ¿Solicitud enviada pendiente?
      final sent = await _requestsRef
          .where('senderId', isEqualTo: _currentUid)
          .where('receiverId', isEqualTo: otherUid)
          .where('status', isEqualTo: FriendRequestStatus.pending.name)
          .limit(1)
          .get();
      if (sent.docs.isNotEmpty) {
        return RelationshipResult(
            RelationshipStatus.requestSent, sent.docs.first.id);
      }

      // ¿Solicitud recibida pendiente?
      final received = await _requestsRef
          .where('senderId', isEqualTo: otherUid)
          .where('receiverId', isEqualTo: _currentUid)
          .where('status', isEqualTo: FriendRequestStatus.pending.name)
          .limit(1)
          .get();
      if (received.docs.isNotEmpty) {
        return RelationshipResult(
            RelationshipStatus.requestReceived, received.docs.first.id);
      }

      return const RelationshipResult(RelationshipStatus.none);
    } catch (e, stack) {
      await reportError(e, stack);
      rethrow;
    }
  }

  // ─── Eliminar cuenta ────────────────────────────────────

  /// Elimina todos los datos de amistad de [uid]:
  /// lo quita del array `friends` de sus amigos y borra todas sus solicitudes.
  Future<void> deleteAllUserFriendData(String uid) async {
    try {
      // Quitar uid del array friends de cada amigo suyo
      final userDoc = await _usersRef.doc(uid).get();
      final friends = List<String>.from(
        userDoc.data()?['friends'] as List? ?? [],
      );
      if (friends.isNotEmpty) {
        final batch = _firestore.batch();
        for (final friendUid in friends) {
          batch.update(_usersRef.doc(friendUid), {
            'friends': FieldValue.arrayRemove([uid]),
          });
        }
        await batch.commit();
      }

      // Eliminar todas las solicitudes de amistad (enviadas y recibidas)
      final sent = await _requestsRef
          .where('senderId', isEqualTo: uid)
          .get();
      final received = await _requestsRef
          .where('receiverId', isEqualTo: uid)
          .get();
      final allDocs = [...sent.docs, ...received.docs];
      if (allDocs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in allDocs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (e, stack) {
      await reportError(e, stack);
      rethrow;
    }
  }

  // ─── Eliminar amigo ─────────────────────────────────────

  /// Elimina a [otherUid] de la lista de amigos de ambos.
  Future<void> removeFriend(String otherUid) async {
    try {
      final batch = _firestore.batch();
      batch.update(_usersRef.doc(_currentUid), {
        'friends': FieldValue.arrayRemove([otherUid]),
      });
      batch.update(_usersRef.doc(otherUid), {
        'friends': FieldValue.arrayRemove([_currentUid]),
      });
      await batch.commit();
    } catch (e, stack) {
      await reportError(e, stack);
      rethrow;
    }
  }
}
