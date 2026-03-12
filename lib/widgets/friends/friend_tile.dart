import 'package:flutter/material.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/models/app_user.dart';
import 'package:musi_link/widgets/user_circle_avatar.dart';

class FriendTile extends StatelessWidget {
  final String uid;
  final Future<AppUser?> Function(String) getUserFuture;
  final void Function(AppUser?) onTap;
  final void Function(AppUser?) onLongPress;

  const FriendTile({
    super.key,
    required this.uid,
    required this.getUserFuture,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: getUserFuture(uid),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final isLoading = snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;
        final name = user?.displayName ??
            (isLoading
                ? AppLocalizations.of(context)!.socialLoading
                : AppLocalizations.of(context)!.socialUser);
        final photoUrl = user?.photoUrl ?? '';

        return ListTile(
          leading: UserCircleAvatar(
            photoUrl: photoUrl,
            name: name,
          ),
          title:
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          onTap: () => onTap(user),
          onLongPress: () => onLongPress(user),
        );
      },
    );
  }
}
