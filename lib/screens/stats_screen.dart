import 'package:flutter/material.dart';
import 'package:musi_link/components/artist_tile.dart';
import 'package:musi_link/components/filter_button.dart';
import 'package:musi_link/components/genre_tile.dart';
import 'package:musi_link/components/track_tile.dart';
import 'package:musi_link/core/models/artist.dart';
import 'package:musi_link/core/models/genre.dart';
import 'package:musi_link/core/models/track.dart';
import 'package:musi_link/core/spotify_get_stats.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

enum ContentType { tracks, artists, genres }

enum TimeRange { shortTerm, mediumTerm, longTerm }

class _StatsScreenState extends State<StatsScreen>
    with AutomaticKeepAliveClientMixin<StatsScreen> {
  late Future<List<dynamic>> _dataFuture;
  ContentType _selectedContent = ContentType.tracks;
  TimeRange _selectedTimeRange = TimeRange.shortTerm;

  final Map<String, List<dynamic>> _cache = {};

  @override
  bool get wantKeepAlive => true;

  static const _timeRanges = {
    TimeRange.shortTerm: 'short_term',
    TimeRange.mediumTerm: 'medium_term',
    TimeRange.longTerm: 'long_term',
  };

  static const _timeRangeLabels = {
    TimeRange.shortTerm: '4 weeks',
    TimeRange.mediumTerm: '6 months',
    TimeRange.longTerm: '1 year',
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

    final api = SpotifyGetStats.instance;

    switch (_selectedContent) {
      case ContentType.tracks:
        _dataFuture = api.getTopTracks(10, timeRange).then((result) {
          _cache[key] = result;
          return result;
        });
      case ContentType.artists:
        _dataFuture = api.getTopArtists(10, timeRange).then((result) {
          _cache[key] = result;
          return result;
        });
      case ContentType.genres:
        _dataFuture = api.getTopGenres(10, timeRange).then((result) {
          _cache[key] = result;
          return result;
        });
    }
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
            ],
          ),
        ),
        Expanded(child: _buildDataList()),
      ],
    );
  }

  Widget _buildContentTypeFilter() {
    return Row(
      spacing: 8,
      children: [
        FilterButton(
          label: 'Tracks',
          isSelected: _selectedContent == ContentType.tracks,
          onPressed: () => _onContentChanged(ContentType.tracks),
        ),
        FilterButton(
          label: 'Artists',
          isSelected: _selectedContent == ContentType.artists,
          onPressed: () => _onContentChanged(ContentType.artists),
        ),
        FilterButton(
          label: 'Genres',
          isSelected: _selectedContent == ContentType.genres,
          onPressed: () => _onContentChanged(ContentType.genres),
        ),
      ],
    );
  }

  Widget _buildTimeRangeFilter() {
    return Row(
      spacing: 8,
      children: TimeRange.values.map((range) {
        return FilterButton(
          label: _timeRangeLabels[range]!,
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
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final data = snapshot.data ?? [];
        if (data.isEmpty) {
          return const Center(child: Text('No hay datos disponibles'));
        }

        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            final item = data[index];
            if (item is Track) {
              return TrackTile(track: item);
            } else if (item is Artist) {
              return ArtistTile(artist: item);
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
