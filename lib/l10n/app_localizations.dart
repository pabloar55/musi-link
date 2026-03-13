import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  /// No description provided for @authName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get authName;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authEnterName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get authEnterName;

  /// No description provided for @authEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get authEnterEmail;

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get authInvalidEmail;

  /// No description provided for @authEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authEnterPassword;

  /// No description provided for @authMinChars.
  ///
  /// In en, this message translates to:
  /// **'Minimum 6 characters'**
  String get authMinChars;

  /// No description provided for @authErrorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered.'**
  String get authErrorEmailInUse;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email.'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email.'**
  String get authErrorUserNotFound;

  /// No description provided for @authErrorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password.'**
  String get authErrorWrongPassword;

  /// No description provided for @authErrorInvalidCredential.
  ///
  /// In en, this message translates to:
  /// **'Invalid credentials.'**
  String get authErrorInvalidCredential;

  /// No description provided for @authErrorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment.'**
  String get authErrorTooManyRequests;

  /// No description provided for @authErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Authentication error ({code}).'**
  String authErrorGeneric(String code);

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// No description provided for @authOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOr;

  /// No description provided for @authContinueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueGoogle;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get authNoAccount;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authHaveAccount;

  /// No description provided for @authRegister.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get authRegister;

  /// No description provided for @authLogin.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get authLogin;

  /// No description provided for @authErrorCouldNotAuth.
  ///
  /// In en, this message translates to:
  /// **'Could not authenticate. Please try again.'**
  String get authErrorCouldNotAuth;

  /// No description provided for @authErrorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error. Please try again.'**
  String get authErrorUnexpected;

  /// No description provided for @authErrorGoogleSignIn.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in with Google.'**
  String get authErrorGoogleSignIn;

  /// No description provided for @authErrorGoogleSignInGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error signing in with Google.'**
  String get authErrorGoogleSignInGeneric;

  /// No description provided for @authErrorAccountExistsWithDifferentCredential.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered with a password. Please sign in with email and password.'**
  String get authErrorAccountExistsWithDifferentCredential;

  /// No description provided for @discoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover people'**
  String get discoverTitle;

  /// No description provided for @discoverErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading discovery'**
  String get discoverErrorLoading;

  /// No description provided for @discoverNoUsers.
  ///
  /// In en, this message translates to:
  /// **'No users with music data'**
  String get discoverNoUsers;

  /// No description provided for @discoverNoUsersHint.
  ///
  /// In en, this message translates to:
  /// **'As more users connect their Spotify, they will appear here'**
  String get discoverNoUsersHint;

  /// No description provided for @navDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get navDiscover;

  /// No description provided for @navStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get navStats;

  /// No description provided for @navMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get navMessages;

  /// No description provided for @navFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get navFriends;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search users'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Username...'**
  String get searchHint;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get searchNoResults;

  /// No description provided for @searchTypeToSearch.
  ///
  /// In en, this message translates to:
  /// **'Type a name to search'**
  String get searchTypeToSearch;

  /// No description provided for @searchSpotifyConnected.
  ///
  /// In en, this message translates to:
  /// **'Spotify connected'**
  String get searchSpotifyConnected;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Music profile'**
  String get profileTitle;

  /// No description provided for @profileStartChat.
  ///
  /// In en, this message translates to:
  /// **'Start chat'**
  String get profileStartChat;

  /// No description provided for @profileNoData.
  ///
  /// In en, this message translates to:
  /// **'This user doesn\'t have music data yet'**
  String get profileNoData;

  /// No description provided for @profileTopArtists.
  ///
  /// In en, this message translates to:
  /// **'Top Artists'**
  String get profileTopArtists;

  /// No description provided for @profileTopGenres.
  ///
  /// In en, this message translates to:
  /// **'Top Genres'**
  String get profileTopGenres;

  /// No description provided for @profileCompatible.
  ///
  /// In en, this message translates to:
  /// **'compatible'**
  String get profileCompatible;

  /// No description provided for @profileSharedArtists.
  ///
  /// In en, this message translates to:
  /// **'Artists in common'**
  String get profileSharedArtists;

  /// No description provided for @profileSharedGenres.
  ///
  /// In en, this message translates to:
  /// **'Genres in common'**
  String get profileSharedGenres;

  /// No description provided for @chatWriteMessage.
  ///
  /// In en, this message translates to:
  /// **'Write a message...'**
  String get chatWriteMessage;

  /// No description provided for @chatSearchSpotify.
  ///
  /// In en, this message translates to:
  /// **'Search song on Spotify...'**
  String get chatSearchSpotify;

  /// No description provided for @chatShareSong.
  ///
  /// In en, this message translates to:
  /// **'Share song'**
  String get chatShareSong;

  /// No description provided for @chatSendFirst.
  ///
  /// In en, this message translates to:
  /// **'Send the first message'**
  String get chatSendFirst;

  /// No description provided for @chatTypeToSearch.
  ///
  /// In en, this message translates to:
  /// **'Type to search songs'**
  String get chatTypeToSearch;

  /// No description provided for @chatNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get chatNoResults;

  /// No description provided for @statsTracks.
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get statsTracks;

  /// No description provided for @statsArtists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get statsArtists;

  /// No description provided for @statsGenres.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get statsGenres;

  /// No description provided for @statsShortTerm.
  ///
  /// In en, this message translates to:
  /// **'4 weeks'**
  String get statsShortTerm;

  /// No description provided for @statsMediumTerm.
  ///
  /// In en, this message translates to:
  /// **'6 months'**
  String get statsMediumTerm;

  /// No description provided for @statsLongTerm.
  ///
  /// In en, this message translates to:
  /// **'1 year'**
  String get statsLongTerm;

  /// No description provided for @statsError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String statsError(String error);

  /// No description provided for @statsNoData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get statsNoData;

  /// No description provided for @socialNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get socialNow;

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get nowPlaying;

  /// No description provided for @socialMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String socialMinutes(int minutes);

  /// No description provided for @socialDays.
  ///
  /// In en, this message translates to:
  /// **'{days}d'**
  String socialDays(int days);

  /// No description provided for @socialNoChats.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get socialNoChats;

  /// No description provided for @socialNoChatsHint.
  ///
  /// In en, this message translates to:
  /// **'Search for users to start chatting'**
  String get socialNoChatsHint;

  /// No description provided for @socialErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading conversations'**
  String get socialErrorLoading;

  /// No description provided for @socialLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get socialLoading;

  /// No description provided for @socialUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get socialUser;

  /// No description provided for @spotifyConnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect your Spotify'**
  String get spotifyConnectTitle;

  /// No description provided for @spotifyConnectDescription.
  ///
  /// In en, this message translates to:
  /// **'To see your music stats we need access to your Spotify account.'**
  String get spotifyConnectDescription;

  /// No description provided for @spotifyConnectButton.
  ///
  /// In en, this message translates to:
  /// **'Connect Spotify'**
  String get spotifyConnectButton;

  /// No description provided for @spotifyConnectError.
  ///
  /// In en, this message translates to:
  /// **'Error connecting to Spotify'**
  String get spotifyConnectError;

  /// No description provided for @menuProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get menuProfile;

  /// No description provided for @menuAccountOptions.
  ///
  /// In en, this message translates to:
  /// **'Account options'**
  String get menuAccountOptions;

  /// No description provided for @menuLightMode.
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get menuLightMode;

  /// No description provided for @menuDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get menuDarkMode;

  /// No description provided for @menuSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get menuSignOut;

  /// No description provided for @discoverySharedArtists.
  ///
  /// In en, this message translates to:
  /// **'Artists in common: {artists}'**
  String discoverySharedArtists(String artists);

  /// No description provided for @discoverySharedGenres.
  ///
  /// In en, this message translates to:
  /// **'Genres in common: {genres}'**
  String discoverySharedGenres(String genres);

  /// No description provided for @discoveryCompatible.
  ///
  /// In en, this message translates to:
  /// **'{score}% compatible'**
  String discoveryCompatible(String score);

  /// No description provided for @friendsReceivedRequests.
  ///
  /// In en, this message translates to:
  /// **'Received requests'**
  String get friendsReceivedRequests;

  /// No description provided for @friendsSentRequests.
  ///
  /// In en, this message translates to:
  /// **'Sent requests'**
  String get friendsSentRequests;

  /// No description provided for @friendsMyFriends.
  ///
  /// In en, this message translates to:
  /// **'My friends'**
  String get friendsMyFriends;

  /// No description provided for @friendsAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get friendsAccept;

  /// No description provided for @friendsReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get friendsReject;

  /// No description provided for @friendsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get friendsCancel;

  /// No description provided for @friendsSendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get friendsSendRequest;

  /// No description provided for @friendsRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get friendsRequestSent;

  /// No description provided for @friendsNoRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get friendsNoRequests;

  /// No description provided for @friendsNoFriends.
  ///
  /// In en, this message translates to:
  /// **'No friends yet'**
  String get friendsNoFriends;

  /// No description provided for @friendsNoFriendsHint.
  ///
  /// In en, this message translates to:
  /// **'Search for users to add friends'**
  String get friendsNoFriendsHint;

  /// No description provided for @friendsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove friend'**
  String get friendsRemove;

  /// No description provided for @friendsRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'This person will be removed from your friends list.'**
  String get friendsRemoveBody;

  /// No description provided for @friendsAlreadyFriends.
  ///
  /// In en, this message translates to:
  /// **'Already friends'**
  String get friendsAlreadyFriends;

  /// No description provided for @profileAddFriend.
  ///
  /// In en, this message translates to:
  /// **'Add friend'**
  String get profileAddFriend;

  /// No description provided for @dailySongTitle.
  ///
  /// In en, this message translates to:
  /// **'Song of the day'**
  String get dailySongTitle;

  /// No description provided for @dailySongChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose song of the day'**
  String get dailySongChoose;

  /// No description provided for @dailySongBy.
  ///
  /// In en, this message translates to:
  /// **'by {artist}'**
  String dailySongBy(String artist);

  /// No description provided for @discoverTabPeople.
  ///
  /// In en, this message translates to:
  /// **'Discover people'**
  String get discoverTabPeople;

  /// No description provided for @dailySongNone.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t chosen a song of the day yet'**
  String get dailySongNone;

  /// No description provided for @dailySongNoneHint.
  ///
  /// In en, this message translates to:
  /// **'Share with others what you\'re listening to today'**
  String get dailySongNoneHint;

  /// No description provided for @dailySongFriendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your friends\' songs'**
  String get dailySongFriendsTitle;

  /// No description provided for @dailySongFriendsNone.
  ///
  /// In en, this message translates to:
  /// **'Your friends haven\'t chosen a song of the day yet'**
  String get dailySongFriendsNone;

  /// No description provided for @dailySongNoFriends.
  ///
  /// In en, this message translates to:
  /// **'Add friends to see their song of the day'**
  String get dailySongNoFriends;

  /// No description provided for @onboardingDiscoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover people'**
  String get onboardingDiscoverTitle;

  /// No description provided for @onboardingDiscoverDesc.
  ///
  /// In en, this message translates to:
  /// **'Find people with similar music taste and discover how compatible you are based on your top artists and genres.'**
  String get onboardingDiscoverDesc;

  /// No description provided for @onboardingStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your music stats'**
  String get onboardingStatsTitle;

  /// No description provided for @onboardingStatsDesc.
  ///
  /// In en, this message translates to:
  /// **'Explore your top tracks, artists and genres from Spotify. See how your taste evolves over time.'**
  String get onboardingStatsDesc;

  /// No description provided for @onboardingDailySongTitle.
  ///
  /// In en, this message translates to:
  /// **'Song of the day'**
  String get onboardingDailySongTitle;

  /// No description provided for @onboardingDailySongDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose a song each day to share with your friends. See what they\'re listening to and discover new music together.'**
  String get onboardingDailySongDesc;

  /// No description provided for @onboardingChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat about music'**
  String get onboardingChatTitle;

  /// No description provided for @onboardingChatDesc.
  ///
  /// In en, this message translates to:
  /// **'Start conversations and share songs directly from Spotify. Talk about the music you love with people who get it.'**
  String get onboardingChatDesc;

  /// No description provided for @onboardingFriendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Build your crew'**
  String get onboardingFriendsTitle;

  /// No description provided for @onboardingFriendsDesc.
  ///
  /// In en, this message translates to:
  /// **'Add friends, see their music profiles, and stay connected through your shared passion for music.'**
  String get onboardingFriendsDesc;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
