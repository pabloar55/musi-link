import 'package:flutter/material.dart';
import 'package:musi_link/theme/app_theme.dart';

const _kEmojis = ['❤️', '🔥', '👏', '😍', '💀'];

class ReactionPicker extends StatelessWidget {
  final Map<String, List<String>> reactions;
  final String currentUid;
  final void Function(String emoji) onReact;

  const ReactionPicker({
    super.key,
    required this.reactions,
    required this.currentUid,
    required this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceSM,
        vertical: AppTokens.spaceXS,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _kEmojis.map((emoji) {
          final hasReacted = reactions[emoji]?.contains(currentUid) ?? false;
          return GestureDetector(
            onTap: () => onReact(emoji),
            child: SizedBox(
              width: AppTokens.minTouchTarget,
              height: AppTokens.minTouchTarget,
              child: Center(
                child: AnimatedContainer(
                  duration: AppTokens.durationFast,
                  padding: const EdgeInsets.all(AppTokens.spaceXS + 2),
                  decoration: BoxDecoration(
                    color: hasReacted ? cs.primaryContainer : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ReactionRow extends StatelessWidget {
  final Map<String, List<String>> reactions;
  final String currentUid;
  final void Function(String emoji) onReact;

  const ReactionRow({
    super.key,
    required this.reactions,
    required this.currentUid,
    required this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Wrap(
      spacing: AppTokens.spaceXS,
      runSpacing: AppTokens.spaceXS,
      children: reactions.entries.map((entry) {
        final hasReacted = entry.value.contains(currentUid);
        return GestureDetector(
          onTap: () => onReact(entry.key),
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
              color: hasReacted ? cs.primaryContainer : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppTokens.radiusMD),
              border: hasReacted
                  ? Border.all(color: cs.primary, width: 1.5)
                  : null,
            ),
            child: Text(
              '${entry.key} ${entry.value.length}',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        );
      }).toList(),
    );
  }
}
