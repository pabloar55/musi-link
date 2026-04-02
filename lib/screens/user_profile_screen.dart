import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/models/app_user.dart';
import 'package:musi_link/models/discovery_result.dart';
import 'package:musi_link/providers/firebase_providers.dart';
import 'package:musi_link/providers/service_providers.dart';
import 'package:musi_link/providers/user_profile_provider.dart';
import 'package:musi_link/services/friend_service.dart';
import 'package:musi_link/widgets/profile/compatibility_card.dart';
import 'package:musi_link/widgets/profile/friendship_buttons.dart';
import 'package:musi_link/widgets/profile/music_taste_section.dart';
import 'package:musi_link/widgets/profile/now_playing_card.dart';
import 'package:musi_link/widgets/profile/profile_daily_song_card.dart';
import 'package:musi_link/widgets/profile/profile_header.dart';
import 'package:musi_link/widgets/remove_friend_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final AppUser user;

  const UserProfileScreen({super.key, required this.user});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  /// UID of the authenticated user from the Riverpod provider.
  /// Returns empty string on session loss — _isOwnProfile then evaluates to
  /// false (safe: shows the other-user view, actions are gated by GoRouter).
  String get _currentUid => ref.read(firebaseAuthProvider).currentUser?.uid ?? '';
  bool get _isOwnProfile => widget.user.uid == _currentUid && _currentUid.isNotEmpty;

  Future<void> _startChat() async {
    final chat =
        await ref.read(chatServiceProvider).getOrCreateChat(widget.user.uid);
    if (!mounted) return;
    unawaited(context.push(
      Uri(path: '/chat', queryParameters: {
        'chatId': chat.id,
        'otherUserName': widget.user.displayName,
        'otherUserId': widget.user.uid,
      }).toString(),
    ));
  }

  Future<void> _sendRequest() async {
    await ref.read(friendServiceProvider).sendRequest(widget.user.uid);
    if (!mounted) return;
    ref.invalidate(relationshipProvider(widget.user.uid));
  }

  Future<void> _acceptRequest(String requestId) async {
    await ref.read(friendServiceProvider).acceptRequest(requestId, widget.user.uid);
    if (!mounted) return;
    ref.invalidate(relationshipProvider(widget.user.uid));
  }

  Future<void> _rejectRequest(String requestId) async {
    await ref.read(friendServiceProvider).rejectRequest(requestId);
    if (!mounted) return;
    ref.invalidate(relationshipProvider(widget.user.uid));
  }

  Future<void> _cancelRequest(String requestId) async {
    await ref.read(friendServiceProvider).cancelRequest(requestId);
    if (!mounted) return;
    ref.invalidate(relationshipProvider(widget.user.uid));
  }

  Future<void> _removeFriend() async {
    final confirmed = await showRemoveFriendDialog(context);
    if (confirmed == true) {
      await ref.read(friendServiceProvider).removeFriend(widget.user.uid);
      if (!mounted) return;
      ref.invalidate(relationshipProvider(widget.user.uid));
    }
  }

  Future<void> _openSpotifyUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<DiscoveryResult> _compatibilityFutureFromAsync() {
    final compatibilityAsync = ref.watch(compatibilityProvider(widget.user));
    return compatibilityAsync.when(
      data: Future<DiscoveryResult>.value,
      loading: () => ref.read(compatibilityProvider(widget.user).future),
      error: (_, __) => ref.read(compatibilityProvider(widget.user).future),
    );
  }

  Future<RelationshipResult> _relationshipFutureFromAsync() {
    final relationshipAsync = ref.watch(relationshipProvider(widget.user.uid));
    return relationshipAsync.when(
      data: Future<RelationshipResult>.value,
      loading: () => ref.read(relationshipProvider(widget.user.uid).future),
      error: (_, __) => ref.read(relationshipProvider(widget.user.uid).future),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = widget.user;
    final hasMusicalData = user.topArtists.isNotEmpty || user.topGenres.isNotEmpty;
    final compatibilityFuture =
        _isOwnProfile ? null : _compatibilityFutureFromAsync();
    final relationshipFuture = _isOwnProfile ? null : _relationshipFutureFromAsync();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: 24,
          bottom: 24 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          children: [
            ProfileHeader(user: user),
            const SizedBox(height: 20),

            if (user.nowPlaying != null &&
                user.nowPlayingUpdatedAt != null &&
                DateTime.now().difference(user.nowPlayingUpdatedAt!).inMinutes < 10)
              NowPlayingCard(
                track: user.nowPlaying!,
                onTap: user.nowPlaying!.spotifyUrl.isNotEmpty
                    ? () => _openSpotifyUrl(user.nowPlaying!.spotifyUrl)
                    : null,
              ),

            if (user.dailySong != null)
              ProfileDailySongCard(
                song: user.dailySong!,
                onTap: user.dailySong!.spotifyUrl.isNotEmpty
                    ? () => _openSpotifyUrl(user.dailySong!.spotifyUrl)
                    : null,
              ),

            const SizedBox(height: 4),

            if (!_isOwnProfile) ...[
              CompatibilityCard(future: compatibilityFuture),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FriendshipButtons(
                  future: relationshipFuture,
                  onStartChat: _startChat,
                  onSendRequest: _sendRequest,
                  onAcceptRequest: _acceptRequest,
                  onRejectRequest: _rejectRequest,
                  onCancelRequest: _cancelRequest,
                  onRemoveFriend: _removeFriend,
                ),
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

            MusicTasteSection(user: user),
          ],
        ),
      ),
    );
  }
}
