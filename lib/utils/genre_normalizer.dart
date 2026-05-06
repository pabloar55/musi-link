const _genreAliases = <String, String>{
  'alt rock': 'alternative rock',
  'alternative': 'alternative',
  'alternative music': 'alternative',
  'corridos belicos': 'corridos belicos',
  'drum and bass': 'drum and bass',
  'dnb': 'drum and bass',
  'edm': 'electronic',
  'electro': 'electronic',
  'electronica': 'electronic',
  'electronic music': 'electronic',
  'hiphop': 'hip hop',
  'hip hop music': 'hip hop',
  'rap': 'hip hop',
  'rhythm and blues': 'r&b',
  'rnb': 'r&b',
  'singer songwriter': 'singer-songwriter',
  'synth pop': 'synthpop',
};

const _blockedGenreTags = <String>{
  '00s',
  '10s',
  '20s',
  '60s',
  '70s',
  '80s',
  '90s',
  'american',
  'australian',
  'belgian',
  'brazilian',
  'british',
  'canadian',
  'chilean',
  'chinese',
  'colombian',
  'danish',
  'dutch',
  'english',
  'favorite',
  'favorites',
  'favourite',
  'female vocalists',
  'finnish',
  'french',
  'german',
  'greek',
  'icelandic',
  'irish',
  'italian',
  'japanese',
  'korean',
  'male vocalists',
  'mexican',
  'mexico',
  'new zealand',
  'norwegian',
  'polish',
  'portuguese',
  'puerto rican',
  'puerto rico',
  'romanian',
  'russian',
  'scottish',
  'seen live',
  'spanish',
  'spain',
  'swedish',
  'turkish',
  'uk',
  'ukrainian',
  'usa',
  'vocalists',
  'welsh',
};

final _decadeOrYearPattern = RegExp(r'^(?:[0-9]{2}s|[12][0-9]{3}s?)$');

String? normalizeGenreName(String value) {
  final key = value
      .trim()
      .replaceAll(RegExp(r'[áàäâãåā]'), 'a')
      .replaceAll(RegExp(r'[ÁÀÄÂÃÅĀ]'), 'A')
      .replaceAll(RegExp(r'[éèëêē]'), 'e')
      .replaceAll(RegExp(r'[ÉÈËÊĒ]'), 'E')
      .replaceAll(RegExp(r'[íìïîī]'), 'i')
      .replaceAll(RegExp(r'[ÍÌÏÎĪ]'), 'I')
      .replaceAll(RegExp(r'[óòöôõō]'), 'o')
      .replaceAll(RegExp(r'[ÓÒÖÔÕŌ]'), 'O')
      .replaceAll(RegExp(r'[úùüûū]'), 'u')
      .replaceAll(RegExp(r'[ÚÙÜÛŪ]'), 'U')
      .replaceAll(RegExp(r'[ñ]'), 'n')
      .replaceAll(RegExp(r'[Ñ]'), 'N')
      .replaceAll(RegExp(r'[ç]'), 'c')
      .replaceAll(RegExp(r'[Ç]'), 'C')
      .toLowerCase()
      .replaceAll(RegExp(r'\br\s*&\s*b\b'), 'rnb')
      .replaceAll('&', ' and ')
      .replaceAll(RegExp(r'[\-_/]+'), ' ')
      .replaceAll(RegExp(r'[^a-z0-9&]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  if (key.isEmpty) return null;
  final normalized = _genreAliases[key] ?? key;
  if (!isUsefulGenreName(normalized)) return null;
  return normalized;
}

bool isUsefulGenreName(String value) {
  final key = value.trim().toLowerCase();
  if (key.length < 2) return false;
  if (_blockedGenreTags.contains(key)) return false;
  if (_decadeOrYearPattern.hasMatch(key)) return false;
  if (key.contains('seen live') || key.contains('favorite')) return false;
  return true;
}

List<String> normalizeGenreNames(Iterable<String> values, {int? limit}) {
  final genresByKey = <String, String>{};
  for (final value in values) {
    final normalized = normalizeGenreName(value);
    if (normalized == null) continue;
    genresByKey.putIfAbsent(normalized, () => normalized);
    if (limit != null && genresByKey.length >= limit) break;
  }
  return genresByKey.values.toList(growable: false);
}
