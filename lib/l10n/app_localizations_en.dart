// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Arrow Escape';

  @override
  String get homeTagline => 'Clear the board. Survive.';

  @override
  String get playButton => 'PLAY';

  @override
  String get aiLevelBuilderButton => 'AI LEVEL BUILDER';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get settingsSoundSection => 'Sound';

  @override
  String get settingsMuteLabel => 'Mute sound';

  @override
  String get settingsLanguageSection => 'Language';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get languageEnglish => 'English';

  @override
  String get undoTooltip => 'Undo';

  @override
  String get restartTooltip => 'Restart';

  @override
  String get muteTooltip => 'Mute';

  @override
  String get unmuteTooltip => 'Unmute';

  @override
  String get victoryTitle => 'Level complete!';

  @override
  String get victorySubtitleDefault => 'All arrows escaped.';

  @override
  String victoryScore(int score) {
    return 'Score: $score';
  }

  @override
  String get newRecord => 'New record!';

  @override
  String get nextLevelButton => 'Next level';

  @override
  String get levelsButton => 'Levels';

  @override
  String get gameOverTitle => 'Game Over';

  @override
  String get gameOverSubtitle => 'No lives left. Try again!';

  @override
  String get retryButton => 'Retry';

  @override
  String get homeButton => 'Home';

  @override
  String get levelsTitle => 'Levels';

  @override
  String get campaignSection => 'Campaign';

  @override
  String get aiGeneratedSection => 'AI Generated';

  @override
  String levelMeta(int count, String difficulty) {
    return '$count arrows · $difficulty';
  }

  @override
  String get accountTooltip => 'Account';

  @override
  String get loginButton => 'Login';

  @override
  String get logoutButton => 'LOG OUT';

  @override
  String accountGreeting(String username) {
    return 'Hi, $username';
  }
}
