import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

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
  ];

  /// Application title / game brand name
  ///
  /// In en, this message translates to:
  /// **'Arrow Escape'**
  String get appTitle;

  /// Subtitle under the game title on the home screen
  ///
  /// In en, this message translates to:
  /// **'Clear the board. Survive.'**
  String get homeTagline;

  /// Primary button on home that starts the campaign
  ///
  /// In en, this message translates to:
  /// **'PLAY'**
  String get playButton;

  /// Home button that opens the AI level generator
  ///
  /// In en, this message translates to:
  /// **'AI LEVEL BUILDER'**
  String get aiLevelBuilderButton;

  /// Title of the settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Tooltip of the settings icon on the home screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// Section header for audio options in settings
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get settingsSoundSection;

  /// Label of the mute toggle in settings
  ///
  /// In en, this message translates to:
  /// **'Mute sound'**
  String get settingsMuteLabel;

  /// Section header for the language selector in settings
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageSection;

  /// Name of the Spanish language option
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageSpanish;

  /// Name of the English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Tooltip of the undo action in the game screen
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoTooltip;

  /// Tooltip of the restart action in the game screen
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restartTooltip;

  /// Tooltip shown on the HUD mute button when sound is on
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get muteTooltip;

  /// Tooltip shown on the HUD mute button when sound is muted
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmuteTooltip;

  /// Title of the victory overlay
  ///
  /// In en, this message translates to:
  /// **'Level complete!'**
  String get victoryTitle;

  /// Fallback victory subtitle when no score is available
  ///
  /// In en, this message translates to:
  /// **'All arrows escaped.'**
  String get victorySubtitleDefault;

  /// Victory subtitle showing the earned score
  ///
  /// In en, this message translates to:
  /// **'Score: {score}'**
  String victoryScore(int score);

  /// Badge shown when the player beats their best score
  ///
  /// In en, this message translates to:
  /// **'New record!'**
  String get newRecord;

  /// Button that advances to the next campaign level
  ///
  /// In en, this message translates to:
  /// **'Next level'**
  String get nextLevelButton;

  /// Button that returns to the level select screen
  ///
  /// In en, this message translates to:
  /// **'Levels'**
  String get levelsButton;

  /// Title of the defeat overlay
  ///
  /// In en, this message translates to:
  /// **'Game Over'**
  String get gameOverTitle;

  /// Subtitle of the defeat overlay
  ///
  /// In en, this message translates to:
  /// **'No lives left. Try again!'**
  String get gameOverSubtitle;

  /// Button that restarts the failed level
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// Button that leaves the game back to the previous screen
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeButton;

  /// Title of the level select screen
  ///
  /// In en, this message translates to:
  /// **'Levels'**
  String get levelsTitle;

  /// Section header for the campaign levels
  ///
  /// In en, this message translates to:
  /// **'Campaign'**
  String get campaignSection;

  /// Section header for AI generated levels
  ///
  /// In en, this message translates to:
  /// **'AI Generated'**
  String get aiGeneratedSection;

  /// Metadata line of a generated level: arrow count and difficulty
  ///
  /// In en, this message translates to:
  /// **'{count} arrows · {difficulty}'**
  String levelMeta(int count, String difficulty);

  /// Tooltip of the account icon on the home screen
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTooltip;

  /// Home button that opens the login screen for a guest
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// Button in the account menu that logs the user out
  ///
  /// In en, this message translates to:
  /// **'LOG OUT'**
  String get logoutButton;

  /// Greeting shown in the account menu for a logged-in user
  ///
  /// In en, this message translates to:
  /// **'Hi, {username}'**
  String accountGreeting(String username);
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
      <String>['en', 'es'].contains(locale.languageCode);

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
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
