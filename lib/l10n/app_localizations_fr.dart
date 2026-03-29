// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get authName => 'Nom';

  @override
  String get authEmail => 'E-mail';

  @override
  String get authPassword => 'Mot de passe';

  @override
  String get authEnterName => 'Entrez votre nom';

  @override
  String get authEnterEmail => 'Entrez votre e-mail';

  @override
  String get authInvalidEmail => 'E-mail invalide';

  @override
  String get authEnterPassword => 'Entrez votre mot de passe';

  @override
  String get authMinChars => '6 caractères minimum';

  @override
  String get authErrorEmailInUse => 'Cet e-mail est déjà enregistré.';

  @override
  String get authErrorInvalidEmail => 'E-mail invalide.';

  @override
  String get authErrorWeakPassword =>
      'Le mot de passe doit contenir au moins 6 caractères.';

  @override
  String get authErrorUserNotFound => 'Aucun compte trouvé avec cet e-mail.';

  @override
  String get authErrorWrongPassword => 'Mot de passe incorrect.';

  @override
  String get authErrorInvalidCredential => 'Identifiants invalides.';

  @override
  String get authErrorTooManyRequests =>
      'Trop de tentatives. Veuillez patienter.';

  @override
  String authErrorGeneric(String code) {
    return 'Erreur d\'authentification ($code).';
  }

  @override
  String get authSignIn => 'Se connecter';

  @override
  String get authCreateAccount => 'Créer un compte';

  @override
  String get authOr => 'ou';

  @override
  String get authContinueGoogle => 'Continuer avec Google';

  @override
  String get authNoAccount => 'Vous n\'avez pas de compte ?';

  @override
  String get authHaveAccount => 'Vous avez déjà un compte ?';

  @override
  String get authRegister => 'S\'inscrire';

  @override
  String get authLogin => 'Se connecter';

  @override
  String get authErrorCouldNotAuth =>
      'Impossible de s\'authentifier. Veuillez réessayer.';

  @override
  String get authErrorUnexpected => 'Erreur inattendue. Veuillez réessayer.';

  @override
  String get authErrorGoogleSignIn => 'Impossible de se connecter avec Google.';

  @override
  String get authErrorGoogleSignInGeneric =>
      'Erreur lors de la connexion avec Google.';

  @override
  String get authErrorAccountExistsWithDifferentCredential =>
      'Cet e-mail est déjà enregistré avec un mot de passe. Veuillez vous connecter avec e-mail et mot de passe.';

  @override
  String get discoverTitle => 'Découvrir des personnes';

  @override
  String get discoverErrorLoading =>
      'Erreur lors du chargement de la découverte';

  @override
  String get discoverNoUsers => 'Aucun utilisateur avec des données musicales';

  @override
  String get discoverNoUsersHint =>
      'Au fur et à mesure que d\'autres utilisateurs connectent leur Spotify, ils apparaîtront ici';

  @override
  String get navDiscover => 'Découvrir';

  @override
  String get navStats => 'Statistiques';

  @override
  String get navMessages => 'Messages';

  @override
  String get navFriends => 'Amis';

  @override
  String get searchTitle => 'Rechercher des utilisateurs';

  @override
  String get searchHint => 'Nom d\'utilisateur...';

  @override
  String get searchNoResults => 'Aucun utilisateur trouvé';

  @override
  String get searchTypeToSearch => 'Tapez un nom pour rechercher';

  @override
  String get searchSpotifyConnected => 'Spotify connecté';

  @override
  String get profileTitle => 'Profil musical';

  @override
  String get profileStartChat => 'Démarrer une conversation';

  @override
  String get profileNoData =>
      'Cet utilisateur n\'a pas encore de données musicales';

  @override
  String get profileTopArtists => 'Top Artistes';

  @override
  String get profileTopGenres => 'Top Genres';

  @override
  String get profileCompatible => 'compatible';

  @override
  String get profileSharedArtists => 'Artistes en commun';

  @override
  String get profileSharedGenres => 'Genres en commun';

  @override
  String get chatWriteMessage => 'Écrire un message...';

  @override
  String get chatSearchSpotify => 'Rechercher une chanson sur Spotify...';

  @override
  String get chatShareSong => 'Partager une chanson';

  @override
  String get chatSendFirst => 'Envoyez le premier message';

  @override
  String get chatTypeToSearch => 'Tapez pour rechercher des chansons';

  @override
  String get chatNoResults => 'Aucun résultat';

  @override
  String get statsTracks => 'Titres';

  @override
  String get statsArtists => 'Artistes';

  @override
  String get statsGenres => 'Genres';

  @override
  String get statsShortTerm => '4 semaines';

  @override
  String get statsMediumTerm => '6 mois';

  @override
  String get statsLongTerm => '1 an';

  @override
  String statsError(String error) {
    return 'Erreur : $error';
  }

  @override
  String get statsNoData => 'Aucune donnée disponible';

  @override
  String get socialNow => 'Maintenant';

  @override
  String get nowPlaying => 'En train d\'écouter';

  @override
  String socialMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String socialDays(int days) {
    return '${days}j';
  }

  @override
  String get socialNoChats => 'Pas encore de conversations';

  @override
  String get socialNoChatsHint =>
      'Recherchez des utilisateurs pour commencer à discuter';

  @override
  String get socialErrorLoading =>
      'Erreur lors du chargement des conversations';

  @override
  String get socialLoading => 'Chargement...';

  @override
  String get socialUser => 'Utilisateur';

  @override
  String get spotifyConnectTitle => 'Connectez votre Spotify';

  @override
  String get spotifyConnectDescription =>
      'Pour voir vos statistiques musicales, nous avons besoin d\'accéder à votre compte Spotify.';

  @override
  String get spotifyConnectButton => 'Connecter Spotify';

  @override
  String get spotifyConnectError => 'Erreur lors de la connexion à Spotify';

  @override
  String get menuProfile => 'Mon profil';

  @override
  String get menuAccountOptions => 'Options du compte';

  @override
  String get menuLightMode => 'Mode clair';

  @override
  String get menuDarkMode => 'Mode sombre';

  @override
  String get menuSignOut => 'Se déconnecter';

  @override
  String get signingOut => 'Déconnexion en cours...';

  @override
  String discoverySharedArtists(String artists) {
    return 'Artistes en commun : $artists';
  }

  @override
  String discoverySharedGenres(String genres) {
    return 'Genres en commun : $genres';
  }

  @override
  String discoveryCompatible(String score) {
    return '$score% compatible';
  }

  @override
  String get friendsReceivedRequests => 'Demandes reçues';

  @override
  String get friendsSentRequests => 'Demandes envoyées';

  @override
  String get friendsMyFriends => 'Mes amis';

  @override
  String get friendsAccept => 'Accepter';

  @override
  String get friendsReject => 'Refuser';

  @override
  String get friendsCancel => 'Annuler';

  @override
  String get friendsSendRequest => 'Envoyer une demande';

  @override
  String get friendsRequestSent => 'Demande envoyée';

  @override
  String get friendsNoRequests => 'Aucune demande en attente';

  @override
  String get friendsNoFriends => 'Pas encore d\'amis';

  @override
  String get friendsNoFriendsHint =>
      'Recherchez des utilisateurs pour ajouter des amis';

  @override
  String get friendsRemove => 'Supprimer l\'ami';

  @override
  String get friendsRemoveBody =>
      'Cette personne sera supprimée de votre liste d\'amis.';

  @override
  String get friendsAlreadyFriends => 'Déjà amis';

  @override
  String get profileAddFriend => 'Ajouter un ami';

  @override
  String get dailySongTitle => 'Chanson du jour';

  @override
  String get dailySongYourTitle => 'Votre chanson du jour';

  @override
  String get dailySongChoose => 'Choisir votre chanson du jour';

  @override
  String dailySongBy(String artist) {
    return 'par $artist';
  }

  @override
  String get discoverTabPeople => 'Découvrir';

  @override
  String get dailySongNone =>
      'Vous n\'avez pas encore choisi votre chanson du jour';

  @override
  String get dailySongNoneHint =>
      'Partagez avec les autres ce que vous écoutez aujourd\'hui';

  @override
  String get dailySongFriendsTitle => 'Chansons de vos amis';

  @override
  String get dailySongFriendsNone =>
      'Vos amis n\'ont pas encore choisi de chanson du jour';

  @override
  String get dailySongNoFriends =>
      'Ajoutez des amis pour voir leurs chansons du jour';

  @override
  String get onboardingDiscoverTitle => 'Découvrez des personnes';

  @override
  String get onboardingDiscoverDesc =>
      'Trouvez des personnes aux goûts musicaux similaires et découvrez votre compatibilité selon vos artistes et genres préférés.';

  @override
  String get onboardingStatsTitle => 'Vos statistiques';

  @override
  String get onboardingStatsDesc =>
      'Explorez vos titres, artistes et genres préférés sur Spotify. Voyez comment vos goûts évoluent au fil du temps.';

  @override
  String get onboardingDailySongTitle => 'Chanson du jour';

  @override
  String get onboardingDailySongDesc =>
      'Choisissez une chanson chaque jour à partager avec vos amis. Découvrez ce qu\'ils écoutent et trouvez de la nouvelle musique ensemble.';

  @override
  String get onboardingChatTitle => 'Discutez de musique';

  @override
  String get onboardingChatDesc =>
      'Lancez des conversations et partagez des chansons directement depuis Spotify. Parlez de la musique que vous aimez avec des gens qui la comprennent.';

  @override
  String get onboardingFriendsTitle => 'Créez votre groupe';

  @override
  String get onboardingFriendsDesc =>
      'Ajoutez des amis, consultez leurs profils musicaux et restez connectés grâce à votre passion commune pour la musique.';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingGetStarted => 'Commencer';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get genericError => 'Une erreur s\'est produite. Veuillez réessayer.';
}
