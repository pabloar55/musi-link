import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacenamiento seguro de credenciales OAuth de Spotify (PKCE).
///
/// Guarda access_token, refresh_token, expiration y code_verifier
/// en [FlutterSecureStorage]. El refresh es manejado por el paquete `spotify`.
class Tokens {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _accessTokenKey = 'spotify_access_token';
  static const String _refreshTokenKey = 'spotify_refresh_token';
  static const String _expirationKey = 'spotify_expiration';
  static const String _codeVerifierKey = 'spotify_code_verifier';

  /// Guarda las credenciales OAuth completas.
  static Future<void> saveCredentials({
    required String accessToken,
    required String refreshToken,
    required String expiration,
    required String codeVerifier,
  }) async {
    try {
      await _storage.write(key: _accessTokenKey, value: accessToken);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
      await _storage.write(key: _expirationKey, value: expiration);
      await _storage.write(key: _codeVerifierKey, value: codeVerifier);
    } catch (e) {
      debugPrint("Error al guardar credenciales: $e");
    }
  }

  /// Devuelve un mapa con las credenciales guardadas, o `null` si no hay
  /// refresh_token (= nunca se autorizó o se hizo logout).
  static Future<Map<String, String?>?> getSavedCredentials() async {
    try {
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      if (refreshToken == null || refreshToken.isEmpty) return null;

      final codeVerifier = await _storage.read(key: _codeVerifierKey);
      if (codeVerifier == null || codeVerifier.isEmpty) return null;

      return {
        'accessToken': await _storage.read(key: _accessTokenKey),
        'refreshToken': refreshToken,
        'expiration': await _storage.read(key: _expirationKey),
        'codeVerifier': codeVerifier,
      };
    } catch (e) {
      debugPrint("Error al leer credenciales: $e");
      return null;
    }
  }

  /// Elimina todas las credenciales de Spotify.
  static Future<void> deleteAll() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _expirationKey);
      await _storage.delete(key: _codeVerifierKey);
    } catch (e) {
      debugPrint("Error al eliminar credenciales: $e");
    }
  }
}
