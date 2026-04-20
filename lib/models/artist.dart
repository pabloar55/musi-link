class Artist {
  final String name;
  final String imageUrl;
  final List<String> genres;
  final String? spotifyId;

  const Artist({
    required this.name,
    required this.imageUrl,
    required this.genres,
    this.spotifyId,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List<dynamic>?;
    final genresList = json['genres'] as List<dynamic>?;

    return Artist(
      name: (json['name'] ?? 'Artista desconocido').toString(),
      imageUrl: (images != null && images.isNotEmpty)
          ? ((images[0] as Map<String, dynamic>)['url'] ?? '').toString()
          : '',
      genres: genresList?.map((g) => g.toString()).toList() ?? [],
    );
  }

  factory Artist.fromMap(Map<String, dynamic> map) => Artist(
        name: (map['name'] ?? '').toString(),
        imageUrl: (map['imageUrl'] ?? '').toString(),
        genres: (map['genres'] as List<dynamic>?)?.map((g) => g.toString()).toList() ?? [],
        spotifyId: map['spotifyId']?.toString(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'imageUrl': imageUrl,
        'genres': genres,
        if (spotifyId != null) 'spotifyId': spotifyId,
      };
}
