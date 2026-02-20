import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:musi_link/core/models/artist.dart';
import 'package:musi_link/core/models/track.dart';
import 'package:musi_link/core/tokens.dart';

class SpotifyGetStats {
  SpotifyGetStats._();
  static final SpotifyGetStats instance = SpotifyGetStats._();

  static const String _baseUrl = 'https://api.spotify.com/v1/me/top';

  /// Método genérico para obtener el top de cualquier tipo (tracks/artists).
  /// Elimina la duplicación de lógica HTTP entre getTopTracks y getTopArtists.
  Future<List<T>> _getTop<T>({
    required String endpoint,
    required int limit,
    required String timeRange,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      debugPrint("----------Obteniendo top $endpoint...---------");
      final url = Uri.parse('$_baseUrl/$endpoint?time_range=$timeRange&limit=$limit');

      final token = await Tokens.getSavedToken();
      if (token == null || token.isEmpty) {
        debugPrint("❌ No hay token disponible");
        return [];
      }

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['items'] ?? [];
        return items
            .cast<Map<String, dynamic>>()
            .map(fromJson)
            .toList();
      } else {
        debugPrint("❌ Error API: ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      debugPrint("❌ Error de conexión: $e");
      return [];
    }
  }

  Future<List<Track>> getTopTracks(int limit, String timeRange) {
    return _getTop(
      endpoint: 'tracks',
      limit: limit,
      timeRange: timeRange,
      fromJson: Track.fromJson,
    );
  }

  Future<List<Artist>> getTopArtists(int limit, String timeRange) {
    return _getTop(
      endpoint: 'artists',
      limit: limit,
      timeRange: timeRange,
      fromJson: Artist.fromJson,
    );
  }
}