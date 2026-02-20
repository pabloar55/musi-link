import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Tokens {

  // Callback para obtener un nuevo token cuando el actual expire. 
  static Future<String?> Function()? onTokenExpired; 

  static const String _tokenKey = 'spotify_access_token';
  static const String _timeKey = 'time';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<String?> getSavedToken() async {
    try {
      final timeString = await _storage.read(key: _timeKey);

      // Si no hay fecha guardada, no hay token válido
      if (timeString == null || timeString.isEmpty) {
        return null;
      }

      final fechaGuardado = DateTime.tryParse(timeString);
      if (fechaGuardado == null) {
        return null;
      }

      // Si han pasado 58+ minutos, el token expiró, se pide uno nuevo
      if (DateTime.now().difference(fechaGuardado).inMinutes >= 58) {
        final tokenNuevo = await onTokenExpired?.call();
        if (tokenNuevo != null) {
          await saveToken(tokenNuevo);
        }
        return tokenNuevo;
      }

      return await _storage.read(key: _tokenKey);
    } catch (e) {
      debugPrint("Error al obtener token: $e");
      return null;
    }
  }

  static Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _timeKey, value: DateTime.now().toString());
      await _storage.write(key: _tokenKey, value: token);
    } catch (e) {
      debugPrint("Error al guardar token: $e");
    }
  }

  static Future<void> deleteToken() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _timeKey);
    } catch (e) {
      debugPrint("Error al eliminar token: $e");
    }
  }
}
