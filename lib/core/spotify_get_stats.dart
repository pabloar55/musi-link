import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:musi_link/core/tokens.dart';

class SpotifyGetStats {
  Future<List<Map<String, String>>> getTopTracks() async {
    try {
      print("----------Obteniendo top tracks...---------");
      // time_range: 'short_term' (mes), 'medium_term' (6 meses), 'long_term' (siempre)
      // limit: número de canciones (máx 50)
      final url = Uri.parse(
        'https://api.spotify.com/v1/me/top/tracks?time_range=medium_term&limit=10',
      );

      final token = await Tokens.getSavedToken();

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['items'];

        // Mapeamos los datos para sacar solo Titulo y Artista
        List<Map<String, String>> tracks = items.map((item) {
          final trackName = item['name'];
          final artistName = item['artists'][0]['name']; // Primer artista
          final imageUrl = item['album']['images'][0]['url']; // Carátula

          return {
            'title': trackName.toString(),
            'artist': artistName.toString(),
            'image': imageUrl.toString(),
          };
        }).toList();
        return tracks;
      } else {
        print("❌ Error API: ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      print("❌ Error de conexión: $e");
      return [];
    }
  }
}