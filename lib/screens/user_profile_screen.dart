import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:musi_link/components/artist_tile.dart';
import 'package:musi_link/components/genre_tile.dart';
import 'package:musi_link/core/chat_service.dart';
import 'package:musi_link/core/models/app_user.dart';
import 'package:musi_link/core/models/discovery_result.dart';
import 'package:musi_link/core/music_profile_service.dart';
import 'package:musi_link/screens/chat_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final AppUser user;

  const UserProfileScreen({super.key, required this.user});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late Future<DiscoveryResult> _compatibilityFuture;

  String get _currentUid => FirebaseAuth.instance.currentUser!.uid;
  bool get _isOwnProfile => widget.user.uid == _currentUid;

  @override
  void initState() {
    super.initState();
    if (!_isOwnProfile) {
      _compatibilityFuture =
          MusicProfileService.instance.getCompatibilityWith(widget.user);
    }
  }

  Future<void> _startChat() async {
    final chat =
        await ChatService.instance.getOrCreateChat(widget.user.uid);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chat.id,
          otherUserName: widget.user.displayName,
          otherUserId: widget.user.uid,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = widget.user;
    final hasMusicalData = user.topArtists.isNotEmpty || user.topGenres.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil musical')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            // Avatar y nombre
            CircleAvatar(
              radius: 40,
              backgroundImage: user.photoUrl.isNotEmpty
                  ? NetworkImage(user.photoUrl)
                  : null,
              child: user.photoUrl.isEmpty
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              user.displayName,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Card de compatibilidad (solo si no es tu perfil)
            if (!_isOwnProfile)
              FutureBuilder<DiscoveryResult>(
                future: _compatibilityFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    );
                  }

                  final result = snapshot.data;
                  if (result == null) return const SizedBox.shrink();

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 24),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            '${result.score.round()}%',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'compatible',
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (result.sharedArtistNames.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Artistas en comun',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              result.sharedArtistNames.join(', '),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                          if (result.sharedGenreNames.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Generos en comun',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              result.sharedGenreNames.join(', '),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),

            // Boton de chat (solo si no es tu perfil)
            if (!_isOwnProfile) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _startChat,
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Iniciar chat'),
              ),
            ],

            const SizedBox(height: 24),

            if (!hasMusicalData)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Este usuario aun no tiene datos musicales',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

            // Top Artistas
            if (user.topArtists.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Top Artistas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...user.topArtists.map((artist) => ArtistTile(artist: artist)),
            ],

            // Top Generos
            if (user.topGenres.isNotEmpty) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Top Generos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...user.topGenres.asMap().entries.map(
                    (entry) =>
                        GenreTile(genre: entry.value, rank: entry.key + 1),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
