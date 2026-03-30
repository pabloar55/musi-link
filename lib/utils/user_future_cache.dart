import 'package:musi_link/models/app_user.dart';
import 'package:musi_link/services/user_service.dart';

class _CachedUser {
  final AppUser? user;
  final DateTime _cachedAt;

  _CachedUser(this.user) : _cachedAt = DateTime.now();

  bool isExpired(Duration ttl) => DateTime.now().difference(_cachedAt) > ttl;
}

/// Mixin que memoiza la carga de perfiles de usuario para evitar
/// reiniciar el FutureBuilder en cada build.
///
/// Cachea el valor resuelto (no el Future) con un TTL de [cacheTtl].
/// Pasado ese tiempo, o tras llamar a [invalidateUserFuture], se hace
/// una nueva petición a Firestore.
mixin UserFutureCache {
  final Map<String, _CachedUser> _userCache = {};

  /// TTL del caché. Sobreescribir para ajustar por pantalla.
  Duration get cacheTtl => const Duration(minutes: 5);

  /// Las clases que usen este mixin deben implementar este getter
  /// para proporcionar la instancia de UserService vía Riverpod.
  UserService get userService;

  Future<AppUser?> getUserFuture(String uid) {
    if (uid.isEmpty) return Future.value();

    final cached = _userCache[uid];
    if (cached != null && !cached.isExpired(cacheTtl)) {
      return Future.value(cached.user);
    }

    return userService.getUser(uid).then((user) {
      _userCache[uid] = _CachedUser(user);
      return user;
    });
  }

  void invalidateUserFuture(String uid) {
    _userCache.remove(uid);
  }
}
