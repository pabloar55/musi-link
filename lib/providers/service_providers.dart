import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musi_link/models/chat.dart';
import 'package:musi_link/models/friend_request.dart';
import 'package:musi_link/providers/firebase_providers.dart';
import 'package:musi_link/services/auth_service.dart';
import 'package:musi_link/services/chat_service.dart';
import 'package:musi_link/services/friend_service.dart';
import 'package:musi_link/services/music_profile_service.dart';
import 'package:musi_link/services/spotify_service.dart';
import 'package:musi_link/services/spotify_stats_service.dart';
import 'package:musi_link/services/user_service.dart';

// ── Servicios sin dependencias ──────────────────────────────────

final userServiceProvider = Provider<UserService>((ref) {
  return UserService(firestore: ref.watch(firebaseFirestoreProvider));
});

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(
    firestore: ref.watch(firebaseFirestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
});

final friendServiceProvider = Provider<FriendService>((ref) {
  return FriendService(
    firestore: ref.watch(firebaseFirestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
});

// ── Servicios con dependencias ──────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(userServiceProvider),
    auth: ref.watch(firebaseAuthProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  );
});

final Provider<SpotifyService> spotifyServiceProvider =
    Provider<SpotifyService>((ref) {
  final service = SpotifyService(
    userService: ref.watch(userServiceProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
  ref.onDispose(service.stopPollingNowPlaying);
  return service;
});

final Provider<SpotifyGetStats> spotifyStatsProvider =
    Provider<SpotifyGetStats>((ref) {
  return SpotifyGetStats(ref.watch(spotifyServiceProvider));
});

final Provider<MusicProfileService> musicProfileServiceProvider =
    Provider<MusicProfileService>((ref) {
  return MusicProfileService(
    ref.watch(spotifyStatsProvider),
    firestore: ref.watch(firebaseFirestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
});

// ── StreamProviders de Firestore ────────────────────────────────

final receivedRequestsProvider = StreamProvider<List<FriendRequest>>((ref) {
  return ref.watch(friendServiceProvider).getReceivedRequests();
});

final sentRequestsProvider = StreamProvider<List<FriendRequest>>((ref) {
  return ref.watch(friendServiceProvider).getSentRequests();
});

final friendsStreamProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(friendServiceProvider).getFriendsStream();
});

final chatsProvider = StreamProvider<List<Chat>>((ref) {
  return ref.watch(chatServiceProvider).getChats();
});
