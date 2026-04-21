import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/providers/firebase_providers.dart';
import 'package:musi_link/providers/service_providers.dart';
import 'package:musi_link/router/go_router_provider.dart';

class PhotoSetupScreen extends ConsumerStatefulWidget {
  const PhotoSetupScreen({super.key});

  static const String photoSetupDoneKey = 'photo_setup_done';

  @override
  ConsumerState<PhotoSetupScreen> createState() => _PhotoSetupScreenState();
}

class _PhotoSetupScreenState extends ConsumerState<PhotoSetupScreen> {
  XFile? _selectedImage;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(LucideIcons.image, color: colorScheme.onSurface),
                title: Text(l10n.photoSetupGallery),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading:
                    Icon(LucideIcons.camera, color: colorScheme.onSurface),
                title: Text(l10n.photoSetupCamera),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image != null && mounted) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _completeSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PhotoSetupScreen.photoSetupDoneKey, true);
    if (!mounted) return;
    ref.read(appRouterNotifierProvider).setPhotoSetupDone();
  }

  Future<void> _handleContinue() async {
    if (_selectedImage == null) {
      await _completeSetup();
      return;
    }

    setState(() => _isUploading = true);

    try {
      final uid = ref.read(firebaseAuthProvider).currentUser!.uid;
      final url = await ref
          .read(storageServiceProvider)
          .uploadProfilePhoto(uid, _selectedImage!);
      if (url != null) {
        await ref
            .read(userServiceProvider)
            .updateProfile(uid, photoUrl: url);
      }
      if (!mounted) return;
      await _completeSetup();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.photoSetupError),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final hasPhoto = _selectedImage != null;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Avatar
              GestureDetector(
                onTap: _isUploading ? null : _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.surfaceContainerHighest,
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: ClipOval(
                        child: hasPhoto
                            ? Image.file(
                                File(_selectedImage!.path),
                                fit: BoxFit.cover,
                              )
                            : Icon(
                                LucideIcons.user,
                                size: 52,
                                color: colorScheme.onSurfaceVariant,
                              ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        LucideIcons.camera,
                        size: 14,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                l10n.photoSetupTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Subtitle
              Text(
                l10n.photoSetupSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 2),

              // Primary button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isUploading ? null : _handleContinue,
                  child: _isUploading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Text(
                          hasPhoto
                              ? l10n.photoSetupContinue
                              : l10n.photoSetupSkip,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // Choose / change photo link
              TextButton(
                onPressed: _isUploading ? null : _pickImage,
                child: Text(
                  hasPhoto ? l10n.photoSetupChange : l10n.photoSetupChoose,
                  style: TextStyle(color: colorScheme.primary),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
