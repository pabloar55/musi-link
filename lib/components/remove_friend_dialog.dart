import 'package:flutter/material.dart';
import 'package:musi_link/l10n/app_localizations.dart';

/// Muestra un diálogo de confirmación para eliminar un amigo.
/// Devuelve `true` si el usuario confirma, `false` o `null` si cancela.
Future<bool?> showRemoveFriendDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.friendsRemove),
      content: Text(l10n.friendsRemoveBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.friendsCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            l10n.friendsRemove,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    ),
  );
}
