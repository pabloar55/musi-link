import 'dart:async';
import 'package:musi_link/utils/error_reporter.dart';

import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:musi_link/utils/tokens.dart';
import 'package:musi_link/services/user_service.dart';
import 'package:musi_link/models/track.dart'
    as app; // Alias para evitar colisiones
import 'package:spotify/spotify.dart';

/// Servicio centralizado de Spotify.
///
/// Usa el paquete `spotify` (0.16.0) con flujo PKCE para:
/// - Autorización inicial (abre el navegador).
/// - Refresh silencioso (HTTP, sin UI) cuando el token expira.
/// - Acceso a la API (top tracks, artists, etc.) vía [_api].
class SpotifyService {
  SpotifyService({
    required UserService userService,
    required FirebaseAuth auth,
  })  : _userService = userService,
        _auth = auth;

  final UserService _userService;
  final FirebaseAuth _auth;
  static const String _clientId =
      String.fromEnvironment('SPOTIFY_CLIENT_ID');
  static const String _redirectUri =
      String.fromEnvironment('SPOTIFY_REDIRECT_URL');

  static const List<String> _scopes = [
    'app-remote-control',
    'user-modify-playback-state',
    'playlist-read-private',
    'user-top-read',
    'user-read-currently-playing',
  ];

  /// Instancia de SpotifyApi. Empieza como null y se inicializa al conectar o restaurar sesión.
  SpotifyApi? _api;

  /// Getter del cliente de Spotify.
  SpotifyApi get api {
    if (_api == null) throw StateError('SpotifyApi no inicializado');
    return _api!;
  }

  bool get isInitialized => _api != null;

  Timer? _nowPlayingTimer;
  app.Track? _lastNowPlayingTrack;
  Future<void>? _syncInProgress;

  /// Inicia el polling de la canción actual.
  void startPollingNowPlaying() {
    stopPollingNowPlaying(); // Asegurarse de no tener multiples timers

    // Ejecutar inmediatamente la primera vez
    _fetchAndUpdateNowPlaying();

    // Polling cada 30 segundos
    _nowPlayingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchAndUpdateNowPlaying();
    });
  }

  /// Detiene el polling de la canción actual.
  void stopPollingNowPlaying() {
    _nowPlayingTimer?.cancel();
    _nowPlayingTimer = null;
  }

  Future<void> _fetchAndUpdateNowPlaying() async {
    if (!isInitialized) return;

    final track = await getCurrentlyPlayingTrack();

    // Evitar actualizaciones innecesarias si es la misma canción
    if (track != null &&
        _lastNowPlayingTrack != null &&
        track.spotifyUrl == _lastNowPlayingTrack!.spotifyUrl) {
      return;
    }

    _lastNowPlayingTrack = track;

    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      await _userService.updateNowPlaying(firebaseUser.uid, track);
    }
  }

  /// Método para obtener la pista que se está reproduciendo actualmente
  Future<app.Track?> getCurrentlyPlayingTrack() async {
    if (_api == null) return null;
    try {
      final playbackState = await _api!.player.currentlyPlaying();
      final item = playbackState.item;
      if (item is Track) {
        final images = item.album?.images;
        final imageUrl = (images != null && images.isNotEmpty)
            ? images.first.url ?? ''
            : '';
        final artistName = (item.artists != null && item.artists!.isNotEmpty)
            ? item.artists!.first.name ?? 'Artista desconocido'
            : 'Artista desconocido';

        return app.Track(
          title: item.name ?? 'Sin título',
          artist: artistName,
          imageUrl: imageUrl,
          spotifyUrl: (item.id != null && item.id!.isNotEmpty)
              ? 'https://open.spotify.com/track/${item.id}'
              : '',
        );
      }
      return null;
    } catch (e, stack) {
      await reportError(e, stack);
      return null;
    }
  }

  /// Abre el flujo OAuth PKCE en el navegador.
  /// Solo se necesita la primera vez o si el refresh_token se invalida.
  Future<bool> authorizeAndConnect() async {
    try {
      final codeVerifier =
          SpotifyApi.generateCodeVerifier(); // Genera un codigo aleatorio para PKCE

      final credentials = SpotifyApiCredentials.pkce(
        // Se cifra para enviarlo a Spotify
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
        options: const FlutterWebAuth2Options(preferEphemeral: true),
      );

      // Crear instancia de SpotifyApi intercambiando el code por tokens
      _api = SpotifyApi.fromAuthCodeGrant(grant, resultUrl);

      // Guardar credenciales para restaurar después
      await _saveCredentials(preserveCodeVerifier: codeVerifier);

      // Sincronizar perfil de Spotify en Firestore
      await _syncSpotifyProfileToFirestore();

      // Sincronizar datos musicales en Firestore — gestionado por el caller
      startPollingNowPlaying();

      return true;
    } on SpotifyAlreadyLinkedException {
      rethrow;
    } catch (e, stack) {
      await reportError(e, stack);
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

      // Sincronizar datos musicales en Firestore — gestionado por el caller
      startPollingNowPlaying();

      return true;
    } catch (e, stack) {
      await reportError(e, stack);
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
    } catch (e, stack) {
      await reportError(e, stack);
    }
  }

  /// Deduplicates concurrent calls: si ya hay una sincronización en vuelo,
  /// ambos llamadores awaitan el mismo Future en lugar de lanzar uno nuevo.
  Future<void> _syncSpotifyProfileToFirestore() {
    return _syncInProgress ??= _doSyncSpotifyProfileToFirestore()
        .whenComplete(() => _syncInProgress = null);
  }

  Future<void> _doSyncSpotifyProfileToFirestore() async {
    if (_api == null) return;

    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return;

      final spotifyUser = await _api!.me.get();
      final spotifyId = spotifyUser.id ?? '';
      final images = spotifyUser.images;
      final spotifyPhotoUrl = (images != null && images.isNotEmpty)
          ? images.first.url ?? ''
          : '';

      if (spotifyId.isEmpty && spotifyPhotoUrl.isEmpty) return;

      await _userService.linkSpotifyProfile(
        firebaseUser.uid,
        spotifyId: spotifyId,
        photoUrl: spotifyPhotoUrl,
      );
    } on SpotifyAlreadyLinkedException {
      rethrow;
    } catch (e, stack) {
      await reportError(e, stack);
    }
  }

  Future<void> disconnect() async {
    stopPollingNowPlaying();
    _lastNowPlayingTrack = null;

    // Limpiar nowPlaying en Firestore (best-effort, no debe bloquear el sign-out)
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        await _userService.updateNowPlaying(firebaseUser.uid, null);
      }
    } catch (e, stack) {
      await reportError(e, stack);
    }

    _api = null;
    await Tokens.deleteAll();
  }
}
