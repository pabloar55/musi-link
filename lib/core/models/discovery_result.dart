import 'package:musi_link/core/models/app_user.dart';

class DiscoveryResult {
  final AppUser user;
  final double score;
  final List<String> sharedArtistNames;
  final List<String> sharedGenreNames;

  const DiscoveryResult({
    required this.user,
    required this.score,
    required this.sharedArtistNames,
    required this.sharedGenreNames,
  });
}
