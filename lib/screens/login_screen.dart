import 'package:flutter/material.dart';
import 'package:musi_link/core/spotify_service.dart';
import 'package:spotify_sdk/spotify_sdk.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final SpotifyService _spotifyService = SpotifyService.instance;
  @override
  Widget build(BuildContext context) {
    return  Column(
              children: [
                // En el botón de "Conectar con Spotify"
                ElevatedButton(
                  onPressed: () async {
                    await _spotifyService.authorizeAndConnect();
                  },
                  child: Text("Conectar Spotify"),
                ),
                   // List<Map<String, String>> _misCanciones = [];
                ElevatedButton(
                  onPressed: () async {

                    // 2. Pedir las canciones
                    var canciones = await SpotifyService.instance.getTopTracks();
                    
                   /* // 3. Actualizar la pantalla
                    setState(() {
                      _misCanciones = canciones;
                    });*/
                    
                    // Imprimir en consola para verlas ya
                    for (var c in canciones) {
                      print("🎵 ${c['title']} - ${c['artist']}");
                    }
                                    },
                  child: Text("Ver mis Top Tracks"),
                )
              ],
            );
  }
}