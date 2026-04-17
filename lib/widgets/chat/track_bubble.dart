import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:musi_link/models/message.dart';
import 'package:musi_link/providers/service_providers.dart';
import 'package:musi_link/services/chat_service.dart';
import 'package:musi_link/theme/app_theme.dart';
import 'package:musi_link/widgets/chat/reaction_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class TrackBubble extends ConsumerWidget {
  final Message message;
  final bool isMe;
  final ColorScheme colorScheme;
  final String currentUid;
  final String chatId;
  final ChatService chatService;

  const TrackBubble({
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
    final track = message.trackData!;
    final time =
        '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: AppTokens.spaceXS),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onLongPress: () => ref
                  .read(activeReactionPickerProvider.notifier)
                  .toggle(message.id),
              onTap: track.spotifyUrl.isNotEmpty
                  ? () async {
                      final uri = Uri.parse(track.spotifyUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    }
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  color: isMe ? cs.primary : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(AppTokens.radiusLG),
                    topRight: const Radius.circular(AppTokens.radiusLG),
                    bottomLeft:
                        Radius.circular(isMe ? AppTokens.radiusLG : 4),
                    bottomRight:
                        Radius.circular(isMe ? 4 : AppTokens.radiusLG),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (track.imageUrl.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: track.imageUrl,
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                      )
                    else
                      Container(
                        width: double.infinity,
                        height: 160,
                        color: cs.surfaceContainerHigh,
                        child: Icon(
                          LucideIcons.music,
                          size: 56,
                          color: cs.onSurface.withAlpha(AppTokens.alphaDisabled),
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTokens.spaceMD,
                        AppTokens.spaceSM + 2,
                        AppTokens.spaceMD,
                        AppTokens.spaceXS,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.titleSmall?.copyWith(
                              color: isMe ? cs.onPrimary : cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            track.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodySmall?.copyWith(
                              color: isMe
                                  ? cs.onPrimary.withAlpha(AppTokens.alphaMedium)
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTokens.spaceMD,
                        0,
                        AppTokens.spaceMD,
                        AppTokens.spaceSM,
                      ),
                      child: Row(
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
                                  : cs.onPrimary
                                      .withAlpha(AppTokens.alphaMedium),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (showingPicker)
              Padding(
                padding: const EdgeInsets.only(top: AppTokens.spaceXS),
                child: ReactionPicker(
                  reactions: message.reactions,
                  currentUid: currentUid,
                  onReact: (emoji) => _toggleReaction(ref, emoji),
                ),
              ),

            if (message.reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppTokens.spaceXS),
                child: ReactionRow(
                  reactions: message.reactions,
                  currentUid: currentUid,
                  onReact: (emoji) => _toggleReaction(ref, emoji),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
