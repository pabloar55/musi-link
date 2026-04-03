import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/models/track.dart';
import 'package:musi_link/theme/app_theme.dart';

class NowPlayingCard extends StatelessWidget {
  final Track track;
  final VoidCallback? onTap;

  const NowPlayingCard({super.key, required this.track, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceXL,
      ).copyWith(bottom: AppTokens.spaceMD),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.radiusMD),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spaceMD),
          child: Row(
            children: [
              // Artwork del álbum
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                child: track.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: track.imageUrl,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        placeholder: (ctx, url) => _artworkPlaceholder(cs),
                        errorWidget: (ctx, url, err) => _artworkPlaceholder(cs),
                      )
                    : _artworkPlaceholder(cs),
              ),
              const SizedBox(width: AppTokens.spaceMD),

              // Metadatos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Label "Now Playing" con indicador animado
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _PulsingDot(color: cs.primary),
                        const SizedBox(width: AppTokens.spaceXS),
                        Text(
                          l10n.nowPlaying,
                          style: tt.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.spaceXS),
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.titleSmall,
                    ),
                    Text(
                      track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.spaceSM),
              Icon(LucideIcons.externalLink, color: cs.onSurfaceVariant, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _artworkPlaceholder(ColorScheme cs) {
    return Container(
      width: 52,
      height: 52,
      color: cs.surfaceContainerHighest,
      child: Icon(LucideIcons.headphones, size: 24, color: cs.primary),
    );
  }
}

/// Punto verde animado que pulsa para indicar reproducción en vivo.
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
