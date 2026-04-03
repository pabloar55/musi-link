import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:musi_link/models/track.dart';
import 'package:musi_link/theme/app_theme.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  final int? rank;

  const TrackTile({super.key, required this.track, this.rank});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceLG,
        vertical: AppTokens.spaceXS,
      ),
      child: Row(
        children: [
          // Número de ranking
          if (rank != null)
            SizedBox(
              width: 28,
              child: Text(
                '$rank',
                textAlign: TextAlign.center,
                style: tt.labelMedium?.copyWith(
                  fontWeight: rank! <= 3 ? FontWeight.w700 : FontWeight.w400,
                  color: rank! <= 3 ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
            ),
          if (rank != null) const SizedBox(width: AppTokens.spaceSM),

          // Carátula
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radiusSM),
            child: track.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: track.imageUrl,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) => _placeholder(cs),
                    errorWidget: (ctx, url, err) => _placeholder(cs),
                  )
                : _placeholder(cs),
          ),
          const SizedBox(width: AppTokens.spaceMD),

          // Título + artista
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  track.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(ColorScheme cs) {
    return Container(
      width: 52,
      height: 52,
      color: cs.surfaceContainerHighest,
      child: Icon(LucideIcons.music, size: 24, color: cs.onSurfaceVariant),
    );
  }
}
