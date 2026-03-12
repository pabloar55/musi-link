import 'package:flutter/material.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:musi_link/services/spotify_service.dart';
import 'package:musi_link/screens/home/main_screen.dart';

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

  /// Si ya hay credenciales de Spotify guardadas, intenta restaurar la sesión.
  /// El paquete `spotify` renueva el token automáticamente con el refresh_token.
  Future<void> _checkExistingToken() async {
    // Intentar restaurar sesión silenciosamente (refresh automático si expiró)
    final restored = await _spotifyService.tryRestoreSession();
    if (restored && mounted) {
      _goToMain();
      return;
    }
    // No hay credenciales o falló → mostrar botón "Conectar Spotify"
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
        SnackBar(content: Text(AppLocalizations.of(context)!.spotifyConnectError)),
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
    final l10n = AppLocalizations.of(context)!;

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
                l10n.spotifyConnectTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.spotifyConnectDescription,
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
                  label: Text(l10n.spotifyConnectButton),
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
