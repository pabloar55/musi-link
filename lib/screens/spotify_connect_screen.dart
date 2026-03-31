import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:musi_link/providers/firebase_providers.dart';
import 'package:musi_link/providers/service_providers.dart';
import 'package:musi_link/screens/onboarding_screen.dart';

/// Pantalla para conectar la cuenta de Spotify después de autenticarse
/// con Firebase. Si el usuario ya tiene token de Spotify válido,
/// se salta automáticamente a MainScreen (o al onboarding si es la primera vez).
class SpotifyConnectScreen extends ConsumerStatefulWidget {
  const SpotifyConnectScreen({super.key});

  @override
  ConsumerState<SpotifyConnectScreen> createState() => _SpotifyConnectScreenState();
}

class _SpotifyConnectScreenState extends ConsumerState<SpotifyConnectScreen> {
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
    final restored = await ref.read(spotifyServiceProvider).tryRestoreSession();

    // Leer flag de onboarding
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone =
        prefs.getBool(OnboardingScreen.onboardingCompletedKey) ?? false;

    if (restored && mounted) {
      // Sincronizar perfil musical (SpotifyService ya no llama esto)
      final auth = ref.read(firebaseAuthProvider);
      final uid = auth.currentUser?.uid;
      if (uid != null) {
        ref.read(musicProfileServiceProvider).syncMusicProfile(uid).ignore();
      }
      if (onboardingDone) {
        context.go('/');
      } else {
        context.go('/onboarding');
      }
      return;
    }

    // No hay credenciales o falló → mostrar botón "Conectar Spotify"
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _connectSpotify() async {
    setState(() => _isLoading = true);
    final result = await ref.read(spotifyServiceProvider).authorizeAndConnect();
    if (!mounted) return;

    if (result) {
      // Sincronizar perfil musical (SpotifyService ya no llama esto)
      final auth = ref.read(firebaseAuthProvider);
      final uid = auth.currentUser?.uid;
      if (uid != null) {
        ref.read(musicProfileServiceProvider).syncMusicProfile(uid).ignore();
      }

      final prefs = await SharedPreferences.getInstance();
      final onboardingDone =
          prefs.getBool(OnboardingScreen.onboardingCompletedKey) ?? false;
      if (!mounted) return;

      if (onboardingDone) {
        context.go('/');
      } else {
        context.go('/onboarding');
      }
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.spotifyConnectError)),
      );
    }
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
              FaIcon(
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
                  icon: const FaIcon(FontAwesomeIcons.spotify),
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
