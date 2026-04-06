import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/models/app_user.dart';
import 'package:musi_link/providers/firebase_providers.dart';
import 'package:musi_link/providers/service_providers.dart';
import 'package:musi_link/theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<AppUser?>(
      future: _userFuture,
      builder: (context, snapshot) {
        final firebaseUser = ref.read(firebaseAuthProvider).currentUser;
        final appUser = snapshot.data;
        final imageUrl = appUser?.photoUrl.isNotEmpty == true
            ? appUser!.photoUrl
            : (firebaseUser?.photoURL ?? '');

        return Tooltip(
          message: l10n.menuAccountOptions,
          child: InkWell(
            onTap: () => context.push('/settings'),
            borderRadius: BorderRadius.circular(AppTokens.radiusFull),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundImage: imageUrl.trim().isNotEmpty
                    ? CachedNetworkImageProvider(imageUrl)
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}
