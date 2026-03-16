// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
  String get statsNoData => 'No data available';

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
  String get socialLoading => 'Loading...';

  @override
  String get socialUser => 'User';

  @override
  String get spotifyConnectTitle => 'Connect your Spotify';

  @override
  String get spotifyConnectDescription =>
      'To see your music stats we need access to your Spotify account.';

  @override
  String get spotifyConnectButton => 'Connect Spotify';

  @override
  String get spotifyConnectError => 'Error connecting to Spotify';

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
}
