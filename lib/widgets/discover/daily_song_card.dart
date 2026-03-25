import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:musi_link/models/track.dart';

class DailySongCard extends StatelessWidget {
  final Track song;
  final VoidCallback? onTap;

  const DailySongCard({super.key, required this.song, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (song.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: song.imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.music_note, size: 28),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      song.artist,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.play_circle_fill,
                color: colorScheme.primary,
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
