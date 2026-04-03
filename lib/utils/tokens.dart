import 'package:musi_link/utils/error_reporter.dart';
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
      await Future.wait([
        _storage.write(key: _accessTokenKey, value: accessToken),
        _storage.write(key: _refreshTokenKey, value: refreshToken),
        _storage.write(key: _expirationKey, value: expiration),
        _storage.write(key: _codeVerifierKey, value: codeVerifier),
      ]);
    } catch (e, stack) {
      await reportError(e, stack);
    }
  }

  /// Devuelve un mapa con las credenciales guardadas, o `null` si no hay
  /// refresh_token (= nunca se autorizó o se hizo logout).
  static Future<Map<String, String?>?> getSavedCredentials() async {
    try {
      final results = await Future.wait([
        _storage.read(key: _refreshTokenKey),
        _storage.read(key: _codeVerifierKey),
        _storage.read(key: _accessTokenKey),
        _storage.read(key: _expirationKey),
      ]);

      final refreshToken = results[0];
      final codeVerifier = results[1];

      if (refreshToken == null || refreshToken.isEmpty) return null;
      if (codeVerifier == null || codeVerifier.isEmpty) return null;

      return {
        'accessToken': results[2],
        'refreshToken': refreshToken,
        'expiration': results[3],
        'codeVerifier': codeVerifier,
      };
    } catch (e, stack) {
      await reportError(e, stack);
      return null;
    }
  }

  /// Elimina todas las credenciales de Spotify.
  static Future<void> deleteAll() async {
    try {
      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _expirationKey),
        _storage.delete(key: _codeVerifierKey),
      ]);
    } catch (e, stack) {
      await reportError(e, stack);
    }
  }
}
