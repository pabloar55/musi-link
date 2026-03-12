import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/components/user_discovery_card.dart';
import 'package:musi_link/core/models/app_user.dart';
import 'package:musi_link/core/models/discovery_result.dart';
import 'package:musi_link/core/models/track.dart';
import 'package:musi_link/core/music_profile_service.dart';
import 'package:musi_link/core/spotify_get_stats.dart';
import 'package:musi_link/core/user_service.dart';
import 'package:musi_link/screens/user_profile_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with AutomaticKeepAliveClientMixin<DiscoverScreen>, TickerProviderStateMixin {
  late Future<List<DiscoveryResult>> _discoveryFuture;
  late TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDiscovery();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadDiscovery() {
    _discoveryFuture = MusicProfileService.instance.getDiscoveryUsers();
  }

  Future<void> _refresh() async {
    setState(() {
      _loadDiscovery();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        TabBar(
          splashFactory: NoSplash.splashFactory,
          dividerColor: Colors.transparent,
          controller: _tabController,
          tabs: [
            Tab(text: l10n.discoverTabPeople),
            Tab(text: l10n.discoverTabDailySong),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _PeopleTab(
                discoveryFuture: _discoveryFuture,
                onRefresh: _refresh,
              ),
              const _DailySongTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── People tab (existing discover content) ───

class _PeopleTab extends StatelessWidget {
  final Future<List<DiscoveryResult>> discoveryFuture;
  final Future<void> Function() onRefresh;

  const _PeopleTab({required this.discoveryFuture, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<List<DiscoveryResult>>(
      future: discoveryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              l10n.discoverErrorLoading,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          );
        }

        final results = snapshot.data ?? [];

        if (results.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.explore_off,
                    size: 64,
                    color: colorScheme.onSurfaceVariant.withAlpha(128),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.discoverNoUsers,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.discoverNoUsersHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant.withAlpha(180),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return UserDiscoveryCard(
                result: result,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => UserProfileScreen(user: result.user),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

// ─── Daily Song tab ───

class _DailySongTab extends StatefulWidget {
  const _DailySongTab();

  @override
  State<_DailySongTab> createState() => _DailySongTabState();
}

class _DailySongTabState extends State<_DailySongTab>
    with AutomaticKeepAliveClientMixin<_DailySongTab> {
  Track? _dailySong;
  bool _loading = true;
  List<AppUser> _friendsWithSongs = [];
  List<String> _friendIds = [];

  String get _currentUid => FirebaseAuth.instance.currentUser!.uid;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await UserService.instance.getUser(_currentUid);
    if (!mounted) return;

    final friendIds = user?.friends ?? [];
    List<AppUser> friendsWithSongs = [];

    if (friendIds.isNotEmpty) {
      final friends = await UserService.instance.getUsersByIds(friendIds);
      friendsWithSongs =
          friends.where((f) => f.dailySong != null).toList();
    }

    setState(() {
      _dailySong = user?.dailySong;
      _friendIds = friendIds;
      _friendsWithSongs = friendsWithSongs;
      _loading = false;
    });
  }

  Future<void> _chooseDailySong() async {
    final track = await showModalBottomSheet<Track>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DailySongSearchSheet(),
    );
    if (track == null || !mounted) return;
    await UserService.instance.setDailySong(_currentUid, track);
    if (!mounted) return;
    setState(() => _dailySong = track);
  }

  Future<void> _openSpotifyUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _loading = true);
        await _loadData();
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // ─── Mi canción del día ───
          Text(
            l10n.dailySongTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          if (_dailySong != null) ...[
            _DailySongCard(
              song: _dailySong!,
              onTap: _dailySong!.spotifyUrl.isNotEmpty
                  ? () => _openSpotifyUrl(_dailySong!.spotifyUrl)
                  : null,
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _chooseDailySong,
                icon: const Icon(Icons.edit, size: 18),
                label: Text(l10n.dailySongChoose),
              ),
            ),
          ] else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.music_note,
                      size: 48,
                      color: colorScheme.onSurfaceVariant.withAlpha(128),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.dailySongNone,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.dailySongNoneHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant.withAlpha(180),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _chooseDailySong,
                      icon: const Icon(Icons.music_note),
                      label: Text(l10n.dailySongChoose),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ─── Canciones de amigos ───
          const SizedBox(height: 24),
          Text(
            l10n.dailySongFriendsTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          if (_friendIds.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    l10n.dailySongNoFriends,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            )
          else if (_friendsWithSongs.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    l10n.dailySongFriendsNone,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            )
          else
            ...List.generate(_friendsWithSongs.length, (index) {
              final friend = _friendsWithSongs[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _FriendDailySongCard(
                  friend: friend,
                  onTapSong: friend.dailySong!.spotifyUrl.isNotEmpty
                      ? () => _openSpotifyUrl(friend.dailySong!.spotifyUrl)
                      : null,
                  onTapProfile: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => UserProfileScreen(user: friend),
                      ),
                    );
                  },
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ─── Daily Song card (reutilizable) ───

class _DailySongCard extends StatelessWidget {
  final Track song;
  final VoidCallback? onTap;

  const _DailySongCard({required this.song, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (song.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    song.imageUrl,
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
                      song.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      song.artist,
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
    );
  }
}

// ─── Friend daily song card ───

class _FriendDailySongCard extends StatelessWidget {
  final AppUser friend;
  final VoidCallback? onTapSong;
  final VoidCallback? onTapProfile;

  const _FriendDailySongCard({
    required this.friend,
    this.onTapSong,
    this.onTapProfile,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final song = friend.dailySong!;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTapSong,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar del amigo
              GestureDetector(
                onTap: onTapProfile,
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: friend.photoUrl.isNotEmpty
                      ? NetworkImage(friend.photoUrl)
                      : null,
                  child: friend.photoUrl.isEmpty
                      ? Text(
                          friend.displayName.isNotEmpty
                              ? friend.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              // Imagen de la canción
              if (song.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    song.imageUrl,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.music_note, size: 22),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      song.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      song.artist,
                      style: TextStyle(
                        fontSize: 12,
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
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Daily Song search sheet ───

class _DailySongSearchSheet extends StatefulWidget {
  @override
  State<_DailySongSearchSheet> createState() => _DailySongSearchSheetState();
}

class _DailySongSearchSheetState extends State<_DailySongSearchSheet> {
  final _searchController = TextEditingController();
  List<Track> _results = [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _loading = true);
    final results = await SpotifyGetStats.instance.searchTracks(query);
    if (mounted) {
      setState(() {
        _results = results;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withAlpha(60),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.chatSearchSpotify,
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.isEmpty
                                ? l10n.chatTypeToSearch
                                : l10n.chatNoResults,
                            style: TextStyle(
                              color: colorScheme.onSurface.withAlpha(120),
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final track = _results[index];
                            return ListTile(
                              leading: track.imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.network(
                                        track.imageUrl,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(Icons.music_note, size: 40),
                              title: Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                track.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => Navigator.of(context).pop(track),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}
