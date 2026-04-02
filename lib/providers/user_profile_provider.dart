import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musi_link/models/app_user.dart';
import 'package:musi_link/models/discovery_result.dart';
import 'package:musi_link/providers/service_providers.dart';
import 'package:musi_link/services/friend_service.dart';

final compatibilityFutureProvider =
    FutureProvider.family<DiscoveryResult, AppUser>((ref, user) {
      return ref.read(musicProfileServiceProvider).getCompatibilityWith(user);
    });

final relationshipFutureProvider =
    FutureProvider.family<RelationshipResult, String>((ref, userUid) {
      return ref.read(friendServiceProvider).getRelationship(userUid);
    });
