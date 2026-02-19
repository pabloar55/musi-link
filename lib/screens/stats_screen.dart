import 'package:flutter/material.dart';
import 'package:musi_link/core/spotify_get_stats.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

enum ContentType { tracks, artists }

enum TimeRange { shortTerm, mediumTerm, longTerm }

class _StatsScreenState extends State<StatsScreen>
    with AutomaticKeepAliveClientMixin<StatsScreen> {
  late Future<List<Map<String, String>>> _dataFuture;
  ContentType _selectedContent = ContentType.tracks;
  TimeRange _selectedTimeRange = TimeRange.shortTerm;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final timeRangeMap = {
      TimeRange.shortTerm: 'short_term',
      TimeRange.mediumTerm: 'medium_term',
      TimeRange.longTerm: 'long_term',
    };
    
    final timeRange = timeRangeMap[_selectedTimeRange]!;
    
    if (_selectedContent == ContentType.tracks) {
      _dataFuture = SpotifyGetStats.instance.getTopTracks(10, timeRange);
    } else {
      _dataFuture = SpotifyGetStats.instance.getTopArtists(10, timeRange);
    }
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
              // Control para seleccionar Tracks o Artists
              Row(
                spacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: _selectedContent == ContentType.tracks
                        ? null
                        : () {
                            setState(() {
                              _selectedContent = ContentType.tracks;
                              _loadData();
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      backgroundColor: _selectedContent == ContentType.tracks
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      foregroundColor: _selectedContent == ContentType.tracks
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    child: const Text('Tracks', style: TextStyle(fontSize: 12)),
                  ),
                  ElevatedButton(
                    onPressed: _selectedContent == ContentType.artists
                        ? null
                        : () {
                            setState(() {
                              _selectedContent = ContentType.artists;
                              _loadData();
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      backgroundColor: _selectedContent == ContentType.artists
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      foregroundColor: _selectedContent == ContentType.artists
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    child: const Text('Artists', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              // Control para seleccionar rango de tiempo
              Row(
                spacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: _selectedTimeRange == TimeRange.shortTerm
                        ? null
                        : () {
                            setState(() {
                              _selectedTimeRange = TimeRange.shortTerm;
                              _loadData();
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      backgroundColor: _selectedTimeRange == TimeRange.shortTerm
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      foregroundColor: _selectedTimeRange == TimeRange.shortTerm
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    child: const Text('4 weeks', style: TextStyle(fontSize: 11)),
                  ),
                  ElevatedButton(
                    onPressed: _selectedTimeRange == TimeRange.mediumTerm
                        ? null
                        : () {
                            setState(() {
                              _selectedTimeRange = TimeRange.mediumTerm;
                              _loadData();
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      backgroundColor: _selectedTimeRange == TimeRange.mediumTerm
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      foregroundColor: _selectedTimeRange == TimeRange.mediumTerm
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    child: const Text('6 months', style: TextStyle(fontSize: 11)),
                  ),
                  ElevatedButton(
                    onPressed: _selectedTimeRange == TimeRange.longTerm
                        ? null
                        : () {
                            setState(() {
                              _selectedTimeRange = TimeRange.longTerm;
                              _loadData();
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      backgroundColor: _selectedTimeRange == TimeRange.longTerm
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      foregroundColor: _selectedTimeRange == TimeRange.longTerm
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    child: const Text('1 year', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, String>>>(
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
                  final image = item['image'];
                  
                  if (_selectedContent == ContentType.tracks) {
                    return ListTile(
                      leading: image != null && image.isNotEmpty
                          ? Image.network(
                              image,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.music_note),
                      title: Text(item['title'] ?? ''),
                      subtitle: Text(item['artist'] ?? ''),
                    );
                  } else {
                    return ListTile(
                      leading: image != null && image.isNotEmpty
                          ? Image.network(
                              image,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.music_note),
                      title: Text(item['name'] ?? ''),
                    );
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
