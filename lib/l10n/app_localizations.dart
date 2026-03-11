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

  /// No description provided for @homeErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading discovery'**
  String get homeErrorLoading;

  /// No description provided for @homeNoUsers.
  ///
  /// In en, this message translates to:
  /// **'No users with music data'**
  String get homeNoUsers;

  /// No description provided for @homeNoUsersHint.
  ///
  /// In en, this message translates to:
  /// **'As more users connect their Spotify, they will appear here'**
  String get homeNoUsersHint;

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

  /// No description provided for @navSocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get navSocial;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

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
