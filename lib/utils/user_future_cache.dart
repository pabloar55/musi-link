import 'package:musi_link/models/app_user.dart';
import 'package:musi_link/services/user_service.dart';

/// Mixin que memoiza la carga de perfiles de usuario para evitar
/// reiniciar el FutureBuilder en cada build.
mixin UserFutureCache {
  final Map<String, Future<AppUser?>> userFutures = {};

  /// Las clases que usen este mixin deben implementar este getter
  /// para proporcionar la instancia de UserService vía Riverpod.
  UserService get userService;

  Future<AppUser?> getUserFuture(String uid) {
    if (uid.isEmpty) return Future.value();
    return userFutures.putIfAbsent(uid, () => userService.getUser(uid));
  }

  void invalidateUserFuture(String uid) {
    userFutures.remove(uid);
  }
}
