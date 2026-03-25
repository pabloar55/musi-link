import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/models/discovery_result.dart';

class UserDiscoveryCard extends StatelessWidget {
  final DiscoveryResult result;
  final VoidCallback onTap;

  const UserDiscoveryCard({
    super.key,
    required this.result,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final user = result.user;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: user.photoUrl.isNotEmpty
                        ? CachedNetworkImageProvider(user.photoUrl)
                        : null,
                    child: user.photoUrl.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          l10n.discoveryCompatible(result.score.round().toString()),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (result.sharedArtistNames.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.music_note,
                        size: 16, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.discoverySharedArtists(result.sharedArtistNames.join(', ')),
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (result.sharedGenreNames.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.label,
                        size: 16, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.discoverySharedGenres(result.sharedGenreNames.join(', ')),
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (user.dailySong != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (user.dailySong!.imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: user.dailySong!.imageUrl,
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Icon(Icons.album,
                          size: 24, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${l10n.dailySongTitle}: ${user.dailySong!.title} — ${user.dailySong!.artist}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
