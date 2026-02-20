class Artist {
  final String name;
  final String imageUrl;

  const Artist({
    required this.name,
    required this.imageUrl,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List<dynamic>?;

    return Artist(
      name: (json['name'] ?? 'Artista desconocido').toString(),
      imageUrl: (images != null && images.isNotEmpty)
          ? (images[0]['url'] ?? '').toString()
          : '',
    );
  }
}
