import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:musi_link/services/music_profile_service.dart';
import 'package:musi_link/utils/tokens.dart';
import 'package:musi_link/services/user_service.dart';
import 'package:spotify/spotify.dart';

/// Servicio centralizado de Spotify.
///
/// Usa el paquete `spotify` (0.16.0) con flujo PKCE para:
/// - Autorización inicial (abre el navegador).
/// - Refresh silencioso (HTTP, sin UI) cuando el token expira.
/// - Acceso a la API (top tracks, artists, etc.) vía [_api].
class SpotifyService {
  SpotifyService._();
  static final SpotifyService instance = SpotifyService._();

  final String _clientId = dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';
  final String _redirectUri = dotenv.env['SPOTIFY_REDIRECT_URL'] ?? '';

  static const List<String> _scopes = [
    'app-remote-control',
    'user-modify-playback-state',
    'playlist-read-private',
    'user-top-read',
  ];

  /// Instancia de SpotifyApi. Empieza como null y se inicializa al conectar o restaurar sesión.
  SpotifyApi? _api;

  /// Getter del cliente de Spotify.
  SpotifyApi get api {
    if (_api == null) throw StateError('SpotifyApi no inicializado');
    return _api!;
  }

  bool get isInitialized => _api != null;

  /// Abre el flujo OAuth PKCE en el navegador.
  /// Solo se necesita la primera vez o si el refresh_token se invalida.
  Future<bool> authorizeAndConnect() async {
    try {
      final codeVerifier = SpotifyApi.generateCodeVerifier(); // Genera un codigo aleatorio para PKCE

      final credentials = SpotifyApiCredentials.pkce( // Se cifra para enviarlo a Spotify
        _clientId,
        codeVerifier: codeVerifier,
      );

      final grant = SpotifyApi.authorizationCodeGrant(credentials); 
      final redirectUri = Uri.parse(_redirectUri);
      final authUri = grant.getAuthorizationUrl(redirectUri, scopes: _scopes);

      // Abre el navegador para que el usuario autorice.
      final resultUrl = await FlutterWebAuth2.authenticate(
        url: authUri.toString(),
        callbackUrlScheme: redirectUri.scheme,
        options: const FlutterWebAuth2Options(
          preferEphemeral: true,
        ),
      );

      // Crear instancia de SpotifyApi intercambiando el code por tokens
      _api = SpotifyApi.fromAuthCodeGrant(grant, resultUrl);

      // Guardar credenciales para restaurar después
      await _saveCredentials(preserveCodeVerifier: codeVerifier);
      

      // Sincronizar perfil de Spotify en Firestore
      await _syncSpotifyProfileToFirestore();

      // Sincronizar datos musicales en Firestore
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        await MusicProfileService.instance.syncMusicProfile(firebaseUser.uid);
      }

      debugPrint('✅ Spotify conectado vía PKCE');
      return true;
    } catch (e) {
      debugPrint('❌ Error en autorización PKCE: $e');
      return false;
    }
  }

  /// Intenta restaurar la sesión de Spotify usando credenciales guardadas.
  /// Si el access_token expiró, el paquete `spotify` lo renueva
  /// automáticamente con el refresh_token al hacer la primera petición.
  ///
  /// Devuelve `true` si se restauró correctamente.
  Future<bool> tryRestoreSession() async {
    try {
      final saved = await Tokens.getSavedCredentials();
      if (saved == null) return false;

      final credentials = SpotifyApiCredentials.pkce(
        _clientId,
        accessToken: saved['accessToken'],
        refreshToken: saved['refreshToken'],
        expiration: DateTime.tryParse(saved['expiration'] ?? ''),
        codeVerifier: saved['codeVerifier'],
        scopes: _scopes,
      );

      // asyncFromCredentials refresca automáticamente si el token expiró
      _api = await SpotifyApi.asyncFromCredentials(credentials);

      // Guardar las credenciales actualizadas
      await _saveCredentials(preserveCodeVerifier: saved['codeVerifier']);

      // Re-sincronizar perfil de Spotify en Firestore
      await _syncSpotifyProfileToFirestore();

      // Sincronizar datos musicales en Firestore
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        await MusicProfileService.instance.syncMusicProfile(firebaseUser.uid);
      }

      debugPrint('✅ Sesión de Spotify restaurada');
      return true;
    } catch (e) {
      debugPrint('❌ Error al restaurar sesión: $e');
      return false;
    }
  }

  Future<void> _saveCredentials({String? preserveCodeVerifier}) async {
    if (_api == null) return;
    try {
      final creds = await _api!.getCredentials();
      await Tokens.saveCredentials(
        accessToken: creds.accessToken ?? '',
        refreshToken: creds.refreshToken ?? '',
        expiration: creds.expiration?.toIso8601String() ?? '',
        codeVerifier: creds.codeVerifier ?? preserveCodeVerifier ?? '',
      );
    } catch (e) {
      debugPrint('❌ Error al guardar credenciales: $e');
    }
  }

  Future<void> _syncSpotifyProfileToFirestore() async {
    if (_api == null) return;

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return;

      final spotifyUser = await _api!.me.get();
      final spotifyId = spotifyUser.id ?? '';
      final images = spotifyUser.images;
      final spotifyPhotoUrl =
          (images != null && images.isNotEmpty) ? images.first.url ?? '' : '';

      if (spotifyId.isEmpty && spotifyPhotoUrl.isEmpty) return;

      await UserService.instance.linkSpotifyProfile(
        firebaseUser.uid,
        spotifyId: spotifyId,
        photoUrl: spotifyPhotoUrl,
      );
    } catch (e) {
      debugPrint('❌ Error al sincronizar perfil de Spotify: $e');
    }
  }

  Future<void> disconnect() async {
    _api = null;
    await Tokens.deleteAll();
  }
}
