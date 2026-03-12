import 'package:musi_link/core/models/app_user.dart';
import 'package:musi_link/core/user_service.dart';

/// Mixin que memoiza la carga de perfiles de usuario para evitar
/// reiniciar el FutureBuilder en cada build.
mixin UserFutureCache {
  final Map<String, Future<AppUser?>> userFutures = {};

  Future<AppUser?> getUserFuture(String uid) {
    if (uid.isEmpty) return Future.value(null);
    return userFutures.putIfAbsent(
      uid,
      () => UserService.instance.getUser(uid),
    );
  }

  void invalidateUserFuture(String uid) {
    userFutures.remove(uid);
  }
}
