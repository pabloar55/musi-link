import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:musi_link/models/artist.dart';
import 'package:musi_link/models/genre.dart';
import 'package:musi_link/models/track.dart';

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final String? spotifyId;
  final DateTime createdAt;
  final DateTime lastLogin;
  final List<Artist> topArtists;
  final List<Genre> topGenres;
  final List<String> topArtistNames;
  final List<String> topGenreNames;
  final DateTime? musicDataUpdatedAt;
  final List<String> friends;
  final Track? dailySong;
  final DateTime? dailySongUpdatedAt;
  final Track? nowPlaying;
  final DateTime? nowPlayingUpdatedAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl = '',
    this.spotifyId,
    required this.createdAt,
    required this.lastLogin,
    this.topArtists = const [],
    this.topGenres = const [],
    this.topArtistNames = const [],
    this.topGenreNames = const [],
    this.musicDataUpdatedAt,
    this.friends = const [],
    this.dailySong,
    this.dailySongUpdatedAt,
    this.nowPlaying,
    this.nowPlayingUpdatedAt,
  });

  static AppUser? fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return null;
    return AppUser(
      uid: doc.id,
      email: (data['email'] ?? '').toString(),
      displayName: (data['displayName'] ?? '').toString(),
      photoUrl: (data['photoUrl'] ?? '').toString(),
      spotifyId: data['spotifyId']?.toString(),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin:
          (data['lastLogin'] as Timestamp?)?.toDate() ?? DateTime.now(),
      topArtists: (data['topArtists'] as List<dynamic>?)
              ?.map((e) => Artist.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      topGenres: (data['topGenres'] as List<dynamic>?)
              ?.map((e) => Genre.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      topArtistNames: (data['topArtistNames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      topGenreNames: (data['topGenreNames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      musicDataUpdatedAt:
          (data['musicDataUpdatedAt'] as Timestamp?)?.toDate(),
      friends: (data['friends'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      dailySong: data['dailySong'] != null
          ? Track.fromMap(data['dailySong'] as Map<String, dynamic>)
          : null,
      dailySongUpdatedAt:
          (data['dailySongUpdatedAt'] as Timestamp?)?.toDate(),
      nowPlaying: data['nowPlaying'] != null
          ? Track.fromMap(data['nowPlaying'] as Map<String, dynamic>)
          : null,
      nowPlayingUpdatedAt:
          (data['nowPlayingUpdatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'displayNameLower': displayName.toLowerCase(),
      'photoUrl': photoUrl,
      'spotifyId': spotifyId,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
    };
  }

  static const _unset = Object();

  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    String? spotifyId,
    DateTime? lastLogin,
    List<Artist>? topArtists,
    List<Genre>? topGenres,
    List<String>? topArtistNames,
    List<String>? topGenreNames,
    DateTime? musicDataUpdatedAt,
    List<String>? friends,
    Object? dailySong = _unset,
    DateTime? dailySongUpdatedAt,
    Object? nowPlaying = _unset,
    DateTime? nowPlayingUpdatedAt,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      spotifyId: spotifyId ?? this.spotifyId,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      topArtists: topArtists ?? this.topArtists,
      topGenres: topGenres ?? this.topGenres,
      topArtistNames: topArtistNames ?? this.topArtistNames,
      topGenreNames: topGenreNames ?? this.topGenreNames,
      musicDataUpdatedAt: musicDataUpdatedAt ?? this.musicDataUpdatedAt,
      friends: friends ?? this.friends,
      dailySong: identical(dailySong, _unset) ? this.dailySong : dailySong as Track?,
      dailySongUpdatedAt: dailySongUpdatedAt ?? this.dailySongUpdatedAt,
      nowPlaying: identical(nowPlaying, _unset) ? this.nowPlaying : nowPlaying as Track?,
      nowPlayingUpdatedAt: nowPlayingUpdatedAt ?? this.nowPlayingUpdatedAt,
    );
  }
}
