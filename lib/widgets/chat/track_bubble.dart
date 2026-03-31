import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:musi_link/services/chat_service.dart';
import 'package:musi_link/models/message.dart';
import 'package:musi_link/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class TrackBubble extends StatefulWidget {
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

  @override
  State<TrackBubble> createState() => _TrackBubbleState();
}

class _TrackBubbleState extends State<TrackBubble> {
  bool _showingPicker = false;

  void _toggleReaction(String emoji) {
    widget.chatService.toggleReaction(
        widget.chatId, widget.message.id, emoji);
    setState(() => _showingPicker = false);
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isMe = widget.isMe;
    final cs = widget.colorScheme;
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
            // Card de la canción
            GestureDetector(
              onLongPress: () =>
                  setState(() => _showingPicker = !_showingPicker),
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
                    // Carátula
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
                          Icons.music_note_rounded,
                          size: 56,
                          color: cs.onSurface.withAlpha(AppTokens.alphaDisabled),
                        ),
                      ),

                    // Info canción
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

                    // Timestamp + read receipt
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
                                  ? cs.onPrimary
                                      .withAlpha(AppTokens.alphaMedium)
                                  : cs.onSurface.withAlpha(AppTokens.alphaLow),
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: AppTokens.spaceXS),
                            Icon(
                              message.read
                                  ? Icons.done_all_rounded
                                  : Icons.done_rounded,
                              size: 14,
                              // Token semántico del design system
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

            // Picker de reacciones inline
            if (_showingPicker)
              Padding(
                padding: const EdgeInsets.only(top: AppTokens.spaceXS),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.spaceSM,
                    vertical: AppTokens.spaceXS,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius:
                        BorderRadius.circular(AppTokens.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: ['❤️', '🔥', '👏', '😍', '🎶'].map((emoji) {
                      final hasReacted = widget.message.reactions[emoji]
                              ?.contains(widget.currentUid) ??
                          false;
                      return GestureDetector(
                        onTap: () => _toggleReaction(emoji),
                        // Touch target mínimo de 44px
                        child: SizedBox(
                          width: AppTokens.minTouchTarget,
                          height: AppTokens.minTouchTarget,
                          child: Center(
                            child: AnimatedContainer(
                              duration: AppTokens.durationFast,
                              padding: const EdgeInsets.all(
                                  AppTokens.spaceXS + 2),
                              decoration: BoxDecoration(
                                color: hasReacted
                                    ? cs.primaryContainer
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            // Reacciones existentes
            if (message.reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppTokens.spaceXS),
                child: Wrap(
                  spacing: AppTokens.spaceXS,
                  runSpacing: AppTokens.spaceXS,
                  children: message.reactions.entries.map((entry) {
                    final hasReacted =
                        entry.value.contains(widget.currentUid);
                    return GestureDetector(
                      onTap: () => _toggleReaction(entry.key),
                      child: AnimatedContainer(
                        duration: AppTokens.durationFast,
                        constraints: const BoxConstraints(
                          minHeight: AppTokens.minTouchTarget - 8,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.spaceSM + 2,
                          vertical: AppTokens.spaceXS,
                        ),
                        decoration: BoxDecoration(
                          color: hasReacted
                              ? cs.primaryContainer
                              : cs.surfaceContainerHighest,
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusMD),
                          border: hasReacted
                              ? Border.all(
                                  color: cs.primary, width: 1.5)
                              : null,
                        ),
                        child: Text(
                          '${entry.key} ${entry.value.length}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
