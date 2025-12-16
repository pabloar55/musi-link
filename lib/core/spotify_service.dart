import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:musi_link/core/tokens.dart';
import 'package:spotify_sdk/spotify_sdk.dart';

class SpotifyService {
  // Singleton
  SpotifyService._();
  static final SpotifyService instance = SpotifyService._();

  final String _clientId = dotenv.env['SPOTIFY_CLIENT_ID'] ?? "";
  final String _redirectUrl = dotenv.env['SPOTIFY_REDIRECT_URL'] ?? "";

  Future<bool> authorizeAndConnect() async {
    var _accessToken = await getNewToken();
    if (_accessToken == null) {
      return false;
    }
    await Tokens.saveToken(_accessToken);
    return true;
  }

  static Future<bool> isUserLoggedIn() async {
    try {
      final token = await Tokens.getSavedToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      print("Error al verificar token: $e");
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
      print(e.toString());
      return null;
    }
  }
}
