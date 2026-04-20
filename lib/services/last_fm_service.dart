import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:musi_link/models/artist.dart' as app;
import 'package:musi_link/utils/error_reporter.dart';

class LastFmService {
  LastFmService({required String apiKey}) : _apiKey = apiKey;

  final String _apiKey;
  static const _base = 'https://ws.audioscrobbler.com/2.0/';

  static final _collabPattern = RegExp(
    r'(&|feat\.?|ft\.?)',
    caseSensitive: false,
  );

  static bool _isCollaboration(String name) =>
      _collabPattern.hasMatch(name);

  Future<List<app.Artist>> getSimilarArtists(
    String artistName, {
    int limit = 10,
  }) async {
    if (artistName.trim().isEmpty) return [];
    try {
      final uri = Uri.parse(_base).replace(queryParameters: {
        'method': 'artist.getSimilar',
        'artist': artistName,
        'api_key': _apiKey,
        'format': 'json',
        'limit': '$limit',
        'autocorrect': '1',
      });
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final similarartists = data['similarartists'] as Map<String, dynamic>?;
      final similar = similarartists?['artist'];
      if (similar == null || similar is! List) return [];
      return similar
          .map((dynamic a) {
            final map = a as Map<String, dynamic>;
            return app.Artist(
              name: (map['name'] as String?) ?? 'Unknown',
              imageUrl: '',
              genres: const [],
            );
          })
          .where((a) => !_isCollaboration(a.name))
          .toList();
    } catch (e, st) {
      await reportError(e, st);
      return [];
    }
  }
}
