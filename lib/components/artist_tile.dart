import 'package:flutter/material.dart';
import 'package:musi_link/core/models/artist.dart';

class ArtistTile extends StatelessWidget {
  final Artist artist;

  const ArtistTile({super.key, required this.artist});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: artist.imageUrl.isNotEmpty
          ? ClipOval(
              child: Image.network(
                artist.imageUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            )
          : const Icon(Icons.music_note, size: 40),
      title: Text(artist.name),
      titleAlignment: ListTileTitleAlignment.center,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
