import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:musi_link/models/friend_request.dart';

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
      _firestore.collection('friend_requests');
  late final CollectionReference<Map<String, dynamic>> _usersRef =
      _firestore.collection('users');

  String get _currentUid => _auth.currentUser!.uid;

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
    } catch (e) {
      debugPrint("❌ Error al enviar solicitud: $e");
      rethrow;
    }
  }

  /// Acepta una solicitud de amistad.
  /// Actualiza el status y añade ambos UIDs a la lista de amigos de cada uno.
  Future<void> acceptRequest(String requestId, String otherUid) async {
    try {
      final batch = _firestore.batch();

      // Actualizar status del request
      batch.update(_requestsRef.doc(requestId), {
        'status': FriendRequestStatus.accepted.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Añadir a la lista de amigos de ambos usuarios
      batch.update(_usersRef.doc(_currentUid), {
        'friends': FieldValue.arrayUnion([otherUid]),
      });
      batch.update(_usersRef.doc(otherUid), {
        'friends': FieldValue.arrayUnion([_currentUid]),
      });

      await batch.commit();
    } catch (e) {
      debugPrint("❌ Error al aceptar solicitud: $e");
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
    } catch (e) {
      debugPrint("❌ Error al rechazar solicitud: $e");
      rethrow;
    }
  }

  /// Cancela (elimina) una solicitud de amistad enviada.
  Future<void> cancelRequest(String requestId) async {
    try {
      await _requestsRef.doc(requestId).delete();
    } catch (e) {
      debugPrint("❌ Error al cancelar solicitud: $e");
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
        .handleError((error) {
          debugPrint('❌ Error en stream de solicitudes recibidas: $error');
        })
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
        .handleError((error) {
          debugPrint('❌ Error en stream de solicitudes enviadas: $error');
        })
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
    } catch (e) {
      debugPrint("❌ Error al comprobar amistad: $e");
      return false;
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
    } catch (e) {
      debugPrint("❌ Error al obtener relación: $e");
      return const RelationshipResult(RelationshipStatus.none);
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
    } catch (e) {
      debugPrint("❌ Error al eliminar amigo: $e");
      rethrow;
    }
  }
}
