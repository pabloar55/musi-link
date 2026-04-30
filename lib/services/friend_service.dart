import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:musi_link/services/authenticated_service.dart';
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
class FriendService with AuthenticatedService {
  FriendService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  FirebaseAuth get auth => _auth;
  late final CollectionReference<Map<String, dynamic>> _requestsRef = _firestore
      .collection(FirestoreCollections.friendRequests);
  late final CollectionReference<Map<String, dynamic>> _privateUsersRef =
      _firestore.collection(FirestoreCollections.userPrivate);
  late final CollectionReference<Map<String, dynamic>> _rateLimitsRef =
      _firestore.collection(FirestoreCollections.rateLimits);

  static const Duration _friendRequestRateLimitWindow = Duration(minutes: 10);

  Map<String, Object?> _nextFriendRequestRateLimit(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final data = snap.data() ?? const <String, dynamic>{};
    final windowStart = data['friendRequestWindowStart'] as Timestamp?;
    final count = (data['friendRequestCount'] as int?) ?? 0;
    final shouldReset =
        windowStart == null ||
        DateTime.now().difference(windowStart.toDate()) >
            _friendRequestRateLimitWindow;

    return {
      'lastFriendRequestAt': FieldValue.serverTimestamp(),
      'friendRequestWindowStart': shouldReset
          ? FieldValue.serverTimestamp()
          : windowStart,
      'friendRequestCount': shouldReset ? 1 : count + 1,
    };
  }

  // ─── Solicitudes ────────────────────────────────────────

  /// Envía una solicitud de amistad a [receiverUid].
  Future<void> sendRequest(String receiverUid) async {
    if (receiverUid == currentUid) return;
    final now = DateTime.now();
    final docId = '${currentUid}_$receiverUid';
    final request = FriendRequest(
      id: docId,
      senderId: currentUid,
      receiverId: receiverUid,
      status: FriendRequestStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
    try {
      // Atomic read-then-write on the deterministic doc ID eliminates the
      // check-then-act race without a collection query.
      final docRef = _requestsRef.doc(docId);
      final inverseDocRef = _requestsRef.doc('${receiverUid}_$currentUid');
      final limiterRef = _rateLimitsRef.doc(currentUid);
      final currentUserRef = _privateUsersRef.doc(currentUid);
      final receiverUserRef = _privateUsersRef.doc(receiverUid);
      await _firestore.runTransaction((tx) async {
        final currentUserSnap = await tx.get(currentUserRef);
        final friends = List<String>.from(
          currentUserSnap.data()?['friends'] as List? ?? [],
        );
        if (friends.contains(receiverUid)) return;

        final inverseSnapshot = await tx.get(inverseDocRef);
        if (inverseSnapshot.exists &&
            inverseSnapshot.data()?['status'] ==
                FriendRequestStatus.pending.name) {
          tx.update(inverseDocRef, {
            'status': FriendRequestStatus.accepted.name,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          tx.update(currentUserRef, {
            'friends': FieldValue.arrayUnion([receiverUid]),
          });
          tx.update(receiverUserRef, {
            'friends': FieldValue.arrayUnion([currentUid]),
          });
          return;
        }

        final snapshot = await tx.get(docRef);
        if (snapshot.exists) return;

        final limiterSnap = await tx.get(limiterRef);
        tx.set(docRef, {
          ...request.toFirestore(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        tx.set(
          limiterRef,
          _nextFriendRequestRateLimit(limiterSnap),
          SetOptions(merge: true),
        );
      });
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
        final requestRef = _requestsRef.doc(requestId);
        final requestDoc = await tx.get(requestRef);

        if (!requestDoc.exists ||
            requestDoc['status'] != FriendRequestStatus.pending.name) {
          return; // ya fue aceptada o rechazada
        }

        final senderId = (requestDoc.data()?['senderId'] ?? otherUid)
            .toString();
        final receiverId = (requestDoc.data()?['receiverId'] ?? currentUid)
            .toString();
        final inverseRef = _requestsRef.doc('${receiverId}_$senderId');
        final inverseSnap = await tx.get(inverseRef);

        tx.update(requestRef, {
          'status': FriendRequestStatus.accepted.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        tx.update(_privateUsersRef.doc(currentUid), {
          'friends': FieldValue.arrayUnion([otherUid]),
        });
        tx.update(_privateUsersRef.doc(otherUid), {
          'friends': FieldValue.arrayUnion([currentUid]),
        });
        if (inverseSnap.exists) tx.delete(inverseRef);
      });
    } catch (e, stack) {
      await reportError(e, stack);
      rethrow;
    }
  }

  /// Rechaza una solicitud de amistad.
  Future<void> rejectRequest(String requestId) async {
    try {
      await _requestsRef.doc(requestId).delete();
    } catch (e, stack) {
      await reportError(e, stack);
      rethrow;
    }
  }

  /// Cancela (elimina) una solicitud de amistad enviada.
  Future<void> cancelRequest(String requestId) async {
    try {
      await _firestore.runTransaction((tx) async {
        final docRef = _requestsRef.doc(requestId);
        final snapshot = await tx.get(docRef);
        if (!snapshot.exists ||
            snapshot.data()?['senderId'] != currentUid ||
            snapshot.data()?['status'] != FriendRequestStatus.pending.name) {
          return;
        }
        tx.delete(docRef);
      });
    } catch (e, stack) {
      await reportError(e, stack);
      rethrow;
    }
  }

  // ─── Streams ────────────────────────────────────────────

  /// Stream de solicitudes de amistad recibidas pendientes.
  Stream<List<FriendRequest>> getReceivedRequests() {
    return _requestsRef
        .where('receiverId', isEqualTo: currentUid)
        .where('status', isEqualTo: FriendRequestStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((e, st) => reportError(e, st).ignore())
        .map(
          (snapshot) => snapshot.docs.map(FriendRequest.fromFirestore).toList(),
        );
  }

  /// Stream de solicitudes de amistad enviadas pendientes.
  Stream<List<FriendRequest>> getSentRequests() {
    return _requestsRef
        .where('senderId', isEqualTo: currentUid)
        .where('status', isEqualTo: FriendRequestStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((e, st) => reportError(e, st).ignore())
        .map(
          (snapshot) => snapshot.docs.map(FriendRequest.fromFirestore).toList(),
        );
  }

  /// Stream de la lista de amigos del usuario actual.
  Stream<List<String>> getFriendsStream() {
    return _privateUsersRef
        .doc(currentUid)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return <String>[];
          final data = doc.data();
          if (data == null) return <String>[];
          return List<String>.from(data['friends'] as List? ?? []);
        })
        .distinct((a, b) => a.length == b.length && a.toSet().containsAll(b));
  }

  /// Obtiene la lista privada de amigos del usuario actual.
  Future<List<String>> getFriends() async {
    try {
      final doc = await _privateUsersRef.doc(currentUid).get();
      if (!doc.exists) return const <String>[];
      return List<String>.from(doc.data()?['friends'] as List? ?? []);
    } catch (e, stack) {
      await reportError(e, stack);
      rethrow;
    }
  }

  // ─── Consultas ──────────────────────────────────────────

  /// Comprueba si el usuario actual es amigo de [otherUid].
  Future<bool> areFriends(String otherUid) async {
    try {
      final doc = await _privateUsersRef.doc(currentUid).get();
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
      final results = await Future.wait([
        _privateUsersRef.doc(currentUid).get(),
        _requestsRef
            .where('senderId', isEqualTo: currentUid)
            .where('receiverId', isEqualTo: otherUid)
            .where('status', isEqualTo: FriendRequestStatus.pending.name)
            .limit(1)
            .get(),
        _requestsRef
            .where('senderId', isEqualTo: otherUid)
            .where('receiverId', isEqualTo: currentUid)
            .where('status', isEqualTo: FriendRequestStatus.pending.name)
            .limit(1)
            .get(),
      ]);

      final userDoc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final sent = results[1] as QuerySnapshot<Map<String, dynamic>>;
      final received = results[2] as QuerySnapshot<Map<String, dynamic>>;

      final friends = List<String>.from(
        userDoc.data()?['friends'] as List? ?? [],
      );
      if (friends.contains(otherUid)) {
        return const RelationshipResult(RelationshipStatus.friends);
      }
      if (sent.docs.isNotEmpty) {
        return RelationshipResult(
          RelationshipStatus.requestSent,
          sent.docs.first.id,
        );
      }
      if (received.docs.isNotEmpty) {
        return RelationshipResult(
          RelationshipStatus.requestReceived,
          received.docs.first.id,
        );
      }

      return const RelationshipResult(RelationshipStatus.none);
    } catch (e, stack) {
      await reportError(e, stack);
      rethrow;
    }
  }

  /// Escucha en tiempo real la relacin con [otherUid].
  Stream<RelationshipResult> watchRelationship(String otherUid) {
    late final StreamController<RelationshipResult> controller;
    final subscriptions = <StreamSubscription<Object?>>[];
    DocumentSnapshot<Map<String, dynamic>>? userDoc;
    DocumentSnapshot<Map<String, dynamic>>? sentDoc;
    DocumentSnapshot<Map<String, dynamic>>? receivedDoc;

    RelationshipResult relationshipFromSnapshots() {
      final friends = List<String>.from(
        userDoc?.data()?['friends'] as List? ?? [],
      );
      if (friends.contains(otherUid)) {
        return const RelationshipResult(RelationshipStatus.friends);
      }

      if (sentDoc?.data()?['status'] == FriendRequestStatus.pending.name) {
        return RelationshipResult(RelationshipStatus.requestSent, sentDoc!.id);
      }

      if (receivedDoc?.data()?['status'] == FriendRequestStatus.pending.name) {
        return RelationshipResult(
          RelationshipStatus.requestReceived,
          receivedDoc!.id,
        );
      }

      return const RelationshipResult(RelationshipStatus.none);
    }

    void emitRelationship() {
      if (!controller.isClosed) controller.add(relationshipFromSnapshots());
    }

    controller = StreamController<RelationshipResult>(
      onListen: () {
        subscriptions.add(
          _privateUsersRef.doc(currentUid).snapshots().listen((snapshot) {
            userDoc = snapshot;
            emitRelationship();
          }),
        );
        subscriptions.add(
          _requestsRef.doc('${currentUid}_$otherUid').snapshots().listen((
            snapshot,
          ) {
            sentDoc = snapshot;
            emitRelationship();
          }),
        );
        subscriptions.add(
          _requestsRef.doc('${otherUid}_$currentUid').snapshots().listen((
            snapshot,
          ) {
            receivedDoc = snapshot;
            emitRelationship();
          }),
        );
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );

    return controller.stream.distinct(
      (a, b) => a.status == b.status && a.requestId == b.requestId,
    );
  }

  // ─── Eliminar cuenta ────────────────────────────────────

  /// Elimina todos los datos de amistad de [uid]:
  /// lo quita del array `friends` de sus amigos y borra todas sus solicitudes.
  Future<void> deleteAllUserFriendData(String uid) async {
    try {
      // Quitar uid del array friends de cada amigo suyo
      final userDoc = await _privateUsersRef.doc(uid).get();
      final friends = List<String>.from(
        userDoc.data()?['friends'] as List? ?? [],
      );
      const batchSize = 400;
      for (var i = 0; i < friends.length; i += batchSize) {
        final chunk = friends.sublist(
          i,
          (i + batchSize).clamp(0, friends.length),
        );
        final batch = _firestore.batch();
        for (final friendUid in chunk) {
          batch.update(_privateUsersRef.doc(friendUid), {
            'friends': FieldValue.arrayRemove([uid]),
          });
        }
        await batch.commit();
      }

      // Eliminar todas las solicitudes de amistad (enviadas y recibidas)
      final sent = await _requestsRef.where('senderId', isEqualTo: uid).get();
      final received = await _requestsRef
          .where('receiverId', isEqualTo: uid)
          .get();
      final allDocs = [...sent.docs, ...received.docs];
      const requestBatchSize = 400;
      for (var i = 0; i < allDocs.length; i += requestBatchSize) {
        final chunk = allDocs.sublist(
          i,
          (i + requestBatchSize).clamp(0, allDocs.length),
        );
        final batch = _firestore.batch();
        for (final doc in chunk) {
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
      batch.update(_privateUsersRef.doc(currentUid), {
        'friends': FieldValue.arrayRemove([otherUid]),
      });
      batch.update(_privateUsersRef.doc(otherUid), {
        'friends': FieldValue.arrayRemove([currentUid]),
      });
      await batch.commit();
    } catch (e, stack) {
      await reportError(e, stack);
      rethrow;
    }
  }
}
