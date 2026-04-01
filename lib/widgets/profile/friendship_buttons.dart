import 'package:flutter/material.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/services/friend_service.dart';

class FriendshipButtons extends StatefulWidget {
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
  State<FriendshipButtons> createState() => _FriendshipButtonsState();
}

class _FriendshipButtonsState extends State<FriendshipButtons> {
  /// Estado optimista local. Cuando no es null, se usa en lugar del future
  /// para evitar el spinner mientras Firestore confirma la operación.
  RelationshipStatus? _optimisticStatus;

  void _handleSendRequest() {
    setState(() => _optimisticStatus = RelationshipStatus.requestSent);
    widget.onSendRequest();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<RelationshipResult>(
      future: widget.future,
      builder: (context, snapshot) {
        // Mientras el future está cargando y hay un estado optimista,
        // mostramos el estado optimista en lugar del spinner.
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        if (isLoading && _optimisticStatus == null) {
          return const SizedBox(
            height: 40,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) return const SizedBox.shrink();

        // Cuando el future resuelve, descartamos el estado optimista
        // y confiamos en el dato real de Firestore.
        if (!isLoading && _optimisticStatus != null) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => setState(() => _optimisticStatus = null),
          );
        }

        final status = _optimisticStatus
            ?? snapshot.data?.status
            ?? RelationshipStatus.none;
        final requestId = snapshot.data?.requestId;

        switch (status) {
          case RelationshipStatus.friends:
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.icon(
                  onPressed: widget.onStartChat,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text(l10n.profileStartChat),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: widget.onRemoveFriend,
                  icon: Icon(Icons.person_remove, color: cs.error),
                  label: Text(
                    l10n.friendsRemove,
                    style: TextStyle(color: cs.error),
                  ),
                ),
              ],
            );

          case RelationshipStatus.requestSent:
            return OutlinedButton.icon(
              onPressed: requestId != null
                  ? () => widget.onCancelRequest(requestId)
                  : null,
              icon: const Icon(Icons.hourglass_top),
              label: Text(l10n.friendsRequestSent),
            );

          case RelationshipStatus.requestReceived:
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.icon(
                  onPressed: requestId != null
                      ? () => widget.onAcceptRequest(requestId)
                      : null,
                  icon: const Icon(Icons.check),
                  label: Text(l10n.friendsAccept),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: requestId != null
                      ? () => widget.onRejectRequest(requestId)
                      : null,
                  icon: const Icon(Icons.close),
                  label: Text(l10n.friendsReject),
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
      },
    );
  }
}
