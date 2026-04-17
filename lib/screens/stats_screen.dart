import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/providers/service_providers.dart';
import 'package:musi_link/services/spotify_stats_service.dart';
import 'package:musi_link/widgets/artist_tile.dart';
import 'package:musi_link/widgets/filter_button.dart';
import 'package:musi_link/widgets/genre_tile.dart';
import 'package:musi_link/widgets/skeleton_loader.dart';
import 'package:musi_link/widgets/track_tile.dart';
import 'package:musi_link/models/artist.dart';
import 'package:musi_link/models/genre.dart';
import 'package:musi_link/models/track.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

enum ContentType { tracks, artists, genres }

enum TimeRange { shortTerm, mediumTerm, longTerm }

class _StatsScreenState extends ConsumerState<StatsScreen>
    with AutomaticKeepAliveClientMixin<StatsScreen> {
  late Future<List<dynamic>> _dataFuture;
  ContentType _selectedContent = ContentType.tracks;
  TimeRange _selectedTimeRange = TimeRange.shortTerm;
  bool _isFromCache = false;
  bool _cacheIsStale = false;

  final Map<String, List<dynamic>> _cache = {};

  @override
  bool get wantKeepAlive => true;

  static const _timeRanges = {
    TimeRange.shortTerm: 'short_term',
    TimeRange.mediumTerm: 'medium_term',
    TimeRange.longTerm: 'long_term',
  };

  Map<TimeRange, String> _timeRangeLabels(AppLocalizations l10n) => {
    TimeRange.shortTerm: l10n.statsShortTerm,
    TimeRange.mediumTerm: l10n.statsMediumTerm,
    TimeRange.longTerm: l10n.statsLongTerm,
  };

  String _cacheKey() => '${_selectedContent.name}_${_selectedTimeRange.name}';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final timeRange = _timeRanges[_selectedTimeRange]!;
    final key = _cacheKey();

    if (_cache.containsKey(key)) {
      _dataFuture = Future.value(_cache[key]);
      return;
    }

    final api = ref.read(spotifyStatsProvider);

    Future<List<dynamic>> fetch;
    switch (_selectedContent) {
      case ContentType.tracks:
        fetch = api.getTopTracks(20, timeRange);
      case ContentType.artists:
        fetch = api.getTopArtists(20, timeRange);
      case ContentType.genres:
        fetch = api.getTopGenres(10, timeRange);
    }

    _dataFuture = fetch.then((result) {
      _cache[key] = result;
      if (mounted) {
        setState(() {
          _isFromCache = api.lastServedFromCache;
          _cacheIsStale = api.cacheIsStale;
        });
      }
      return result;
    });
  }

  void _onContentChanged(ContentType type) {
    setState(() {
      _selectedContent = type;
      _loadData();
    });
  }

  void _onTimeRangeChanged(TimeRange range) {
    setState(() {
      _selectedTimeRange = range;
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            spacing: 12,
            children: [
              _buildContentTypeFilter(),
              _buildTimeRangeFilter(),
              if (_isFromCache || _cacheIsStale)
                Row(
                  children: [
                    Icon(
                      _isFromCache ? LucideIcons.cloudOff : LucideIcons.clock,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isFromCache
                          ? AppLocalizations.of(context)!.statsOfflineCache
                          : AppLocalizations.of(context)!.statsStaleCache,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        Expanded(child: _buildDataList()),
      ],
    );
  }

  Widget _buildContentTypeFilter() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      spacing: 8,
      children: [
        FilterButton(
          label: l10n.statsTracks,
          isSelected: _selectedContent == ContentType.tracks,
          onPressed: () => _onContentChanged(ContentType.tracks),
        ),
        FilterButton(
          label: l10n.statsArtists,
          isSelected: _selectedContent == ContentType.artists,
          onPressed: () => _onContentChanged(ContentType.artists),
        ),
        FilterButton(
          label: l10n.statsGenres,
          isSelected: _selectedContent == ContentType.genres,
          onPressed: () => _onContentChanged(ContentType.genres),
        ),
      ],
    );
  }

  Widget _buildTimeRangeFilter() {
    final l10n = AppLocalizations.of(context)!;
    final labels = _timeRangeLabels(l10n);
    return Row(
      spacing: 8,
      children: TimeRange.values.map((range) {
        return FilterButton(
          label: labels[range]!,
          isSelected: _selectedTimeRange == range,
          onPressed: () => _onTimeRangeChanged(range),
          fontSize: 11,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        );
      }).toList(),
    );
  }

  Widget _buildDataList() {
    return FutureBuilder<List<dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SkeletonShimmer(
            child: ListView(
              children:
                  List.generate(8, (_) => const SkeletonStatsTile()),
            ),
          );
        }
        if (snapshot.hasError) {
          if (snapshot.error is OfflineNoDataException) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 12,
                children: [
                  Icon(
                    LucideIcons.cloudOff,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  Text(
                    AppLocalizations.of(context)!.statsOfflineNoData,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return Center(child: Text(AppLocalizations.of(context)!.statsError(snapshot.error.toString())));
        }

        final data = snapshot.data ?? [];
        if (data.isEmpty) {
          return Center(child: Text(AppLocalizations.of(context)!.statsNoData));
        }

        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            final item = data[index];
            if (item is Track) {
              return TrackTile(track: item, rank: index + 1);
            } else if (item is Artist) {
              return ArtistTile(artist: item, rank: index + 1);
            } else if (item is Genre) {
              return GenreTile(genre: item, rank: index + 1);
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}
