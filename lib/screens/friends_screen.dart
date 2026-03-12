import 'package:flutter/material.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/core/friend_service.dart';
import 'package:musi_link/core/models/app_user.dart';
import 'package:musi_link/core/models/friend_request.dart';
import 'package:musi_link/core/user_future_cache.dart';
import 'package:musi_link/screens/user_profile_screen.dart';
import 'package:musi_link/components/remove_friend_dialog.dart';
import 'package:musi_link/components/user_circle_avatar.dart';
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
          _SectionHeader(title: l10n.friendsReceivedRequests),
          StreamBuilder<List<FriendRequest>>(
            stream: FriendService.instance.getReceivedRequests(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final requests = snapshot.data ?? [];
              if (requests.isEmpty) {
                return _EmptyMessage(text: l10n.friendsNoRequests);
              }
              return Column(
                children: requests.map((request) {
                  return _RequestTile(
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
          _SectionHeader(title: l10n.friendsSentRequests),
          StreamBuilder<List<FriendRequest>>(
            stream: FriendService.instance.getSentRequests(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final requests = snapshot.data ?? [];
              if (requests.isEmpty) {
                return _EmptyMessage(text: l10n.friendsNoRequests);
              }
              return Column(
                children: requests.map((request) {
                  return _RequestTile(
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
          _SectionHeader(title: l10n.friendsMyFriends),
          StreamBuilder<List<String>>(
            stream: FriendService.instance.getFriendsStream(),
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
                    _EmptyMessage(text: l10n.friendsNoFriends),
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
                  return _FriendTile(
                    uid: uid,
                    getUserFuture: getUserFuture,
                    onTap: (user) {
                      if (user != null) {
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

// ─── Widgets auxiliares ─────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final String text;
  const _EmptyMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
          fontSize: 14,
        ),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final String uid;
  final Future<AppUser?> Function(String) getUserFuture;
  final Widget trailing;

  const _RequestTile({
    required this.uid,
    required this.getUserFuture,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: getUserFuture(uid),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final isLoading = snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;
        final name = user?.displayName ??
            (isLoading
                ? AppLocalizations.of(context)!.socialLoading
                : AppLocalizations.of(context)!.socialUser);
        final photoUrl = user?.photoUrl ?? '';

        return ListTile(
          leading: UserCircleAvatar(
            photoUrl: photoUrl,
            name: name,
          ),
          title:
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: trailing,
        );
      },
    );
  }
}

class _FriendTile extends StatelessWidget {
  final String uid;
  final Future<AppUser?> Function(String) getUserFuture;
  final void Function(AppUser?) onTap;
  final void Function(AppUser?) onLongPress;

  const _FriendTile({
    required this.uid,
    required this.getUserFuture,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: getUserFuture(uid),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final isLoading = snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;
        final name = user?.displayName ??
            (isLoading
                ? AppLocalizations.of(context)!.socialLoading
                : AppLocalizations.of(context)!.socialUser);
        final photoUrl = user?.photoUrl ?? '';

        return ListTile(
          leading: UserCircleAvatar(
            photoUrl: photoUrl,
            name: name,
          ),
          title:
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          onTap: () => onTap(user),
          onLongPress: () => onLongPress(user),
        );
      },
    );
  }
}
