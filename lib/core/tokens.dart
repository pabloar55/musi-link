import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:musi_link/core/spotify_service.dart';

class Tokens {
  static const String _tokenKey = 'spotify_access_token';
  static const String _timeKey = 'time';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static Future<String?> getSavedToken() async {
    try {
      var fechaGuardado = DateTime.parse(
        await _storage.read(key: _timeKey) ?? "",
      );
      if (DateTime.now().difference(fechaGuardado).inMinutes >= 58) {
        var tokenNuevo = await SpotifyService.instance.getNewToken();
        if (tokenNuevo != null) {
          await saveToken(tokenNuevo);
        }
        return tokenNuevo;
      }
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      print("Error al obtener token: $e");
      return null;
    }
  }

  static Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _timeKey, value: DateTime.now().toString());
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
