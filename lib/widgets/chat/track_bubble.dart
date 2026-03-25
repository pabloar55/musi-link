import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:musi_link/services/chat_service.dart';
import 'package:musi_link/models/message.dart';
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
    widget.chatService.toggleReaction(widget.chatId, widget.message.id, emoji);
    setState(() => _showingPicker = false);
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isMe = widget.isMe;
    final colorScheme = widget.colorScheme;
    final currentUid = widget.currentUid;
    final track = message.trackData!;
    final time =
        '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Card de la canción
            GestureDetector(
              onLongPress: () => setState(() => _showingPicker = !_showingPicker),
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
                  color: isMe
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
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
                        height: 180,
                        fit: BoxFit.cover,
                      )
                    else
                      Container(
                        width: double.infinity,
                        height: 180,
                        color: colorScheme.surfaceContainerHigh,
                        child: Icon(Icons.music_note,
                            size: 64,
                            color: colorScheme.onSurface.withAlpha(80)),
                      ),
                    // Info canción
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isMe
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            track.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: isMe
                                  ? colorScheme.onPrimary.withAlpha(200)
                                  : colorScheme.onSurface.withAlpha(160),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Timestamp + read receipt
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 11,
                              color: isMe
                                  ? colorScheme.onPrimary.withAlpha(180)
                                  : colorScheme.onSurface.withAlpha(120),
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              message.read ? Icons.done_all : Icons.done,
                              size: 14,
                              color: message.read
                                  ? const Color.fromARGB(255, 0, 140, 255)
                                  : colorScheme.onPrimary.withAlpha(180),
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
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: ['❤️', '🔥', '👏', '😍', '🎶'].map((emoji) {
                      final hasReacted =
                          message.reactions[emoji]?.contains(currentUid) ?? false;
                      return GestureDetector(
                        onTap: () => _toggleReaction(emoji),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: hasReacted
                                ? colorScheme.primaryContainer
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(emoji, style: const TextStyle(fontSize: 24)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            // Reacciones
            if (message.reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 4,
                  children: message.reactions.entries.map((entry) {
                    final hasReacted = entry.value.contains(currentUid);
                    return GestureDetector(
                      onTap: () => _toggleReaction(entry.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: hasReacted
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: hasReacted
                              ? Border.all(
                                  color: colorScheme.primary, width: 1.5)
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
