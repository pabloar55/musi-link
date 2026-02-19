import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:musi_link/core/tokens.dart';

class SpotifyGetStats {
  // Singleton para no crear instancias innecesarias
  SpotifyGetStats._();
  static final SpotifyGetStats instance = SpotifyGetStats._();

  Future<List<Map<String, String>>> getTopTracks(int limit, String timeRange) async {
    try {
      debugPrint("----------Obteniendo top tracks...---------");
      final url = Uri.parse(
        'https://api.spotify.com/v1/me/top/tracks?time_range=$timeRange&limit=$limit',
      );

      final token = await Tokens.getSavedToken();
      // Si no hay token, no hacemos la petición
      if (token == null || token.isEmpty) {
        debugPrint("❌ No hay token disponible");
        return [];
      }

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['items'] ?? [];
        List<Map<String, String>> tracks = items.map((item) {
          final artists = item['artists'] as List<dynamic>?;
          final images = item['album']?['images'] as List<dynamic>?;

          final trackName = item['name'] ?? 'Sin título';
          final artistName = (artists != null && artists.isNotEmpty)
              ? artists[0]['name'] ?? 'Artista desconocido'
              : 'Artista desconocido';
          final imageUrl = (images != null && images.isNotEmpty)
              ? images[0]['url'] ?? ''
              : '';

          return {
            'title': trackName.toString(),
            'artist': artistName.toString(),
            'image': imageUrl.toString(),
          };
        }).toList();
        return tracks;
      } else {
        debugPrint("❌ Error API: ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      debugPrint("❌ Error de conexión: $e");
      return [];
    }
  }

  Future<List<Map<String, String>>> getTopArtists(int limit, String timeRange) async {
    try {
      debugPrint("----------Obteniendo top artists...---------");
      final url = Uri.parse(
        'https://api.spotify.com/v1/me/top/artists?time_range=$timeRange&limit=$limit',
      );

      final token = await Tokens.getSavedToken();
      // Si no hay token, no hacemos la petición
      if (token == null || token.isEmpty) {
        debugPrint("❌ No hay token disponible");
        return [];
      }

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['items'] ?? [];
        List<Map<String, String>> artists = items.map((item) {
          final images = item['images'] as List<dynamic>?;

          final artistName = item['name'] ?? 'Artista desconocido';
          final imageUrl = (images != null && images.isNotEmpty)
              ? images[0]['url'] ?? ''
              : '';

          return {
            'name': artistName.toString(),
            'image': imageUrl.toString(),
          };
        }).toList();
        return artists;
      } else {
        debugPrint("❌ Error API: ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      debugPrint("❌ Error de conexión: $e");
      return [];
    }
  }
}