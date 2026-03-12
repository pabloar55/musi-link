import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/components/artist_tile.dart';
import 'package:musi_link/components/genre_tile.dart';
import 'package:musi_link/core/chat_service.dart';
import 'package:musi_link/core/friend_service.dart';
import 'package:musi_link/core/models/app_user.dart';
import 'package:musi_link/core/models/discovery_result.dart';
import 'package:musi_link/core/models/track.dart';
import 'package:musi_link/core/music_profile_service.dart';
import 'package:musi_link/components/remove_friend_dialog.dart';
import 'package:musi_link/screens/chat_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class UserProfileScreen extends StatefulWidget {
  final AppUser user;

  const UserProfileScreen({super.key, required this.user});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late Future<DiscoveryResult> _compatibilityFuture;
  late Future<RelationshipResult> _relationshipFuture;
  Track? _dailySong;

  String get _currentUid => FirebaseAuth.instance.currentUser!.uid;
  bool get _isOwnProfile => widget.user.uid == _currentUid;

  @override
  void initState() {
    super.initState();
    _dailySong = widget.user.dailySong;
    if (!_isOwnProfile) {
      _compatibilityFuture =
          MusicProfileService.instance.getCompatibilityWith(widget.user);
      _relationshipFuture =
          FriendService.instance.getRelationship(widget.user.uid);
    }
  }

  void _refreshRelationship() {
    setState(() {
      _relationshipFuture =
          FriendService.instance.getRelationship(widget.user.uid);
    });
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

  Future<void> _sendRequest() async {
    await FriendService.instance.sendRequest(widget.user.uid);
    if (!mounted) return;
    _refreshRelationship();
  }

  Future<void> _acceptRequest(String requestId) async {
    await FriendService.instance.acceptRequest(requestId, widget.user.uid);
    if (!mounted) return;
    _refreshRelationship();
  }

  Future<void> _rejectRequest(String requestId) async {
    await FriendService.instance.rejectRequest(requestId);
    if (!mounted) return;
    _refreshRelationship();
  }

  Future<void> _cancelRequest(String requestId) async {
    await FriendService.instance.cancelRequest(requestId);
    if (!mounted) return;
    _refreshRelationship();
  }

  Future<void> _removeFriend() async {
    final confirmed = await showRemoveFriendDialog(context);
    if (confirmed == true) {
      await FriendService.instance.removeFriend(widget.user.uid);
      if (!mounted) return;
      _refreshRelationship();
    }
  }

  Future<void> _openSpotifyUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final user = widget.user;
    final hasMusicalData = user.topArtists.isNotEmpty || user.topGenres.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
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

            // Canción del día (solo mostrar, sin edición)
            if (_dailySong != null)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _dailySong!.spotifyUrl.isNotEmpty
                      ? () => _openSpotifyUrl(_dailySong!.spotifyUrl)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        if (_dailySong!.imageUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _dailySong!.imageUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.music_note, size: 28),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.dailySongTitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _dailySong!.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _dailySong!.artist,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.play_circle_fill,
                          color: colorScheme.primary,
                          size: 32,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 4),

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
                            l10n.profileCompatible,
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (result.sharedArtistNames.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              l10n.profileSharedArtists,
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
                              l10n.profileSharedGenres,
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

            // Botones de amistad / chat (solo si no es tu perfil)
            if (!_isOwnProfile) ...[
              const SizedBox(height: 16),
              FutureBuilder<RelationshipResult>(
                future: _relationshipFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 40,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final relationship = snapshot.data ??
                      const RelationshipResult(RelationshipStatus.none);

                  switch (relationship.status) {
                    case RelationshipStatus.friends:
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FilledButton.icon(
                            onPressed: _startChat,
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: Text(l10n.profileStartChat),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _removeFriend,
                            icon: Icon(Icons.person_remove,
                                color: colorScheme.error),
                            label: Text(
                              l10n.friendsRemove,
                              style: TextStyle(color: colorScheme.error),
                            ),
                          ),
                        ],
                      );

                    case RelationshipStatus.requestSent:
                      return OutlinedButton.icon(
                        onPressed: () {
                          if (relationship.requestId != null) {
                            _cancelRequest(relationship.requestId!);
                          }
                        },
                        icon: const Icon(Icons.hourglass_top),
                        label: Text(l10n.friendsRequestSent),
                      );

                    case RelationshipStatus.requestReceived:
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FilledButton.icon(
                            onPressed: () {
                              if (relationship.requestId != null) {
                                _acceptRequest(relationship.requestId!);
                              }
                            },
                            icon: const Icon(Icons.check),
                            label: Text(l10n.friendsAccept),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              if (relationship.requestId != null) {
                                _rejectRequest(relationship.requestId!);
                              }
                            },
                            icon: const Icon(Icons.close),
                            label: Text(l10n.friendsReject),
                          ),
                        ],
                      );

                    case RelationshipStatus.none:
                      return FilledButton.icon(
                        onPressed: _sendRequest,
                        icon: const Icon(Icons.person_add),
                        label: Text(l10n.profileAddFriend),
                      );
                  }
                },
              ),
            ],

            const SizedBox(height: 24),

            if (!hasMusicalData)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l10n.profileNoData,
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
                    l10n.profileTopArtists,
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
                    l10n.profileTopGenres,
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
