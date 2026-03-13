import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/services/auth_service.dart';
import 'package:musi_link/models/app_user.dart';
import 'package:musi_link/services/spotify_service.dart';
import 'package:musi_link/theme/theme_mode_controller.dart';
import 'package:musi_link/services/user_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:musi_link/screens/user_profile_screen.dart';

enum _UserMenuAction { profile, darkLightMode, logout }

class UserAvatarMenu extends StatefulWidget {
  const UserAvatarMenu({super.key});

  @override
  State<UserAvatarMenu> createState() => _UserAvatarMenuState();
}

class _UserAvatarMenuState extends State<UserAvatarMenu> {
  Future<AppUser?>? _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _getCurrentAppUser();
  }

  Future<AppUser?> _getCurrentAppUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return null;
    return UserService.instance.getUser(firebaseUser.uid);
  }

  Future<void> _handleUserMenuAction(_UserMenuAction action) async {
    switch (action) {
      case _UserMenuAction.profile:
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser == null) return;
        final appUser = await UserService.instance.getUser(firebaseUser.uid);
        if (appUser != null && mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => UserProfileScreen(user: appUser),
            ),
          );
        }
        break;

      case _UserMenuAction.darkLightMode:
        if (!mounted) return;
        ThemeModeController.instance.toggleDarkLight();
        break;

      case _UserMenuAction.logout:
        await SpotifyService.instance.disconnect();
        await AuthService.instance.signOut();
        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
        break;
    }
  }

  Widget _buildUserAvatar(String imageUrl) {
    return CircleAvatar(
      radius: 16,
      backgroundImage: imageUrl.trim().isNotEmpty
          ? NetworkImage(imageUrl)
          : null,
      
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeModeController.instance,
      builder: (context, themeMode, _) {
        final isDarkMode = ThemeModeController.instance.isDark;

        return FutureBuilder<AppUser?>(
          future: _userFuture,
          builder: (context, snapshot) {
            final firebaseUser = FirebaseAuth.instance.currentUser;
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
      },
    );
  }
}
