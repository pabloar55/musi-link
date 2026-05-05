import 'package:cloud_functions/cloud_functions.dart';
import 'package:musi_link/models/artist.dart' as app;
import 'package:musi_link/utils/error_reporter.dart';

class LastFmService {
  LastFmService(this._functions);

  final FirebaseFunctions _functions;

  Future<List<app.Artist>> getSimilarArtists(
    String artistName, {
    int limit = 10,
  }) async {
    if (artistName.trim().isEmpty) return [];
    try {
      final callable = _functions.httpsCallable('getSimilarArtists');
      final result = await callable.call<List<dynamic>>({
        'artistName': artistName,
        'limit': limit,
      });
      return result.data
          .map(
            (dynamic name) => app.Artist(
              name: name as String? ?? 'Unknown',
              imageUrl: '',
              genres: const [],
            ),
          )
          .toList();
    } catch (e, st) {
      await reportError(e, st);
      return [];
    }
  }
}
