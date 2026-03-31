import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/models/discovery_result.dart';
import 'package:musi_link/models/track.dart';
import 'package:musi_link/theme/app_theme.dart';

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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final user = result.user;
    final score = result.score.round();

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceLG,
        vertical: AppTokens.spaceXS,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusMD),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spaceLG),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              _UserAvatar(photoUrl: user.photoUrl),
              const SizedBox(width: AppTokens.spaceMD),

              // Info principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre + Score badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            user.displayName,
                            style: tt.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppTokens.spaceSM),
                        _ScoreBadge(score: score, colorScheme: cs),
                      ],
                    ),
                    const SizedBox(height: AppTokens.spaceXS),

                    // Artistas compartidos
                    if (result.sharedArtistNames.isNotEmpty)
                      _MetaRow(
                        icon: Icons.music_note_rounded,
                        text: result.sharedArtistNames.join(', '),
                        colorScheme: cs,
                        textTheme: tt,
                      ),

                    // Géneros compartidos
                    if (result.sharedGenreNames.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      _MetaRow(
                        icon: Icons.label_rounded,
                        text: result.sharedGenreNames.join(', '),
                        colorScheme: cs,
                        textTheme: tt,
                      ),
                    ],

                    // Daily song
                    if (user.dailySong != null) ...[
                      const SizedBox(height: AppTokens.spaceSM),
                      _DailySongRow(
                        song: user.dailySong!,
                        l10n: l10n,
                        cs: cs,
                        tt: tt,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: AppTokens.spaceXS),
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  final String photoUrl;
  const _UserAvatar({required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasPhoto = photoUrl.isNotEmpty;

    return CircleAvatar(
      radius: 26,
      backgroundColor: cs.surfaceContainerHighest,
      backgroundImage: hasPhoto ? CachedNetworkImageProvider(photoUrl) : null,
      child: hasPhoto
          ? null
          : Icon(Icons.person_rounded, size: 28, color: cs.onSurfaceVariant),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int score;
  final ColorScheme colorScheme;
  const _ScoreBadge({required this.score, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final cs = colorScheme;
    final isHigh = score >= 70;
    final isMedium = score >= 40;
    final color = isHigh ? cs.primary : (isMedium ? cs.secondary : cs.onSurfaceVariant);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceSM + 2,
        vertical: AppTokens.spaceXS,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        border: Border.all(color: color.withAlpha(80), width: 1),
      ),
      child: Text(
        '$score%',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _MetaRow({
    required this.icon,
    required this.text,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: AppTokens.spaceXS),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DailySongRow extends StatelessWidget {
  final Track song;
  final AppLocalizations l10n;
  final ColorScheme cs;
  final TextTheme tt;

  const _DailySongRow({
    required this.song,
    required this.l10n,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceSM,
        vertical: AppTokens.spaceXS,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppTokens.radiusSM),
      ),
      child: Row(
        children: [
          // Artwork 40×40
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: song.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: song.imageUrl,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    errorWidget: (ctx, url, err) => _songPlaceholder(),
                  )
                : _songPlaceholder(),
          ),
          const SizedBox(width: AppTokens.spaceSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.dailySongTitle,
                  style: tt.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  '${song.title} — ${song.artist}',
                  style: tt.bodySmall?.copyWith(color: cs.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _songPlaceholder() {
    return Container(
      width: 36,
      height: 36,
      color: Colors.white12,
      child: const Icon(Icons.music_note, size: 18, color: Colors.white54),
    );
  }
}
