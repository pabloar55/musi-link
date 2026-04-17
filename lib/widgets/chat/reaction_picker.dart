import 'package:flutter/material.dart';
import 'package:musi_link/theme/app_theme.dart';

const _kEmojis = ['❤️', '🔥', '👏', '😍', '💀'];

class FloatingReactionPicker extends StatefulWidget {
  final LayerLink layerLink;
  final bool isMe;
  final Map<String, List<String>> reactions;
  final String currentUid;
  final void Function(String emoji) onReact;
  final VoidCallback onDismiss;

  const FloatingReactionPicker({
    super.key,
    required this.layerLink,
    required this.isMe,
    required this.reactions,
    required this.currentUid,
    required this.onReact,
    required this.onDismiss,
  });

  @override
  State<FloatingReactionPicker> createState() => _FloatingReactionPickerState();
}

class _FloatingReactionPickerState extends State<FloatingReactionPicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alignment =
        widget.isMe ? Alignment.bottomRight : Alignment.bottomLeft;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            behavior: HitTestBehavior.translucent,
          ),
        ),
        CompositedTransformFollower(
          link: widget.layerLink,
          showWhenUnlinked: false,
          targetAnchor:
              widget.isMe ? Alignment.topRight : Alignment.topLeft,
          followerAnchor: alignment,
          offset: const Offset(0, -AppTokens.spaceXS),
          child: Material(
            color: Colors.transparent,
            child: FadeTransition(
              opacity: _opacity,
              child: ScaleTransition(
                scale: _scale,
                alignment: alignment,
                child: ReactionPicker(
                  reactions: widget.reactions,
                  currentUid: widget.currentUid,
                  onReact: widget.onReact,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

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
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withAlpha(30),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                    color: hasReacted
                        ? cs.onSurface.withAlpha(25)
                        : Colors.transparent,
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
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spaceSM,
              vertical: AppTokens.spaceXS,
            ),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppTokens.radiusFull),
              border: Border.all(
                color: hasReacted
                    ? cs.onSurface.withAlpha(120)
                    : cs.outlineVariant.withAlpha(80),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withAlpha(20),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              entry.key,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        );
      }).toList(),
    );
  }
}
