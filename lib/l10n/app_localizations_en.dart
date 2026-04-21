// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get authTagline => 'Connect with people who share your music taste';

  @override
  String get authName => 'Name';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authEnterName => 'Enter your name';

  @override
  String get authEnterEmail => 'Enter your email';

  @override
  String get authInvalidEmail => 'Invalid email';

  @override
  String get authEnterPassword => 'Enter your password';

  @override
  String get authMinChars => 'Minimum 6 characters';

  @override
  String get authErrorEmailInUse => 'This email is already registered.';

  @override
  String get authErrorInvalidEmail => 'Invalid email.';

  @override
  String get authErrorWeakPassword => 'Password must be at least 6 characters.';

  @override
  String get authErrorUserNotFound => 'No account found with this email.';

  @override
  String get authErrorWrongPassword => 'Incorrect password.';

  @override
  String get authErrorInvalidCredential => 'Invalid credentials.';

  @override
  String get authErrorTooManyRequests =>
      'Too many attempts. Please wait a moment.';

  @override
  String authErrorGeneric(String code) {
    return 'Authentication error ($code).';
  }

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authOr => 'or';

  @override
  String get authContinueGoogle => 'Continue with Google';

  @override
  String get authNoAccount => 'Don\'t have an account?';

  @override
  String get authHaveAccount => 'Already have an account?';

  @override
  String get authRegister => 'Sign up';

  @override
  String get authLogin => 'Log in';

  @override
  String get authErrorCouldNotAuth =>
      'Could not authenticate. Please try again.';

  @override
  String get authErrorUnexpected => 'Unexpected error. Please try again.';

  @override
  String get authErrorGoogleSignIn => 'Could not sign in with Google.';

  @override
  String get authErrorGoogleSignInGeneric => 'Error signing in with Google.';

  @override
  String get authErrorAccountExistsWithDifferentCredential =>
      'This email is already registered with a password. Please sign in with email and password.';

  @override
  String get discoverTitle => 'Discover people';

  @override
  String get discoverErrorLoading => 'Error loading discovery';

  @override
  String get discoverNoUsers => 'No users with music data';

  @override
  String get discoverNoUsersHint =>
      'As more users connect their Spotify, they will appear here';

  @override
  String get navDiscover => 'Discover';

  @override
  String get navStats => 'Stats';

  @override
  String get navMessages => 'Messages';

  @override
  String get navFriends => 'Friends';

  @override
  String get searchTitle => 'Search users';

  @override
  String get searchHint => 'Username...';

  @override
  String get searchNoResults => 'No users found';

  @override
  String get searchTypeToSearch => 'Type a name to search';

  @override
  String get searchSpotifyConnected => 'Spotify connected';

  @override
  String get profileTitle => 'Music profile';

  @override
  String get profileStartChat => 'Start chat';

  @override
  String get profileNoData => 'This user doesn\'t have music data yet';

  @override
  String get profileTopArtists => 'Top Artists';

  @override
  String get profileTopGenres => 'Top Genres';

  @override
  String get profileCompatible => 'compatible';

  @override
  String get profileSharedArtists => 'Artists in common';

  @override
  String get profileSharedGenres => 'Genres in common';

  @override
  String get chatWriteMessage => 'Write a message...';

  @override
  String get chatSearchSpotify => 'Search song on Spotify...';

  @override
  String get chatShareSong => 'Share song';

  @override
  String get chatSendFirst => 'Send the first message';

  @override
  String get chatTypeToSearch => 'Type to search songs';

  @override
  String get chatNoResults => 'No results';

  @override
  String get statsTracks => 'Tracks';

  @override
  String get statsArtists => 'Artists';

  @override
  String get statsGenres => 'Genres';

  @override
  String get statsShortTerm => '4 weeks';

  @override
  String get statsMediumTerm => '6 months';

  @override
  String get statsLongTerm => '1 year';

  @override
  String statsError(String error) {
    return 'Error: $error';
  }

  @override
  String get statsEditArtists => 'Edit artists';

  @override
  String get statsNoData => 'No data available';

  @override
  String get statsOfflineCache => 'Offline — showing saved data';

  @override
  String get statsStaleCache => 'Showing data from over 48 hours ago';

  @override
  String get statsOfflineNoData =>
      'No connection and no saved data yet.\nVisit this tab online first.';

  @override
  String get socialNow => 'Now';

  @override
  String get nowPlaying => 'Now playing';

  @override
  String socialMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String socialDays(int days) {
    return '${days}d';
  }

  @override
  String get socialNoChats => 'No conversations yet';

  @override
  String get socialNoChatsHint => 'Search for users to start chatting';

  @override
  String get socialErrorLoading => 'Error loading conversations';

  @override
  String get socialUser => 'User';

  @override
  String get artistSelectorTitle => 'Your Top Artists';

  @override
  String artistSelectorSubtitle(int min, int count) {
    return '$count added · drag to reorder (min. $min)';
  }

  @override
  String get artistSelectorSearchHint => 'Search artists...';

  @override
  String get artistSelectorContinue => 'Continue';

  @override
  String get artistSelectorNoResults => 'No artists found';

  @override
  String get artistSelectorEmpty =>
      'Search for your favourite artists to get started';

  @override
  String get artistSelectorSuggested => 'Suggested';

  @override
  String get menuProfile => 'My profile';

  @override
  String get menuAccountOptions => 'Account options';

  @override
  String get menuLightMode => 'Light mode';

  @override
  String get menuDarkMode => 'Dark mode';

  @override
  String get menuSignOut => 'Sign out';

  @override
  String get signingOut => 'Signing out...';

  @override
  String discoverySharedArtists(String artists) {
    return 'Artists in common: $artists';
  }

  @override
  String discoverySharedGenres(String genres) {
    return 'Genres in common: $genres';
  }

  @override
  String discoveryCompatible(String score) {
    return '$score% compatible';
  }

  @override
  String get friendsReceivedRequests => 'Received requests';

  @override
  String get friendsSentRequests => 'Sent requests';

  @override
  String get friendsMyFriends => 'My friends';

  @override
  String get friendsAccept => 'Accept';

  @override
  String get friendsReject => 'Reject';

  @override
  String get friendsCancel => 'Cancel';

  @override
  String get friendsSendRequest => 'Send request';

  @override
  String get friendsRequestSent => 'Request sent';

  @override
  String get friendsNoRequests => 'No pending requests';

  @override
  String get friendsNoFriends => 'No friends yet';

  @override
  String get friendsNoFriendsHint => 'Search for users to add friends';

  @override
  String get friendsRemove => 'Remove friend';

  @override
  String get friendsRemoveBody =>
      'This person will be removed from your friends list.';

  @override
  String get friendsAlreadyFriends => 'Already friends';

  @override
  String get profileAddFriend => 'Add friend';

  @override
  String get dailySongTitle => 'Song of the day';

  @override
  String get dailySongYourTitle => 'Your song of the day';

  @override
  String get dailySongChoose => 'Choose your song of the day';

  @override
  String dailySongBy(String artist) {
    return 'by $artist';
  }

  @override
  String get discoverTabPeople => 'Discover people';

  @override
  String get dailySongNone => 'You haven\'t chosen your song of the day yet';

  @override
  String get dailySongNoneHint =>
      'Share with others what you\'re listening to today';

  @override
  String get dailySongFriendsTitle => 'Your friends\' songs';

  @override
  String get dailySongFriendsNone =>
      'Your friends haven\'t chosen a song of the day yet';

  @override
  String get dailySongNoFriends => 'Add friends to see their song of the day';

  @override
  String get onboardingDiscoverTitle => 'Discover people';

  @override
  String get onboardingDiscoverDesc =>
      'Find people with similar music taste and discover how compatible you are based on your top artists and genres.';

  @override
  String get onboardingStatsTitle => 'Your music stats';

  @override
  String get onboardingStatsDesc =>
      'Explore your top tracks, artists and genres from Spotify. See how your taste evolves over time.';

  @override
  String get onboardingDailySongTitle => 'Song of the day';

  @override
  String get onboardingDailySongDesc =>
      'Choose a song each day to share with your friends. See what they\'re listening to and discover new music together.';

  @override
  String get onboardingChatTitle => 'Chat about music';

  @override
  String get onboardingChatDesc =>
      'Start conversations and share songs directly from Spotify. Talk about the music you love with people who get it.';

  @override
  String get onboardingFriendsTitle => 'Build your crew';

  @override
  String get onboardingFriendsDesc =>
      'Add friends, see their music profiles, and stay connected through your shared passion for music.';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get photoSetupTitle => 'Add a profile photo';

  @override
  String get photoSetupSubtitle =>
      'Let others know who you are. You can always change it later.';

  @override
  String get photoSetupChoose => 'Choose photo';

  @override
  String get photoSetupChange => 'Change photo';

  @override
  String get photoSetupContinue => 'Continue';

  @override
  String get photoSetupSkip => 'Skip for now';

  @override
  String get photoSetupUploading => 'Uploading...';

  @override
  String get photoSetupGallery => 'Gallery';

  @override
  String get photoSetupCamera => 'Camera';

  @override
  String get photoSetupError => 'Could not upload photo. Please try again.';

  @override
  String get genericError => 'Something went wrong. Please try again.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsVibration => 'Vibration';

  @override
  String get settingsLegal => 'Legal';

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get deleteAccountBody =>
      'This will permanently delete your account, all your messages, Spotify data and profile information. This action cannot be undone.';

  @override
  String get deleteAccountConfirm => 'Delete';

  @override
  String get deletingAccount => 'Deleting account...';

  @override
  String get reauthTitle => 'Confirm your identity';

  @override
  String get reauthBody => 'To delete your account, re-enter your password.';

  @override
  String get reauthConfirm => 'Confirm';

  @override
  String get reauthWrongAccount =>
      'The selected account is not linked to this app. Please choose the correct account.';

  @override
  String get privacyTitle => 'Privacy Policy';

  @override
  String get privacyLastUpdated => 'Last updated: 6 April 2026';

  @override
  String get privacyS1Title => '1. Data Controller';

  @override
  String get privacyS1Body =>
      'MusiLink is developed and operated by Pablo Armas (armasp80@gmail.com), established in Spain. Pablo Armas is the data controller responsible for processing your personal data in accordance with Regulation (EU) 2016/679 (GDPR).';

  @override
  String get privacyS2Title => '2. Data We Collect';

  @override
  String get privacyS2Body =>
      'We collect and process the following personal data:\n\n• Account data: name, email address, profile photo, and login identifiers (via email/password or Google Sign-In).\n\n• Spotify data: Spotify user ID, profile photo, top artists, top genres, top tracks, and currently playing track — synced via Spotify\'s API with your explicit authorisation.\n\n• Social data: messages, shared songs, daily song selections, friend requests, and emoji reactions.\n\n• Technical data: crash logs and anonymised usage events collected by Firebase Crashlytics and Firebase Analytics.';

  @override
  String get privacyS3Title => '3. How We Use Your Data';

  @override
  String get privacyS3Body =>
      'Your data is processed for the following purposes:\n\n• Providing the service (account, music compatibility, discovery, chat). Legal basis: contract performance (Art. 6.1.b GDPR).\n\n• Spotify integration: displaying and comparing your music taste. Legal basis: contract performance (Art. 6.1.b GDPR).\n\n• App stability: diagnosing crashes and errors. Legal basis: legitimate interest (Art. 6.1.f GDPR).\n\n• Analytics: understanding how users interact with the App to improve it. Legal basis: legitimate interest (Art. 6.1.f GDPR).';

  @override
  String get privacyS4Title => '4. Third-Party Services';

  @override
  String get privacyS4Body =>
      'We use the following third-party services, each with their own privacy policies:\n\n• Google Firebase (Auth, Firestore, Crashlytics, Analytics) — Google LLC. Data may be transferred to the US under standard contractual clauses.\n\n• Spotify — Spotify AB. Used only to read your music data with your authorisation.';

  @override
  String get privacyS5Title => '5. Data Retention & Deletion';

  @override
  String get privacyS5Body =>
      'We do not retain your data beyond the time you use the App. When you delete your account via the \'Delete account\' button in Settings, all your personal data is permanently and immediately deleted from our systems. Crash reports and analytics data held by Google are subject to Google\'s own retention policies.';

  @override
  String get privacyS6Title => '6. Your Rights';

  @override
  String get privacyS6Body =>
      'Under GDPR, you have the following rights:\n\n• Access: request a copy of data we hold about you.\n• Rectification: correct inaccurate or incomplete data.\n• Erasure: delete your account and all data via the \'Delete account\' button in Settings.\n• Restriction: request we limit processing of your data.\n• Portability: receive your data in a structured, machine-readable format.\n• Objection: object to processing based on legitimate interest.\n\nTo exercise these rights, contact armasp80@gmail.com. You may also file a complaint with the Spanish Data Protection Authority (AEPD) at www.aepd.es.';

  @override
  String get privacyS7Title => '7. Minimum Age';

  @override
  String get privacyS7Body =>
      'MusiLink is intended for users aged 16 and over. We do not knowingly collect personal data from anyone under 16. If you believe a minor has provided us with personal data, contact us at armasp80@gmail.com and we will delete it immediately.';

  @override
  String get privacyS8Title => '8. Security';

  @override
  String get privacyS8Body =>
      'We implement appropriate technical and organisational measures to protect your personal data against unauthorised access, loss, or alteration. Data is stored in Google Firebase, which applies industry-standard security controls.';

  @override
  String get privacyS9Title => '9. Contact';

  @override
  String get privacyS9Body =>
      'For any questions about this Privacy Policy or the processing of your data, please contact:\n\nPablo Armas\narmasp80@gmail.com';
}
