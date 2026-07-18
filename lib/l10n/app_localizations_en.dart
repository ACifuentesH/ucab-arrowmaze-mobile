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
  String get creativeButton => 'CREATIVE';

  @override
  String get survivalModeButton => 'TIME TRIAL MODE';

  @override
  String get survivalLeaderboardTitle => 'Time Trial Leaderboard';

  @override
  String get survivalLeaderboardEmpty => 'No records yet';

  @override
  String get survivalLeaderboardError =>
      'Could not load the time trial ranking. Check your connection and try again.';

  @override
  String get survivalLeaderboardRetry => 'Retry';

  @override
  String get survivalPlayAgain => 'Play again';

  @override
  String get survivalViewRanking => 'View ranking';

  @override
  String get survivalBackToMenu => 'Back to menu';

  @override
  String survivalBoardsSolved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'boards',
      one: 'board',
    );
    return '$_temp0';
  }

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
  String get hexModeButton => 'Hexagonal Mode';

  @override
  String get hexModeTitle => 'Hexagonal Mode';

  @override
  String get hexModeSubtitle =>
      'Honeycomb boards: arrows escape through 6 directions.';

  @override
  String get hexComingSoon => 'Coming soon';

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

  @override
  String get loginPromptTitle => 'Want to save your progress?';

  @override
  String get loginPromptSubtitle =>
      'Log in or create an account to sync your levels and scores. You can also keep playing without one.';

  @override
  String get loginPromptLoginButton => 'Log in';

  @override
  String get loginPromptRegisterButton => 'Create account';

  @override
  String get loginPromptGuestButton => 'Continue as guest';

  @override
  String get loginTitle => 'Log in';

  @override
  String get loginSubtitle => 'Enter your credentials to continue';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'you@email.com';

  @override
  String get passwordLabel => 'Password';

  @override
  String get emailRequired => 'Enter your email';

  @override
  String get emailInvalid => 'Invalid email address';

  @override
  String get passwordRequired => 'Enter your password';

  @override
  String get loginSubmitButton => 'LOG IN';

  @override
  String get loginRegisterLink => 'Don\'t have an account? Sign up';

  @override
  String get registerTitle => 'Create account';

  @override
  String get registerSubtitle => 'Enter your details to sign up';

  @override
  String get usernameLabel => 'Username';

  @override
  String get usernameHint => 'your_username';

  @override
  String get usernameRequired => 'Enter a username';

  @override
  String get usernameLengthValidation =>
      'Username must be between 3 and 30 characters';

  @override
  String get passwordMinLengthValidation =>
      'Password must be at least 6 characters';

  @override
  String get registerSubmitButton => 'SIGN UP';

  @override
  String get registerLoginLink => 'Already have an account? Log in';

  @override
  String get survivalExitTitle => 'Quit game?';

  @override
  String get survivalExitMessage => 'You will lose your progress';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get survivalExitButton => 'Quit';

  @override
  String get survivalExitTooltip => 'Quit game';

  @override
  String get survivalScoreSaved => 'Score saved!';

  @override
  String get survivalTimeUp => 'Time\'s up!';

  @override
  String survivalResultBoardsSolved(int count) {
    return 'Boards solved: $count';
  }

  @override
  String get survivalScoreNotSaved =>
      'Score not saved. Log in to join the ranking.';

  @override
  String get error_invalid_email => 'The email address format is invalid.';
}
