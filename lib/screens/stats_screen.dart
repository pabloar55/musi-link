import 'package:flutter/material.dart';
import 'package:musi_link/core/spotify_get_stats.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with AutomaticKeepAliveClientMixin<StatsScreen> {
  late Future<List<Map<String, String>>> _tracksFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tracksFuture = SpotifyGetStats().getTopTracks();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<Map<String, String>>>(
      future: _tracksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final tracks = snapshot.data ?? [];
        if (tracks.isEmpty) {
          return const Center(child: Text('No hay top tracks disponibles'));
        }

        return ListView.builder(
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            final t = tracks[index];
            final image = t['image'];
            return ListTile(
              leading: image != null && image.isNotEmpty
                  ? Image.network(
                      image,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.music_note),
              title: Text(t['title'] ?? ''),
              subtitle: Text(t['artist'] ?? ''),
            );
          },
        );
      },
    );
  }
}
