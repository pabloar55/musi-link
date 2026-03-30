import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:musi_link/models/app_user.dart';

class ProfileHeader extends StatelessWidget {
  final AppUser user;

  const ProfileHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: user.photoUrl.isNotEmpty
              ? CachedNetworkImageProvider(user.photoUrl)
              : null,
          child: user.photoUrl.isEmpty
              ? const Icon(Icons.person, size: 40)
              : null,
        ),
        const SizedBox(height: 12),
        Text(
          user.displayName,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
