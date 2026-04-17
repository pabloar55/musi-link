/// Nombres de las colecciones (y subcolecciones) de Firestore.
///
/// Usar estas constantes en lugar de literales de cadena elimina el riesgo
/// de typos silenciosos que no se detectan en compilación ni en runtime
/// hasta que una operación falla.
abstract final class FirestoreCollections {
  static const String users = 'users';
  static const String chats = 'chats';
  static const String messages = 'messages';
  static const String friendRequests = 'friend_requests';
  static const String spotifyLinks = 'spotify_links';
}
