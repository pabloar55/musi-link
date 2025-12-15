import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:spotify_sdk/spotify_sdk.dart';

class SpotifyService {
  // Singleton
  SpotifyService._();
  static final SpotifyService instance = SpotifyService._();
  static const String _tokenKey = 'spotify_access_token';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  final String _clientId = dotenv.env['SPOTIFY_CLIENT_ID'] ?? "";
  final String _redirectUrl = dotenv.env['SPOTIFY_REDIRECT_URL'] ?? "";
  String _accessToken = "";

  Future<bool> authorizeAndConnect() async {
    try {
      _accessToken = await SpotifySdk.getAccessToken(
        clientId: _clientId,
        redirectUrl: _redirectUrl,
        scope: "app-remote-control,user-modify-playback-state,playlist-read-private,user-top-read",
      );

      if (_accessToken.isEmpty) {
        return false;
      }

        await saveToken(_accessToken);
        return true;

    } on PlatformException catch (e) {

      if (e.code == 'UserNotAuthorizedException') {
        print(
          "Error de Autorización: Revisa el SHA-1 en el Dashboard de Spotify.",
        );
      } else if (e.code == 'CouldNotFindSpotifyApp') {
        print("La app de Spotify no está instalada.");
      } else {
        print("Error de Plataforma: ${e.code} - ${e.message}");
      }
      return false;
    } 
  }
    static Future<bool> isUserLoggedIn() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      return token != null && token.isNotEmpty;
    } catch (e) {
      print("Error al verificar token: $e");
      return false;
    }
  }

  static Future<String?> getSavedToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      print("Error al obtener token: $e");
      return null;
    }
  }

  static Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (e) {
      print("Error al guardar token: $e");
    }
  }

  static Future<void> deleteToken() async {
    try {
      await _storage.delete(key: _tokenKey);
    } catch (e) {
      print("Error al eliminar token: $e");
    }
  }

}
