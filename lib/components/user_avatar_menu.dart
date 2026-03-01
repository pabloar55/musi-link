import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:musi_link/core/auth_service.dart';
import 'package:musi_link/core/models/app_user.dart';
import 'package:musi_link/core/spotify_service.dart';
import 'package:musi_link/core/theme/theme_mode_controller.dart';
import 'package:musi_link/core/user_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
enum _UserMenuAction { darkLightMode, logout }

class UserAvatarMenu extends StatefulWidget {
  const UserAvatarMenu({super.key});

  @override
  State<UserAvatarMenu> createState() => _UserAvatarMenuState();
}

class _UserAvatarMenuState extends State<UserAvatarMenu> {
  Future<AppUser?> _getCurrentAppUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return null;
    return UserService.instance.getUser(firebaseUser.uid);
  }

  Future<void> _handleUserMenuAction(_UserMenuAction action) async {
    switch (action) {
      case _UserMenuAction.darkLightMode:
        if (!mounted) return;
        ThemeModeController.instance.toggleDarkLight();
        break;

      case _UserMenuAction.logout:
        await SpotifyService.instance.disconnect();
        await AuthService.instance.signOut();
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
        final isDarkMode = themeMode == ThemeMode.dark;

        return FutureBuilder<AppUser?>(
          future: _getCurrentAppUser(),
          builder: (context, snapshot) {
            final firebaseUser = FirebaseAuth.instance.currentUser;
            final appUser = snapshot.data;
            final imageUrl = appUser?.photoUrl.isNotEmpty == true
                ? appUser!.photoUrl
                : (firebaseUser?.photoURL ?? '');

            return PopupMenuButton<_UserMenuAction>(
              tooltip: 'Opciones de cuenta',
              onSelected: _handleUserMenuAction,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _UserMenuAction.darkLightMode,
                  child: ListTile(
                    leading: Icon(
                      isDarkMode ? Icons.sunny : FontAwesomeIcons.solidMoon,
                    ),
                    title: Text(
                      isDarkMode ? 'Modo claro' : 'Modo oscuro',
                    ),
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: _UserMenuAction.logout,
                  child: ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('Cerrar sesión'),
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
