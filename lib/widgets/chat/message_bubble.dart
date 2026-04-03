import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:musi_link/models/message.dart';
import 'package:musi_link/theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final ColorScheme colorScheme;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final cs = colorScheme;
    final tt = Theme.of(context).textTheme;
    final time =
        '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
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
                    message.read ? LucideIcons.checkCheck : LucideIcons.check,
                    size: 14,
                    // Usa el token semántico del design system (no hardcodeado)
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
    );
  }
}
