import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:musi_link/models/artist.dart';
import 'package:musi_link/theme/app_theme.dart';

class ArtistTile extends StatelessWidget {
  final Artist artist;
  final int? rank;

  const ArtistTile({super.key, required this.artist, this.rank});

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

          // Foto circular del artista
          ClipOval(
            child: artist.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: artist.imageUrl,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) => _placeholder(cs),
                    errorWidget: (ctx, url, err) => _placeholder(cs),
                  )
                : _placeholder(cs),
          ),
          const SizedBox(width: AppTokens.spaceMD),

          // Nombre
          Expanded(
            child: Text(
              artist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.titleSmall,
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
      child: Icon(LucideIcons.user, size: 28, color: cs.onSurfaceVariant),
    );
  }
}
