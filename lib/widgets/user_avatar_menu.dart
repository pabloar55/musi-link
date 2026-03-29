import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/models/app_user.dart';
import 'package:musi_link/providers/providers.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
          context.push('/profile', extra: appUser);
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
          onSelected: _handleUserMenuAction,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _UserMenuAction.profile,
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(AppLocalizations.of(context)!.menuProfile),
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: _UserMenuAction.darkLightMode,
              child: ListTile(
                leading: Icon(
                  isDarkMode ? Icons.sunny : FontAwesomeIcons.solidMoon,
                ),
                title: Text(
                  isDarkMode ? AppLocalizations.of(context)!.menuLightMode : AppLocalizations.of(context)!.menuDarkMode,
                ),
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: _UserMenuAction.logout,
              child: ListTile(
                leading: const Icon(Icons.logout),
                title: Text(AppLocalizations.of(context)!.menuSignOut),
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
