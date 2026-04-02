import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/services/friend_service.dart';
import 'package:musi_link/widgets/skeleton_loader.dart';

class FriendshipButtons extends StatefulWidget {
  final AsyncValue<RelationshipResult> value;
  final VoidCallback onStartChat;
  final VoidCallback onSendRequest;
  final void Function(String requestId) onAcceptRequest;
  final void Function(String requestId) onRejectRequest;
  final void Function(String requestId) onCancelRequest;
  final VoidCallback onRemoveFriend;

  const FriendshipButtons({
    super.key,
    required this.value,
    required this.onStartChat,
    required this.onSendRequest,
    required this.onAcceptRequest,
    required this.onRejectRequest,
    required this.onCancelRequest,
    required this.onRemoveFriend,
  });

  @override
  State<FriendshipButtons> createState() => _FriendshipButtonsState();
}

class _FriendshipButtonsState extends State<FriendshipButtons> {
  /// Estado optimista local. Cuando no es null, se usa en lugar del valor real
  /// para evitar el spinner mientras Firestore confirma la operación.
  RelationshipStatus? _optimisticStatus;

  void _handleSendRequest() {
    setState(() => _optimisticStatus = RelationshipStatus.requestSent);
    widget.onSendRequest();
  }

  void _handleCancelRequest(String requestId) {
    setState(() => _optimisticStatus = RelationshipStatus.none);
    widget.onCancelRequest(requestId);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final relationship = widget.value.valueOrNull;
    final isLoading = widget.value.isLoading;
    final hasError = widget.value.hasError;

    if (isLoading && _optimisticStatus == null) {
      return const SkeletonShimmer(child: SkeletonFriendshipButtons());
    }

    if (hasError && relationship == null) return const SizedBox.shrink();

    if (!isLoading &&
        _optimisticStatus != null &&
        relationship?.status == _optimisticStatus) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => setState(() => _optimisticStatus = null),
      );
    }

    final status = _optimisticStatus ?? relationship?.status ?? RelationshipStatus.none;
    final requestId = relationship?.requestId;

    switch (status) {
      case RelationshipStatus.friends:
        return Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: widget.onStartChat,
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text(l10n.profileStartChat),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onRemoveFriend,
                icon: Icon(Icons.person_remove, color: cs.error),
                label: Text(
                  l10n.friendsRemove,
                  style: TextStyle(color: cs.error),
                ),
              ),
            ),
          ],
        );

      case RelationshipStatus.requestSent:
        return OutlinedButton.icon(
          onPressed: _optimisticStatus != null
              ? () {}
              : requestId != null
              ? () => _handleCancelRequest(requestId)
              : null,
          icon: const Icon(Icons.hourglass_top),
          label: Text(l10n.friendsRequestSent),
        );

      case RelationshipStatus.requestReceived:
        return Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: requestId != null
                    ? () => widget.onAcceptRequest(requestId)
                    : null,
                icon: const Icon(Icons.check),
                label: Text(l10n.friendsAccept),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: requestId != null
                    ? () => widget.onRejectRequest(requestId)
                    : null,
                icon: const Icon(Icons.close),
                label: Text(l10n.friendsReject),
              ),
            ),
          ],
        );

      case RelationshipStatus.none:
        return FilledButton.icon(
          onPressed: _handleSendRequest,
          icon: const Icon(Icons.person_add),
          label: Text(l10n.profileAddFriend),
        );
    }
  }
}
