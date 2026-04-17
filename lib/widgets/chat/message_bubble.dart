import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:musi_link/models/message.dart';
import 'package:musi_link/providers/service_providers.dart';
import 'package:musi_link/services/chat_service.dart';
import 'package:musi_link/theme/app_theme.dart';
import 'package:musi_link/widgets/chat/reaction_picker.dart';

class MessageBubble extends ConsumerWidget {
  final Message message;
  final bool isMe;
  final ColorScheme colorScheme;
  final String currentUid;
  final String chatId;
  final ChatService chatService;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.colorScheme,
    required this.currentUid,
    required this.chatId,
    required this.chatService,
  });

  void _toggleReaction(WidgetRef ref, String emoji) {
    chatService.toggleReaction(chatId, message.id, emoji);
    ref.read(activeReactionPickerProvider.notifier).close();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showingPicker =
        ref.watch(activeReactionPickerProvider) == message.id;
    final cs = colorScheme;
    final tt = Theme.of(context).textTheme;
    final time =
        '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onLongPress: () => ref
                .read(activeReactionPickerProvider.notifier)
                .toggle(message.id),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              margin: const EdgeInsets.symmetric(vertical: AppTokens.spaceXS),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spaceMD,
                vertical: AppTokens.spaceSM + 2,
              ),
              decoration: BoxDecoration(
                color: isMe ? cs.primary : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppTokens.radiusLG),
                  topRight: const Radius.circular(AppTokens.radiusLG),
                  bottomLeft: Radius.circular(isMe ? AppTokens.radiusLG : 4),
                  bottomRight: Radius.circular(isMe ? 4 : AppTokens.radiusLG),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.text,
                    style: tt.bodyMedium?.copyWith(
                      color: isMe ? cs.onPrimary : cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppTokens.spaceXS),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: tt.labelSmall?.copyWith(
                          fontSize: 11,
                          color: isMe
                              ? cs.onPrimary.withAlpha(AppTokens.alphaMedium)
                              : cs.onSurface.withAlpha(AppTokens.alphaLow),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: AppTokens.spaceXS),
                        Icon(
                          message.read
                              ? LucideIcons.checkCheck
                              : LucideIcons.check,
                          size: 14,
                          color: message.read
                              ? AppTokens.readReceiptColor
                              : cs.onPrimary.withAlpha(AppTokens.alphaMedium),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (showingPicker)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTokens.spaceXS),
              child: ReactionPicker(
                reactions: message.reactions,
                currentUid: currentUid,
                onReact: (emoji) => _toggleReaction(ref, emoji),
              ),
            ),

          if (message.reactions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTokens.spaceXS),
              child: ReactionRow(
                reactions: message.reactions,
                currentUid: currentUid,
                onReact: (emoji) => _toggleReaction(ref, emoji),
              ),
            ),
        ],
      ),
    );
  }
}
