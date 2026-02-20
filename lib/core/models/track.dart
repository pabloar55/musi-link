class Track {
  final String title;
  final String artist;
  final String imageUrl;

  const Track({
    required this.title,
    required this.artist,
    required this.imageUrl,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    final artists = json['artists'] as List<dynamic>?;
    final images = json['album']?['images'] as List<dynamic>?;

    return Track(
      title: (json['name'] ?? 'Sin título').toString(),
      artist: (artists != null && artists.isNotEmpty)
          ? (artists[0]['name'] ?? 'Artista desconocido').toString()
          : 'Artista desconocido',
      imageUrl: (images != null && images.isNotEmpty)
          ? (images[0]['url'] ?? '').toString()
          : '',
    );
  }
}
