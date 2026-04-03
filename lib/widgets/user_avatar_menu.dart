import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/models/app_user.dart';
import 'package:musi_link/providers/firebase_providers.dart';
import 'package:musi_link/providers/service_providers.dart';
import 'package:musi_link/providers/theme_provider.dart';
import 'package:musi_link/widgets/signing_out_dialog.dart';

enum _UserMenuAction { profile, darkLightMode, logout }

class UserAvatarMenu extends ConsumerStatefulWidget {
  const UserAvatarMenu({super.key});

  @override
  ConsumerState<UserAvatarMenu> createState() => _UserAvatarMenuState();
}

class _UserAvatarMenuState extends ConsumerState<UserAvatarMenu> {
  Future<AppUser?>? _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _getCurrentAppUser();
  }

  Future<AppUser?> _getCurrentAppUser() async {
    final firebaseUser = ref.read(firebaseAuthProvider).currentUser;
    if (firebaseUser == null) return null;
    return ref.read(userServiceProvider).getUser(firebaseUser.uid);
  }

  Future<void> _handleUserMenuAction(_UserMenuAction action) async {
    switch (action) {
      case _UserMenuAction.profile:
        final firebaseUser = ref.read(firebaseAuthProvider).currentUser;
        if (firebaseUser == null) return;
        final appUser =
            await ref.read(userServiceProvider).getUser(firebaseUser.uid);
        if (appUser != null && mounted) {
          unawaited(context.push('/profile', extra: appUser));
        }
        break;

      case _UserMenuAction.darkLightMode:
        if (!mounted) return;
        ref.read(themeModeProvider.notifier).toggleDarkLight();
        break;

      case _UserMenuAction.logout:
        if (!mounted) return;
        SigningOutDialog.show(context);
        try {
          await ref.read(spotifyServiceProvider).disconnect();
        } catch (_) {}
        try {
          await ref.read(authServiceProvider).signOut();
        } catch (_) {}
        ref.read(chatServiceProvider).clearCache();
        ref.invalidate(musicProfileServiceProvider);
        if (!mounted) return;
        context.go('/auth');
        break;
    }
  }

  Widget _buildUserAvatar(String imageUrl) {
    return CircleAvatar(
      radius: 16,
      backgroundImage: imageUrl.trim().isNotEmpty
          ? CachedNetworkImageProvider(imageUrl)
          : null,
      
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(isDarkProvider);

    return FutureBuilder<AppUser?>(
      future: _userFuture,
      builder: (context, snapshot) {
        final firebaseUser = ref.read(firebaseAuthProvider).currentUser;
        final appUser = snapshot.data;
        final imageUrl = appUser?.photoUrl.isNotEmpty == true
            ? appUser!.photoUrl
            : (firebaseUser?.photoURL ?? '');

        return PopupMenuButton<_UserMenuAction>(
          tooltip: AppLocalizations.of(context)!.menuAccountOptions,
          splashRadius: 0,
          style: const ButtonStyle(splashFactory: NoSplash.splashFactory),
          popUpAnimationStyle: const AnimationStyle(
            duration: Duration(milliseconds: 150),
            curve: Curves.easeInOut,
          ),
          onSelected: _handleUserMenuAction,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _UserMenuAction.profile,
              child: _MenuRow(
                icon: const Icon(Icons.person_outline_rounded),
                label: AppLocalizations.of(context)!.menuProfile,
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: _UserMenuAction.darkLightMode,
              child: _MenuRow(
                icon: isDarkMode
                    ? const Icon(Icons.wb_sunny_outlined)
                    : const Icon(Icons.dark_mode_outlined),
                label: isDarkMode
                    ? AppLocalizations.of(context)!.menuLightMode
                    : AppLocalizations.of(context)!.menuDarkMode,
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: _UserMenuAction.logout,
              child: _MenuRow(
                icon: const Icon(Icons.logout_rounded),
                label: AppLocalizations.of(context)!.menuSignOut,
              ),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildUserAvatar(imageUrl),
          ),
        );
      },
    );
  }
}

class _MenuRow extends StatelessWidget {
  final Widget icon;
  final String label;

  const _MenuRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        IconTheme(
          data: IconThemeData(size: 20, color: cs.onSurfaceVariant),
          child: icon,
        ),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}
