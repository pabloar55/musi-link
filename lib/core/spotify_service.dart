import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:spotify_sdk/spotify_sdk.dart';

class SpotifyService {
  // Singleton
  SpotifyService._();
  static final SpotifyService instance = SpotifyService._();

  final String _clientId = dotenv.env['SPOTIFY_CLIENT_ID'] ?? "";
  final String _redirectUrl = dotenv.env['SPOTIFY_REDIRECT_URL'] ?? "";
  String _accessToken = "";
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Función ÚNICA para conectar
  Future<void> authorizeAndConnect() async {
    try {
      print("Iniciando autenticación");
      
      // PASO 1: Obtener el Token (Esto abre la app de Spotify y pide permiso)
        _accessToken = await SpotifySdk.getAccessToken(
        clientId: _clientId,
        redirectUrl: _redirectUrl,
        // IMPORTANTE: 'app-remote-control' es obligatorio para conectar después
        scope: "app-remote-control,user-modify-playback-state,playlist-read-private,user-top-read",
      );

      if (_accessToken.isEmpty) {
        print("No se obtuvo el token. El usuario canceló o hubo error.");
        return;
      }

      print("Token obtenido: $_accessToken");

      print("Conectando al App Remote...");
      var result = await SpotifySdk.connectToSpotifyRemote(
        clientId: _clientId,    
        redirectUrl: _redirectUrl,
      );

      if (result) {
        print("¡CONEXIÓN TOTALMENTE EXITOSA!");
      } else {
        print("Falló la conexión al Remote (pero tenemos token)");
      }
      

    } on PlatformException catch (e) {
      // Manejo específico de errores
      if (e.code == 'UserNotAuthorizedException') {
        print("Error de Autorización: Revisa el SHA-1 en el Dashboard de Spotify.");
      } else if (e.code == 'CouldNotFindSpotifyApp') {
        print("La app de Spotify no está instalada.");
      } else {
        print("Error de Plataforma: ${e.code} - ${e.message}");
      }
    } catch (e) {
      print("Error general: $e");
    }
  }
  Future<List<Map<String, String>>> getTopTracks() async {
  try {
    // time_range: 'short_term' (mes), 'medium_term' (6 meses), 'long_term' (siempre)
    // limit: número de canciones (máx 50)
    final url = Uri.parse(
        'https://api.spotify.com/v1/me/top/tracks?time_range=medium_term&limit=10');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $_accessToken', // Usamos el token aquí
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

      print("🔥 Top Tracks descargados: ${tracks.length}");
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