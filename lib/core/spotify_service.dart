import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:spotify_sdk/spotify_sdk.dart';

class SpotifyService {
  // Singleton
  SpotifyService._();
  static final SpotifyService instance = SpotifyService._();

  // TUS CONSTANTES (Asegúrate que coinciden con Spotify Dashboard)
  final String _clientId = '3629aecf6254423facc915c0876fde0d';
  final String _redirectUrl = 'musilink://callback'; 
  
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Función ÚNICA para conectar
  Future<void> authorizeAndConnect() async {
    try {
      print("Iniciando autenticación");
      
      // PASO 1: Obtener el Token (Esto abre la app de Spotify y pide permiso)
      var accessToken = await SpotifySdk.getAccessToken(
        clientId: _clientId,
        redirectUrl: _redirectUrl,
        // IMPORTANTE: 'app-remote-control' es obligatorio para conectar después
        scope: "app-remote-control,user-modify-playback-state,playlist-read-private,user-top-read",
      );

      if (accessToken.isEmpty) {
        print("No se obtuvo el token. El usuario canceló o hubo error.");
        return;
      }

      print("Token obtenido: $accessToken");

      print("Conectando al App Remote...");
      var result = await SpotifySdk.connectToSpotifyRemote(
        clientId: _clientId,    
        redirectUrl: _redirectUrl,
      );

      if (result) {
        print("¡CONEXIÓN TOTALMENTE EXITOSA!");
      } else {
        print("Falló la conexión al Remote (pero tenemos token)");
      }

    } on PlatformException catch (e) {
      // Manejo específico de errores
      if (e.code == 'UserNotAuthorizedException') {
        print("Error de Autorización: Revisa el SHA-1 en el Dashboard de Spotify.");
      } else if (e.code == 'CouldNotFindSpotifyApp') {
        print("La app de Spotify no está instalada.");
      } else {
        print("Error de Plataforma: ${e.code} - ${e.message}");
      }
    } catch (e) {
      print("Error general: $e");
    }
  }
}