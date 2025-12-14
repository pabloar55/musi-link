import 'package:flutter/material.dart';
import 'package:musi_link/core/spotify_service.dart';

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
                // En el botón de "Ver Estadísticas"
                /*ElevatedButton(
                  onPressed: () async {
                    try {
                      var tracks = await _spotifyService.getTopTracks();
                      print("Tus top tracks: $tracks");
                      // Aquí actualizarías el estado para mostrarlo en una lista
                    } catch (e) {
                      print(e);
                    }
                  },
                  child: Text("Cargar Top Tracks"),
                )*/
              ],
            );
  }
}