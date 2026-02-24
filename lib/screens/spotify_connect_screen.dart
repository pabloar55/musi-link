import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:musi_link/core/spotify_service.dart';
import 'package:musi_link/screens/main_screen.dart';

/// Pantalla para conectar la cuenta de Spotify después de autenticarse
/// con Firebase. Si el usuario ya tiene token de Spotify válido,
/// se salta automáticamente a MainScreen.
class SpotifyConnectScreen extends StatefulWidget {
  const SpotifyConnectScreen({super.key});

  @override
  State<SpotifyConnectScreen> createState() => _SpotifyConnectScreenState();
}

class _SpotifyConnectScreenState extends State<SpotifyConnectScreen> {
  final SpotifyService _spotifyService = SpotifyService.instance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkExistingToken();
  }

  /// Si ya hay un token de Spotify válido, salta directamente a MainScreen.
  Future<void> _checkExistingToken() async {
    final isLoggedIn = await SpotifyService.isUserLoggedIn();
    if (isLoggedIn && mounted) {
      _goToMain();
      return;
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _connectSpotify() async {
    setState(() => _isLoading = true);
    final result = await _spotifyService.authorizeAndConnect();
    if (!mounted) return;

    if (result) {
      _goToMain();
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al conectar con Spotify")),
      );
    }
  }

  void _goToMain() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Icon(
                FontAwesomeIcons.spotify,
                size: 80,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                "Conecta tu Spotify",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                "Para ver tus estadísticas musicales necesitamos acceso a tu cuenta de Spotify.",
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _connectSpotify,
                  icon: const Icon(FontAwesomeIcons.spotify),
                  label: const Text("Conectar Spotify"),
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
