import 'package:flutter/material.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/models/discovery_result.dart';

class CompatibilityCard extends StatelessWidget {
  final Future<DiscoveryResult> future;

  const CompatibilityCard({super.key, required this.future});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<DiscoveryResult>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          );
        }

        final result = snapshot.data;
        if (result == null) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  '${result.score.round()}%',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.profileCompatible,
                  style: TextStyle(
                      fontSize: 16, color: colorScheme.onSurfaceVariant),
                ),
                if (result.sharedArtistNames.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.profileSharedArtists,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.sharedArtistNames.join(', '),
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 13, color: colorScheme.onSurface),
                  ),
                ],
                if (result.sharedGenreNames.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.profileSharedGenres,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.sharedGenreNames.join(', '),
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 13, color: colorScheme.onSurface),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
