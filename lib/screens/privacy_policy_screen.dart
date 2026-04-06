import 'package:flutter/material.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final sections = [
      (l10n.privacyS1Title, l10n.privacyS1Body),
      (l10n.privacyS2Title, l10n.privacyS2Body),
      (l10n.privacyS3Title, l10n.privacyS3Body),
      (l10n.privacyS4Title, l10n.privacyS4Body),
      (l10n.privacyS5Title, l10n.privacyS5Body),
      (l10n.privacyS6Title, l10n.privacyS6Body),
      (l10n.privacyS7Title, l10n.privacyS7Body),
      (l10n.privacyS8Title, l10n.privacyS8Body),
      (l10n.privacyS9Title, l10n.privacyS9Body),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceLG,
          vertical: AppTokens.spaceXL,
        ),
        children: [
          Text(
            l10n.privacyLastUpdated,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppTokens.spaceXL),
          for (final (title, body) in sections) ...[
            _PolicySection(title: title, body: body),
            const SizedBox(height: AppTokens.spaceLG),
          ],
          const SizedBox(height: AppTokens.spaceXL),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String body;

  const _PolicySection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppTokens.spaceSM),
        Text(
          body,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.6,
              ),
        ),
      ],
    );
  }
}
