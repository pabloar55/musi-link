class Artist {
  final String name;
  final String imageUrl;
  final List<String> genres;

  const Artist({
    required this.name,
    required this.imageUrl,
    required this.genres,
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
        genres: [],
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'imageUrl': imageUrl,
      };
}
