import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musi_link/models/chat.dart';
import 'package:musi_link/models/friend_request.dart';
import 'package:musi_link/providers/firebase_providers.dart';
import 'package:musi_link/providers/theme_provider.dart';
import 'package:musi_link/services/auth_service.dart';
import 'package:musi_link/services/chat_service.dart';
import 'package:musi_link/services/friend_service.dart';
import 'package:musi_link/services/music_profile_service.dart';
import 'package:musi_link/services/notification_service.dart';
import 'package:musi_link/services/last_fm_service.dart';
import 'package:musi_link/services/spotify_client_service.dart';
import 'package:musi_link/services/spotify_stats_service.dart';
import 'package:musi_link/services/storage_service.dart';
import 'package:musi_link/services/user_service.dart';

// ── Chat activo (suprime notificaciones del chat en pantalla) ──────

class ActiveChatNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setChat(String? chatId) => state = chatId;
}

final activeChatIdProvider =
    NotifierProvider<ActiveChatNotifier, String?>(ActiveChatNotifier.new);

// ── Notificación pendiente (cold-start o tap en local notification) ─

class PendingNotificationNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() => null;

  void setValue(Map<String, dynamic>? data) {
    state = data;
  }
}

final pendingNotificationProvider = NotifierProvider<PendingNotificationNotifier,
    Map<String, dynamic>?>(PendingNotificationNotifier.new);

// ── Servicios sin dependencias ──────────────────────────────────

final userServiceProvider = Provider<UserService>((ref) {
  return UserService(firestore: ref.watch(firebaseFirestoreProvider));
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(storage: ref.watch(firebaseStorageProvider));
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

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    messaging: ref.read(firebaseMessagingProvider),
    firestore: ref.read(firebaseFirestoreProvider),
    auth: ref.read(firebaseAuthProvider),
    prefs: ref.read(sharedPreferencesProvider),
    onNotificationTapped: (data) =>
        ref.read(pendingNotificationProvider.notifier).setValue(data),
    getActiveChatId: () => ref.read(activeChatIdProvider),
  );
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(userServiceProvider),
    auth: ref.watch(firebaseAuthProvider),
    googleSignIn: ref.watch(googleSignInProvider),
    notificationService: ref.watch(notificationServiceProvider),
  );
});

final Provider<SpotifyClientService> spotifyClientServiceProvider =
    Provider<SpotifyClientService>((ref) {
  return SpotifyClientService(
    clientId: const String.fromEnvironment('SPOTIFY_CLIENT_ID'),
    clientSecret: const String.fromEnvironment('SPOTIFY_CLIENT_SECRET'),
  );
});

final Provider<LastFmService> lastFmServiceProvider =
    Provider<LastFmService>((ref) {
  return LastFmService(
    apiKey: const String.fromEnvironment('LASTFM_API_KEY'),
  );
});

final Provider<SpotifyGetStats> spotifyStatsProvider =
    Provider<SpotifyGetStats>((ref) {
  return SpotifyGetStats(
    ref.watch(spotifyClientServiceProvider),
    ref.watch(lastFmServiceProvider),
  );
});

final Provider<MusicProfileService> musicProfileServiceProvider =
    Provider<MusicProfileService>((ref) {
  return MusicProfileService(
    ref.watch(spotifyStatsProvider),
    firestore: ref.watch(firebaseFirestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
});

// ── UI state ────────────────────────────────────────────────────

/// ID del mensaje cuyo reaction picker está abierto; null = ninguno.
class ActiveReactionPickerNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void open(String messageId) => state = messageId;
  void close() => state = null;
  void toggle(String messageId) =>
      state = state == messageId ? null : messageId;
}

final activeReactionPickerProvider =
    NotifierProvider<ActiveReactionPickerNotifier, String?>(
        ActiveReactionPickerNotifier.new);

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
