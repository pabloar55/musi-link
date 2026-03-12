// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get authName => 'Nombre';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Contraseña';

  @override
  String get authEnterName => 'Introduce tu nombre';

  @override
  String get authEnterEmail => 'Introduce tu email';

  @override
  String get authInvalidEmail => 'Email no válido';

  @override
  String get authEnterPassword => 'Introduce tu contraseña';

  @override
  String get authMinChars => 'Mínimo 6 caracteres';

  @override
  String get authErrorEmailInUse => 'Este email ya está registrado.';

  @override
  String get authErrorInvalidEmail => 'Email no válido.';

  @override
  String get authErrorWeakPassword =>
      'La contraseña debe tener al menos 6 caracteres.';

  @override
  String get authErrorUserNotFound => 'No existe una cuenta con este email.';

  @override
  String get authErrorWrongPassword => 'Contraseña incorrecta.';

  @override
  String get authErrorInvalidCredential => 'Credenciales incorrectas.';

  @override
  String get authErrorTooManyRequests =>
      'Demasiados intentos. Espera un momento.';

  @override
  String authErrorGeneric(String code) {
    return 'Error de autenticación ($code).';
  }

  @override
  String get authSignIn => 'Iniciar sesión';

  @override
  String get authCreateAccount => 'Crear cuenta';

  @override
  String get authOr => 'o';

  @override
  String get authContinueGoogle => 'Continuar con Google';

  @override
  String get authNoAccount => '¿No tienes cuenta?';

  @override
  String get authHaveAccount => '¿Ya tienes cuenta?';

  @override
  String get authRegister => 'Regístrate';

  @override
  String get authLogin => 'Inicia sesión';

  @override
  String get authErrorCouldNotAuth =>
      'No se pudo autenticar. Inténtalo de nuevo.';

  @override
  String get authErrorUnexpected => 'Error inesperado. Inténtalo de nuevo.';

  @override
  String get authErrorGoogleSignIn => 'No se pudo iniciar sesión con Google.';

  @override
  String get authErrorGoogleSignInGeneric =>
      'Error al iniciar sesión con Google.';

  @override
  String get discoverTitle => 'Descubrir personas';

  @override
  String get discoverErrorLoading => 'Error al cargar descubrimiento';

  @override
  String get discoverNoUsers => 'No hay usuarios con datos musicales';

  @override
  String get discoverNoUsersHint =>
      'Cuando más usuarios conecten su Spotify, aparecerán aquí';

  @override
  String get navDiscover => 'Descubrir';

  @override
  String get navStats => 'Estadísticas';

  @override
  String get navMessages => 'Mensajes';

  @override
  String get navFriends => 'Amigos';

  @override
  String get searchTitle => 'Buscar usuarios';

  @override
  String get searchHint => 'Nombre de usuario...';

  @override
  String get searchNoResults => 'No se encontraron usuarios';

  @override
  String get searchTypeToSearch => 'Escribe un nombre para buscar';

  @override
  String get searchSpotifyConnected => 'Spotify conectado';

  @override
  String get profileTitle => 'Perfil musical';

  @override
  String get profileStartChat => 'Iniciar chat';

  @override
  String get profileNoData => 'Este usuario aún no tiene datos musicales';

  @override
  String get profileTopArtists => 'Top Artistas';

  @override
  String get profileTopGenres => 'Top Géneros';

  @override
  String get profileCompatible => 'compatible';

  @override
  String get profileSharedArtists => 'Artistas en común';

  @override
  String get profileSharedGenres => 'Géneros en común';

  @override
  String get chatWriteMessage => 'Escribe un mensaje...';

  @override
  String get chatSearchSpotify => 'Buscar canción en Spotify...';

  @override
  String get chatShareSong => 'Compartir canción';

  @override
  String get chatSendFirst => 'Envía el primer mensaje';

  @override
  String get chatTypeToSearch => 'Escribe para buscar canciones';

  @override
  String get chatNoResults => 'Sin resultados';

  @override
  String get statsTracks => 'Canciones';

  @override
  String get statsArtists => 'Artistas';

  @override
  String get statsGenres => 'Géneros';

  @override
  String get statsShortTerm => '4 semanas';

  @override
  String get statsMediumTerm => '6 meses';

  @override
  String get statsLongTerm => '1 año';

  @override
  String statsError(String error) {
    return 'Error: $error';
  }

  @override
  String get statsNoData => 'No hay datos disponibles';

  @override
  String get socialNow => 'Ahora';

  @override
  String socialMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String socialDays(int days) {
    return '${days}d';
  }

  @override
  String get socialNoChats => 'No tienes conversaciones aún';

  @override
  String get socialNoChatsHint => 'Busca usuarios para empezar a chatear';

  @override
  String get socialErrorLoading => 'Error al cargar conversaciones';

  @override
  String get socialLoading => 'Cargando...';

  @override
  String get socialUser => 'Usuario';

  @override
  String get spotifyConnectTitle => 'Conecta tu Spotify';

  @override
  String get spotifyConnectDescription =>
      'Para ver tus estadísticas musicales necesitamos acceso a tu cuenta de Spotify.';

  @override
  String get spotifyConnectButton => 'Conectar Spotify';

  @override
  String get spotifyConnectError => 'Error al conectar con Spotify';

  @override
  String get menuAccountOptions => 'Opciones de cuenta';

  @override
  String get menuLightMode => 'Modo claro';

  @override
  String get menuDarkMode => 'Modo oscuro';

  @override
  String get menuSignOut => 'Cerrar sesión';

  @override
  String discoverySharedArtists(String artists) {
    return 'Artistas en común: $artists';
  }

  @override
  String discoverySharedGenres(String genres) {
    return 'Géneros en común: $genres';
  }

  @override
  String discoveryCompatible(String score) {
    return '$score% compatible';
  }

  @override
  String get friendsReceivedRequests => 'Solicitudes recibidas';

  @override
  String get friendsSentRequests => 'Solicitudes enviadas';

  @override
  String get friendsMyFriends => 'Mis amigos';

  @override
  String get friendsAccept => 'Aceptar';

  @override
  String get friendsReject => 'Rechazar';

  @override
  String get friendsCancel => 'Cancelar';

  @override
  String get friendsSendRequest => 'Enviar solicitud';

  @override
  String get friendsRequestSent => 'Solicitud enviada';

  @override
  String get friendsNoRequests => 'No hay solicitudes pendientes';

  @override
  String get friendsNoFriends => 'Aún no tienes amigos';

  @override
  String get friendsNoFriendsHint => 'Busca usuarios para añadir amigos';

  @override
  String get friendsRemove => 'Eliminar amigo';

  @override
  String get friendsRemoveBody =>
      'Esta persona será eliminada de tu lista de amigos.';

  @override
  String get friendsAlreadyFriends => 'Ya son amigos';

  @override
  String get profileAddFriend => 'Añadir amigo';

  @override
  String get dailySongTitle => 'Canción del día';

  @override
  String get dailySongChoose => 'Elegir canción del día';

  @override
  String dailySongBy(String artist) {
    return 'de $artist';
  }

  @override
  String get discoverTabPeople => 'Descubrir personas';

  @override
  String get discoverTabDailySong => 'Canción diaria';

  @override
  String get dailySongNone => 'Aún no has elegido una canción del día';

  @override
  String get dailySongNoneHint => 'Comparte con los demás lo que escuchas hoy';

  @override
  String get dailySongFriendsTitle => 'Canciones de tus amigos';

  @override
  String get dailySongFriendsNone =>
      'Tus amigos aún no han elegido una canción del día';

  @override
  String get dailySongNoFriends =>
      'Añade amigos para ver sus canciones del día';
}
