class Genre {
  final String name;
  final int count;
  final double percentage;

  const Genre({
    required this.name,
    required this.count,
    required this.percentage,
  });

  factory Genre.fromMap(Map<String, dynamic> map) => Genre(
        name: (map['name'] ?? '').toString(),
        count: (map['count'] as num?)?.toInt() ?? 0,
        percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'count': count,
        'percentage': percentage,
      };
}
