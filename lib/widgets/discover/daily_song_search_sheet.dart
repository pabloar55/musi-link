import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/models/track.dart';
import 'package:musi_link/providers/providers.dart';

class DailySongSearchSheet extends ConsumerStatefulWidget {
  const DailySongSearchSheet({super.key});

  @override
  ConsumerState<DailySongSearchSheet> createState() => _DailySongSearchSheetState();
}

class _DailySongSearchSheetState extends ConsumerState<DailySongSearchSheet> {
  final _searchController = TextEditingController();
  List<Track> _results = [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _loading = true);
    final results = await ref.read(spotifyStatsProvider).searchTracks(query);
    if (mounted) {
      setState(() {
        _results = results;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withAlpha(60),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.chatSearchSpotify,
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.isEmpty
                                ? l10n.chatTypeToSearch
                                : l10n.chatNoResults,
                            style: TextStyle(
                              color: colorScheme.onSurface.withAlpha(120),
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final track = _results[index];
                            return ListTile(
                              leading: track.imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: CachedNetworkImage(
                                        imageUrl: track.imageUrl,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(Icons.music_note, size: 40),
                              title: Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                track.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => Navigator.of(context).pop(track),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}
