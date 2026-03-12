import 'package:flutter/material.dart';

/// CircleAvatar del usuario con imagen + fallback de letra inicial.
class UserCircleAvatar extends StatelessWidget {
  final String photoUrl;
  final String name;
  final double radius;

  const UserCircleAvatar({
    super.key,
    required this.photoUrl,
    required this.name,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPhoto = photoUrl.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
      child: hasPhoto
          ? null
          : Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
