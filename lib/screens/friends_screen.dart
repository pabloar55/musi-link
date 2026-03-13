import 'package:flutter/material.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/services/friend_service.dart';
import 'package:musi_link/models/friend_request.dart';
import 'package:musi_link/utils/user_future_cache.dart';
import 'package:musi_link/widgets/friends/section_header.dart';
import 'package:musi_link/widgets/friends/empty_message.dart';
import 'package:musi_link/widgets/friends/request_tile.dart';
import 'package:musi_link/widgets/friends/friend_tile.dart';
import 'package:musi_link/screens/user_profile_screen.dart';
import 'package:musi_link/widgets/remove_friend_dialog.dart';
import 'package:musi_link/screens/user_search_screen.dart';

/// Pantalla de amigos: solicitudes pendientes + lista de amigos.
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with AutomaticKeepAliveClientMixin, UserFutureCache {
  @override
  bool get wantKeepAlive => true;

  late final Stream<List<FriendRequest>> _receivedRequestsStream;
  late final Stream<List<FriendRequest>> _sentRequestsStream;
  late final Stream<List<String>> _friendsStream;

  @override
  void initState() {
    super.initState();
    _receivedRequestsStream = FriendService.instance.getReceivedRequests();
    _sentRequestsStream = FriendService.instance.getSentRequests();
    _friendsStream = FriendService.instance.getFriendsStream();
  }

  Future<void> _showRemoveFriendDialog(String uid, String? name) async {
    final confirmed = await showRemoveFriendDialog(context);
    if (confirmed == true) {
      invalidateUserFuture(uid);
      await FriendService.instance.removeFriend(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ─── Solicitudes recibidas ───────────────────
          SectionHeader(title: l10n.friendsReceivedRequests),
          StreamBuilder<List<FriendRequest>>(
            stream: _receivedRequestsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final requests = snapshot.data ?? [];
              if (requests.isEmpty) {
                return EmptyMessage(text: l10n.friendsNoRequests);
              }
              return Column(
                children: requests.map((request) {
                  return RequestTile(
                    uid: request.senderId,
                    getUserFuture: getUserFuture,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.check_circle,
                              color: colorScheme.primary),
                          tooltip: l10n.friendsAccept,
                          onPressed: () => FriendService.instance
                              .acceptRequest(request.id, request.senderId),
                        ),
                        IconButton(
                          icon: Icon(Icons.cancel, color: colorScheme.error),
                          tooltip: l10n.friendsReject,
                          onPressed: () => FriendService.instance
                              .rejectRequest(request.id),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 8),

          // ─── Solicitudes enviadas ────────────────────
          SectionHeader(title: l10n.friendsSentRequests),
          StreamBuilder<List<FriendRequest>>(
            stream: _sentRequestsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final requests = snapshot.data ?? [];
              if (requests.isEmpty) {
                return EmptyMessage(text: l10n.friendsNoRequests);
              }
              return Column(
                children: requests.map((request) {
                  return RequestTile(
                    uid: request.receiverId,
                    getUserFuture: getUserFuture,
                    trailing: TextButton(
                      onPressed: () =>
                          FriendService.instance.cancelRequest(request.id),
                      child: Text(l10n.friendsCancel),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 8),

          // ─── Lista de amigos ─────────────────────────
          SectionHeader(title: l10n.friendsMyFriends),
          StreamBuilder<List<String>>(
            stream: _friendsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final friendUids = snapshot.data ?? [];
              if (friendUids.isEmpty) {
                return Column(
                  children: [
                    EmptyMessage(text: l10n.friendsNoFriends),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        l10n.friendsNoFriendsHint,
                        style: TextStyle(
                          color: colorScheme.onSurface.withAlpha(100),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                );
              }
              return Column(
                children: friendUids.map((uid) {
                  return FriendTile(
                    uid: uid,
                    getUserFuture: getUserFuture,
                    onTap: (user) {
                      if (user != null) {
                        // Invalida el caché para obtener los datos más recientes (ej. Now Playing)
                        invalidateUserFuture(user.uid);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => UserProfileScreen(user: user),
                          ),
                        );
                      }
                    },
                    onLongPress: (user) =>
                        _showRemoveFriendDialog(uid, user?.displayName),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const UserSearchScreen()),
          );
        },
        child: const Icon(Icons.person_search),
      ),
    );
  }
}

