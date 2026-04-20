import 'package:musi_link/models/artist.dart' as app;
import 'package:musi_link/models/track.dart' as app;
import 'package:musi_link/utils/error_reporter.dart';
import 'package:spotify/spotify.dart';

class SpotifyClientService {
  SpotifyClientService({
    required String clientId,
    required String clientSecret,
  }) : _api = SpotifyApi(SpotifyApiCredentials(clientId, clientSecret));

  final SpotifyApi _api;

  Future<List<app.Artist>> searchArtists(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) return [];
    try {
      final results = _api.search.get(query, types: [SearchType.artist]);
      final page = await results.first(limit);
      final artists = <app.Artist>[];
      for (final pages in page) {
        if (pages.items == null) continue;
        for (final item in pages.items!) {
          if (item is Artist) {
            final images = item.images;
            final imageUrl =
                (images != null && images.isNotEmpty) ? images.first.url ?? '' : '';
            artists.add(app.Artist(
              name: item.name ?? 'Unknown Artist',
              imageUrl: imageUrl,
              genres: item.genres?.toList() ?? [],
              spotifyId: item.id,
            ));
          }
        }
      }
      return artists;
    } catch (e, stack) {
      await reportError(e, stack);
      return [];
    }
  }

  Future<List<app.Track>> searchTracks(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) return [];
    try {
      final results = _api.search.get(query, types: [SearchType.track]);
      final page = await results.first(limit);
      final tracks = <app.Track>[];
      for (final pages in page) {
        if (pages.items == null) continue;
        for (final item in pages.items!) {
          if (item is Track) {
            final images = item.album?.images;
            final imageUrl =
                (images != null && images.isNotEmpty) ? images.first.url ?? '' : '';
            final artistName = (item.artists != null && item.artists!.isNotEmpty)
                ? item.artists!.first.name ?? 'Unknown Artist'
                : 'Unknown Artist';
            tracks.add(app.Track(
              title: item.name ?? 'Unknown',
              artist: artistName,
              imageUrl: imageUrl,
              spotifyUrl: (item.id != null && item.id!.isNotEmpty)
                  ? 'https://open.spotify.com/track/${item.id}'
                  : '',
            ));
          }
        }
      }
      return tracks;
    } catch (e, stack) {
      await reportError(e, stack);
      return [];
    }
  }

}
