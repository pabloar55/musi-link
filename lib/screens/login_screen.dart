import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:musi_link/core/spotify_service.dart';
import 'package:musi_link/screens/main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final SpotifyService _spotifyService = SpotifyService.instance;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Spacer(),
        ElevatedButton(
          onPressed: () async {
            var result = await _spotifyService.authorizeAndConnect();
            if (!context.mounted) return;
            if (result) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MainScreen()),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Error al conectar con Spotify")),
              );
            }
          },
          child: Row(
            children: [
              Text("Conectar Spotify"),
              Icon(FontAwesomeIcons.spotify),
            ],
          ),
        ),
        Spacer(),
        /*List<Map<String, String>> _misCanciones = [];
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
        ),*/
      ],
    );
  }
}
