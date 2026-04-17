import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musi_link/models/app_user.dart';
import 'package:musi_link/models/discovery_result.dart';
import 'package:musi_link/providers/firebase_providers.dart';
import 'package:musi_link/providers/service_providers.dart';
import 'package:musi_link/services/friend_service.dart';

final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) return Stream.value(null);
  return ref.watch(userServiceProvider).watchUser(uid);
});

final userStreamProvider = StreamProvider.family<AppUser?, String>((ref, uid) {
  return ref.read(userServiceProvider).watchUser(uid);
});

final compatibilityProvider =
    FutureProvider.family<DiscoveryResult, AppUser>((ref, user) async {
      final myUser = await ref.watch(currentUserProvider.future);
      if (myUser == null) {
        return DiscoveryResult(
          user: user,
          score: 0,
          sharedArtistNames: [],
          sharedGenreNames: [],
        );
      }
      return ref
          .read(musicProfileServiceProvider)
          .getCompatibilityWith(myUser, user);
    });

final relationshipProvider =
    FutureProvider.family<RelationshipResult, String>((ref, userUid) {
      return ref.read(friendServiceProvider).getRelationship(userUid);
    });
