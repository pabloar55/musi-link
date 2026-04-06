import 'package:flutter/material.dart';
import 'package:musi_link/l10n/app_localizations.dart';

/// Muestra un diálogo pidiendo la contraseña para re-autenticar al usuario
/// antes de eliminar su cuenta. Devuelve la contraseña introducida, o `null`
/// si el usuario cancela.
Future<String?> showReauthPasswordDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (context) {
      bool obscure = true;
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.reauthTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.reauthBody),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                obscureText: obscure,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.authPassword,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => obscure = !obscure),
                  ),
                ),
                onSubmitted: (v) =>
                    Navigator.of(context).pop(v.isEmpty ? null : v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(l10n.friendsCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context)
                  .pop(controller.text.isEmpty ? null : controller.text),
              child: Text(l10n.reauthConfirm),
            ),
          ],
        ),
      );
    },
  );
}
