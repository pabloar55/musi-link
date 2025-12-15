import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CheckSpotifyAuth {
  static const String _tokenKey = 'spotify_access_token';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Verifica si el usuario tiene un token guardado (estaba logueado)
  static Future<bool> isUserLoggedIn() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      return token != null && token.isNotEmpty;
    } catch (e) {
      print("Error al verificar token: $e");
      return false;
    }
  }

  /// Obtiene el token guardado
  static Future<String?> getSavedToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      print("Error al obtener token: $e");
      return null;
    }
  }

  /// Guarda el token después de la autenticación
  static Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (e) {
      print("Error al guardar token: $e");
    }
  }

  /// Elimina el token (logout)
  static Future<void> deleteToken() async {
    try {
      await _storage.delete(key: _tokenKey);
    } catch (e) {
      print("Error al eliminar token: $e");
    }
  }
}
