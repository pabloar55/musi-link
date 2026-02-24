import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Tokens {

  // Callback para obtener un nuevo token cuando el actual expire. 
  static Future<String?> Function()? onTokenExpired; 

  static const String _tokenKey = 'spotify_access_token';
  static const String _timeKey = 'time';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Comprueba si hay un token guardado y no expirado, SIN intentar renovar.
  static Future<bool> hasValidToken() async {
    try {
      final timeString = await _storage.read(key: _timeKey);
      final fechaToken = timeString != null && timeString.isNotEmpty
          ? DateTime.tryParse(timeString)
          : null;

      final bool expirado = fechaToken == null ||
          DateTime.now().difference(fechaToken).inMinutes >= 58;

      if (expirado) return false;

      final tokenGuardado = await _storage.read(key: _tokenKey);
      return tokenGuardado != null && tokenGuardado.isNotEmpty;
    } catch (e) {
      debugPrint("Error al verificar token: $e");
      return false;
    }
  }

  static Future<String?> getSavedToken() async {
    try {
      final timeString = await _storage.read(key: _timeKey);
      final fechaToken = timeString != null && timeString.isNotEmpty
          ? DateTime.tryParse(timeString)
          : null;

      final bool expirado = fechaToken == null ||
          DateTime.now().difference(fechaToken).inMinutes >= 58;

      final tokenGuardado = await _storage.read(key: _tokenKey);

      if (tokenGuardado == null || expirado) {
        debugPrint("⏰ Token nulo o expirado, intentando renovar...");
        final tokenNuevo = await onTokenExpired?.call();
        if (tokenNuevo != null) {
          await saveToken(tokenNuevo);
          return tokenNuevo;
        } else {
          debugPrint("❌ No se pudo renovar el token");
          return null;
        }
      }

      return tokenGuardado;
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
