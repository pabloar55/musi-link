import 'package:flutter/material.dart';
import 'package:musi_link/core/models/track.dart';

class TrackTile extends StatelessWidget {
  final Track track;

  const TrackTile({super.key, required this.track});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: track.imageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                track.imageUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            )
          : const Icon(Icons.music_note, size: 40),
      title: Text(track.title),
      subtitle: Text(track.artist),
    );
  }
}
