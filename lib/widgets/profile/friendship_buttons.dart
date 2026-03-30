import 'package:flutter/material.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/services/friend_service.dart';

class FriendshipButtons extends StatelessWidget {
  final Future<RelationshipResult> future;
  final VoidCallback onStartChat;
  final VoidCallback onSendRequest;
  final void Function(String requestId) onAcceptRequest;
  final void Function(String requestId) onRejectRequest;
  final void Function(String requestId) onCancelRequest;
  final VoidCallback onRemoveFriend;

  const FriendshipButtons({
    super.key,
    required this.future,
    required this.onStartChat,
    required this.onSendRequest,
    required this.onAcceptRequest,
    required this.onRejectRequest,
    required this.onCancelRequest,
    required this.onRemoveFriend,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<RelationshipResult>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 40,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final relationship =
            snapshot.data ?? const RelationshipResult(RelationshipStatus.none);

        switch (relationship.status) {
          case RelationshipStatus.friends:
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.icon(
                  onPressed: onStartChat,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text(l10n.profileStartChat),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onRemoveFriend,
                  icon: Icon(Icons.person_remove, color: colorScheme.error),
                  label: Text(
                    l10n.friendsRemove,
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
              ],
            );

          case RelationshipStatus.requestSent:
            return OutlinedButton.icon(
              onPressed: () {
                if (relationship.requestId != null) {
                  onCancelRequest(relationship.requestId!);
                }
              },
              icon: const Icon(Icons.hourglass_top),
              label: Text(l10n.friendsRequestSent),
            );

          case RelationshipStatus.requestReceived:
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.icon(
                  onPressed: () {
                    if (relationship.requestId != null) {
                      onAcceptRequest(relationship.requestId!);
                    }
                  },
                  icon: const Icon(Icons.check),
                  label: Text(l10n.friendsAccept),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    if (relationship.requestId != null) {
                      onRejectRequest(relationship.requestId!);
                    }
                  },
                  icon: const Icon(Icons.close),
                  label: Text(l10n.friendsReject),
                ),
              ],
            );

          case RelationshipStatus.none:
            return FilledButton.icon(
              onPressed: onSendRequest,
              icon: const Icon(Icons.person_add),
              label: Text(l10n.profileAddFriend),
            );
        }
      },
    );
  }
}
