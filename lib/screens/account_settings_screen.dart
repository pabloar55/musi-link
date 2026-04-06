import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/providers/firebase_providers.dart';
import 'package:musi_link/providers/service_providers.dart';
import 'package:musi_link/providers/theme_provider.dart';
import 'package:musi_link/providers/user_profile_provider.dart';
import 'package:musi_link/theme/app_theme.dart';
import 'package:musi_link/utils/error_reporter.dart';
import 'package:musi_link/widgets/signing_out_dialog.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState
    extends ConsumerState<AccountSettingsScreen> {
  Future<void> _goToProfile() async {
    final appUser = ref.read(currentUserProvider).asData?.value;
    if (appUser != null && mounted) {
      unawaited(context.push('/profile', extra: appUser));
    }
  }

  Future<void> _signOut() async {
    if (!mounted) return;
    SigningOutDialog.show(context);
    try {
      await ref.read(spotifyServiceProvider).disconnect();
    } catch (_) {}
    try {
      await ref.read(authServiceProvider).signOut();
    } catch (e, st) {
      reportError(e, st).ignore();
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.genericError),
        ),
      );
      return;
    }
    ref.read(chatServiceProvider).clearCache();
    ref.invalidate(musicProfileServiceProvider);
    if (!mounted) return;
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = ref.watch(isDarkProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: Builder(
        builder: (context) {
          final appUser = ref.watch(currentUserProvider).asData?.value;
          final firebaseUser = ref.read(firebaseAuthProvider).currentUser;
          final imageUrl = appUser?.photoUrl ?? '';
          final displayName = appUser?.displayName ?? l10n.socialUser;
          final email = firebaseUser?.email ?? '';

          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spaceLG,
              vertical: AppTokens.spaceXL,
            ),
            children: [
              // ── Profile header ─────────────────────────────────────
              _ProfileCard(
                imageUrl: imageUrl,
                displayName: displayName,
                email: email,
                uid: appUser?.uid ?? firebaseUser?.uid ?? '',
                onTap: _goToProfile,
              ),

              const SizedBox(height: AppTokens.spaceXL),

              // ── Appearance ─────────────────────────────────────────
              _SectionHeader(label: l10n.settingsAppearance),
              const SizedBox(height: AppTokens.spaceSM),
              _SettingsCard(
                children: [
                  _SwitchTile(
                    icon: LucideIcons.moon,
                    label: l10n.menuDarkMode,
                    value: isDarkMode,
                    onChanged: (_) =>
                        ref.read(themeModeProvider.notifier).toggleDarkLight(),
                  ),
                ],
              ),

              const SizedBox(height: AppTokens.spaceLG),

              // ── Legal ──────────────────────────────────────────────
              _SectionHeader(label: l10n.settingsLegal),
              const SizedBox(height: AppTokens.spaceSM),
              _SettingsCard(
                children: [
                  _ChevronTile(
                    icon: LucideIcons.shieldCheck,
                    label: l10n.settingsPrivacyPolicy,
                    onTap: () {
                      // TODO: open privacy policy URL
                    },
                  ),
                ],
              ),

              const SizedBox(height: AppTokens.space2XL),

              // ── Sign out ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(LucideIcons.logOut),
                  label: Text(l10n.menuSignOut),
                ),
              ),

              const SizedBox(height: AppTokens.spaceMD),

              // ── Delete account ─────────────────────────────────────
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    // TODO: implement delete account flow
                  },
                  icon: Icon(LucideIcons.trash2, size: 16, color: cs.error),
                  label: Text(
                    l10n.settingsDeleteAccount,
                    style: TextStyle(color: cs.error),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final String imageUrl;
  final String displayName;
  final String email;
  final String uid;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.imageUrl,
    required this.displayName,
    required this.email,
    required this.uid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusMD),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spaceLG),
          child: Row(
            children: [
              Hero(
                tag: 'user-avatar-$uid',
                child: CircleAvatar(
                  radius: 28,
                  backgroundImage: imageUrl.trim().isNotEmpty
                      ? CachedNetworkImageProvider(imageUrl)
                      : null,
                  backgroundColor: cs.surfaceContainerHighest,
                  child: imageUrl.trim().isEmpty
                      ? Icon(LucideIcons.user, color: cs.onSurfaceVariant)
                      : null,
                ),
              ),
              const SizedBox(width: AppTokens.spaceLG),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: AppTokens.spaceXS),
                      Text(
                        email,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                color: cs.onSurfaceVariant,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppTokens.spaceXS),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Divider(
                height: 1,
                indent: AppTokens.spaceLG + 22 + AppTokens.spaceMD,
              ),
          ],
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SwitchListTile(
      secondary: Icon(icon, size: 22, color: cs.onSurfaceVariant),
      title: Text(label),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceLG,
        vertical: AppTokens.spaceXS,
      ),
    );
  }
}

class _ChevronTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ChevronTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, size: 22, color: cs.onSurfaceVariant),
      title: Text(label),
      trailing: Icon(
        LucideIcons.chevronRight,
        size: 18,
        color: cs.onSurfaceVariant,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceLG,
        vertical: AppTokens.spaceXS,
      ),
    );
  }
}
