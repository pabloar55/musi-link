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
  String get statsOfflineCache => 'Hors ligne — données enregistrées affichées';

  @override
  String get statsOfflineNoData =>
      'Pas de connexion et aucune donnée enregistrée.\nConsultez cet onglet en ligne d\'abord.';

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
  String get spotifyAlreadyLinkedError =>
      'Ce compte Spotify est déjà lié à un autre utilisateur';

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

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get settingsLegal => 'Informations légales';

  @override
  String get settingsPrivacyPolicy => 'Politique de confidentialité';

  @override
  String get settingsDeleteAccount => 'Supprimer le compte';

  @override
  String get privacyTitle => 'Politique de confidentialité';

  @override
  String get privacyLastUpdated => 'Dernière mise à jour : 6 avril 2026';

  @override
  String get privacyS1Title => '1. Responsable du traitement';

  @override
  String get privacyS1Body =>
      'Musi Link est développée et exploitée par Pablo Armas (armasp80@gmail.com), établi en Espagne. Pablo Armas agit en tant que responsable du traitement de vos données personnelles conformément au Règlement (UE) 2016/679 (RGPD).';

  @override
  String get privacyS2Title => '2. Données collectées';

  @override
  String get privacyS2Body =>
      'Nous collectons et traitons les données personnelles suivantes :\n\n• Données de compte : nom, adresse e-mail, photo de profil et identifiants de connexion (via e-mail/mot de passe ou Google).\n\n• Données Spotify : identifiant utilisateur Spotify, photo de profil, artistes, genres et titres les plus écoutés, et titre en cours de lecture — synchronisés via l\'API Spotify avec votre autorisation explicite.\n\n• Données sociales : messages, chansons partagées, chanson du jour, demandes d\'amitié et réactions emoji.\n\n• Données techniques : rapports de plantage et événements d\'utilisation anonymisés collectés par Firebase Crashlytics et Firebase Analytics.';

  @override
  String get privacyS3Title => '3. Utilisation de vos données';

  @override
  String get privacyS3Body =>
      'Vos données sont traitées aux fins suivantes :\n\n• Fourniture du service (compte, compatibilité musicale, découverte, chat). Base légale : exécution d\'un contrat (art. 6.1.b RGPD).\n\n• Intégration Spotify : affichage et comparaison de votre profil musical. Base légale : exécution d\'un contrat (art. 6.1.b RGPD).\n\n• Stabilité de l\'application : diagnostic des erreurs et plantages. Base légale : intérêt légitime (art. 6.1.f RGPD).\n\n• Analyses : comprendre l\'utilisation de l\'application pour l\'améliorer. Base légale : intérêt légitime (art. 6.1.f RGPD).';

  @override
  String get privacyS4Title => '4. Services tiers';

  @override
  String get privacyS4Body =>
      'Nous utilisons les services tiers suivants, soumis à leurs propres politiques de confidentialité :\n\n• Google Firebase (Auth, Firestore, Crashlytics, Analytics) — Google LLC. Les données peuvent être transférées aux États-Unis dans le cadre de clauses contractuelles types.\n\n• Spotify — Spotify AB. Utilisé uniquement pour lire vos données musicales avec votre autorisation.';

  @override
  String get privacyS5Title => '5. Conservation et suppression des données';

  @override
  String get privacyS5Body =>
      'Nous ne conservons pas vos données au-delà de la durée d\'utilisation de l\'application. Lorsque vous supprimez votre compte via le bouton « Supprimer le compte » dans les Paramètres, toutes vos données personnelles sont définitivement et immédiatement effacées de nos systèmes. Les rapports de plantage et données analytiques conservés par Google sont soumis aux politiques de conservation de Google.';

  @override
  String get privacyS6Title => '6. Vos droits';

  @override
  String get privacyS6Body =>
      'En vertu du RGPD, vous disposez des droits suivants :\n\n• Accès : demander une copie des données que nous détenons à votre sujet.\n• Rectification : corriger des données inexactes ou incomplètes.\n• Effacement : supprimer votre compte et toutes les données associées via le bouton « Supprimer le compte » dans les Paramètres.\n• Limitation : demander que nous limitions le traitement de vos données.\n• Portabilité : recevoir vos données dans un format structuré et lisible par machine.\n• Opposition : vous opposer au traitement fondé sur l\'intérêt légitime.\n\nPour exercer ces droits, contactez armasp80@gmail.com. Vous pouvez également introduire une réclamation auprès de l\'Agence Espagnole de Protection des Données (AEPD) à l\'adresse www.aepd.es.';

  @override
  String get privacyS7Title => '7. Âge minimum';

  @override
  String get privacyS7Body =>
      'Musi Link est destinée aux utilisateurs âgés de 16 ans et plus. Nous ne collectons pas sciemment de données personnelles auprès de personnes de moins de 16 ans. Si vous pensez qu\'un mineur nous a fourni des données personnelles, contactez-nous à armasp80@gmail.com et nous les supprimerons immédiatement.';

  @override
  String get privacyS8Title => '8. Sécurité';

  @override
  String get privacyS8Body =>
      'Nous mettons en œuvre des mesures techniques et organisationnelles appropriées pour protéger vos données personnelles contre tout accès non autorisé, perte ou altération. Les données sont stockées sur Google Firebase, qui applique des contrôles de sécurité conformes aux normes du secteur.';

  @override
  String get privacyS9Title => '9. Contact';

  @override
  String get privacyS9Body =>
      'Pour toute question concernant cette Politique de Confidentialité ou le traitement de vos données personnelles, contactez-nous à :\n\nPablo Armas\narmasp80@gmail.com';
}
