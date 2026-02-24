import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:musi_link/core/tokens.dart';
import 'package:spotify_sdk/spotify_sdk.dart';

class SpotifyService {
  SpotifyService._() {
    // Callback de Tokens
    Tokens.onTokenExpired = () => getNewToken();
  }
  // Singleton
  static final SpotifyService instance = SpotifyService._();

  final String _clientId = dotenv.env['SPOTIFY_CLIENT_ID'] ?? "";
  final String _redirectUrl = dotenv.env['SPOTIFY_REDIRECT_URL'] ?? "";

  Future<bool> authorizeAndConnect() async {
    var accessToken = await getNewToken();
    if (accessToken == null) {
      return false;
    }
    await Tokens.saveToken(accessToken);
    return true;
  }

  static Future<bool> isUserLoggedIn() async {
    try {
      instance;
      return await Tokens.hasValidToken();
    } catch (e) {
      debugPrint("Error al verificar token: $e");
      return false;
    }
  }

  Future<String?> getNewToken() async {
    try {
      return await SpotifySdk.getAccessToken(
        clientId: _clientId,
        redirectUrl: _redirectUrl,
        scope:
            "app-remote-control,user-modify-playback-state,playlist-read-private,user-top-read",
      );
    } on Exception catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }
}
