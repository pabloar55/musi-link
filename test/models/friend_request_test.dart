import 'package:flutter_test/flutter_test.dart';
import 'package:musi_link/models/friend_request.dart';

void main() {
  group('FriendRequest', () {
    final now = DateTime(2025, 6, 15, 10, 0);

    group('constructor', () {
      test('crea FriendRequest con todos los campos', () {
        final request = FriendRequest(
          id: 'req1',
          senderId: 'user1',
          receiverId: 'user2',
          status: FriendRequestStatus.pending,
          createdAt: now,
          updatedAt: now,
        );

        expect(request.id, 'req1');
        expect(request.senderId, 'user1');
        expect(request.receiverId, 'user2');
        expect(request.status, FriendRequestStatus.pending);
      });
    });

    group('toFirestore', () {
      test('serializa correctamente con status pending', () {
        final request = FriendRequest(
          id: 'req1',
          senderId: 'user1',
          receiverId: 'user2',
          status: FriendRequestStatus.pending,
          createdAt: now,
          updatedAt: now,
        );

        final map = request.toFirestore();

        expect(map['senderId'], 'user1');
        expect(map['receiverId'], 'user2');
        expect(map['status'], 'pending');
        expect(map.containsKey('id'), false);
      });

      test('serializa correctamente con status accepted', () {
        final request = FriendRequest(
          id: 'req1',
          senderId: 'user1',
          receiverId: 'user2',
          status: FriendRequestStatus.accepted,
          createdAt: now,
          updatedAt: now,
        );

        final map = request.toFirestore();
        expect(map['status'], 'accepted');
      });

      test('serializa correctamente con status rejected', () {
        final request = FriendRequest(
          id: 'req1',
          senderId: 'user1',
          receiverId: 'user2',
          status: FriendRequestStatus.rejected,
          createdAt: now,
          updatedAt: now,
        );

        final map = request.toFirestore();
        expect(map['status'], 'rejected');
      });
    });
  });

  group('FriendRequestStatus', () {
    test('tiene 3 valores', () {
      expect(FriendRequestStatus.values.length, 3);
    });

    test('contiene pending, accepted, rejected', () {
      expect(FriendRequestStatus.values, contains(FriendRequestStatus.pending));
      expect(
          FriendRequestStatus.values, contains(FriendRequestStatus.accepted));
      expect(
          FriendRequestStatus.values, contains(FriendRequestStatus.rejected));
    });
  });
}
