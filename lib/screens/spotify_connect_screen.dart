import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:musi_link/providers/firebase_providers.dart';
import 'package:musi_link/providers/service_providers.dart';
import 'package:musi_link/router/go_router_provider.dart';
import 'package:musi_link/screens/onboarding_screen.dart';
import 'package:musi_link/services/user_service.dart';
import 'package:musi_link/utils/error_reporter.dart';

/// Pantalla para conectar la cuenta de Spotify después de autenticarse
/// con Firebase. Solo se muestra cuando el splash no pudo restaurar sesión.
class SpotifyConnectScreen extends ConsumerStatefulWidget {
  const SpotifyConnectScreen({super.key});

  @override
  ConsumerState<SpotifyConnectScreen> createState() => _SpotifyConnectScreenState();
}

class _SpotifyConnectScreenState extends ConsumerState<SpotifyConnectScreen> {
  bool _isLoading = false;

  Future<void> _connectSpotify() async {
    setState(() => _isLoading = true);
    try {
      final result = await ref
          .read(spotifyServiceProvider)
          .authorizeAndConnect()
          .timeout(const Duration(minutes: 2), onTimeout: () => false);
      if (!mounted) return;

      if (result) {
        final auth = ref.read(firebaseAuthProvider);
        final uid = auth.currentUser?.uid;
        if (uid != null) {
          ref.read(musicProfileServiceProvider).syncMusicProfile(uid).ignore();
        }

        final prefs = await SharedPreferences.getInstance();
        final onboardingDone =
            prefs.getBool(OnboardingScreen.onboardingCompletedKey) ?? false;
        if (!mounted) return;

        // Actualizar el notifier ANTES de navegar para que el router re-evalúe
        // con spotifyConnected=true. Sin esto, el redirect devuelve al usuario
        // a /spotify-connect en cuanto GoRouter evalúa la nueva ruta.
        ref.read(appRouterNotifierProvider).setSpotifyConnected(
          onboardingDone: onboardingDone,
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.spotifyConnectError)),
        );
      }
    } on SpotifyAlreadyLinkedException {
      if (!mounted) return;
      setState(() => _isLoading = false);
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          content: Text(AppLocalizations.of(ctx)!.spotifyAlreadyLinkedError),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
            ),
          ],
        ),
      );
      if (!mounted) return;
      await ref.read(authServiceProvider).signOut();
    } catch (e, st) {
      reportError(e, st).ignore();
      if (!mounted) return;
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
