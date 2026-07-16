// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Arrow Escape';

  @override
  String get homeTagline => 'Despeja el tablero. Sobrevive.';

  @override
  String get playButton => 'JUGAR';

  @override
  String get aiLevelBuilderButton => 'CREAR NIVEL CON IA';

  @override
  String get survivalModeButton => 'MODO SUPERVIVENCIA';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsTooltip => 'Ajustes';

  @override
  String get settingsSoundSection => 'Sonido';

  @override
  String get settingsMuteLabel => 'Silenciar sonido';

  @override
  String get settingsLanguageSection => 'Idioma';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get undoTooltip => 'Deshacer';

  @override
  String get restartTooltip => 'Reiniciar';

  @override
  String get muteTooltip => 'Silenciar';

  @override
  String get unmuteTooltip => 'Activar sonido';

  @override
  String get victoryTitle => '¡Nivel completado!';

  @override
  String get victorySubtitleDefault => 'Todas las flechas escaparon.';

  @override
  String victoryScore(int score) {
    return 'Puntuación: $score';
  }

  @override
  String get newRecord => '¡Nuevo récord!';

  @override
  String get nextLevelButton => 'Siguiente nivel';

  @override
  String get levelsButton => 'Niveles';

  @override
  String get gameOverTitle => 'Game Over';

  @override
  String get gameOverSubtitle => 'Sin vidas. ¡Inténtalo de nuevo!';

  @override
  String get retryButton => 'Reintentar';

  @override
  String get homeButton => 'Inicio';

  @override
  String get levelsTitle => 'Niveles';

  @override
  String get campaignSection => 'Campaña';

  @override
  String get aiGeneratedSection => 'Generados con IA';

  @override
  String levelMeta(int count, String difficulty) {
    return '$count flechas · $difficulty';
  }

  @override
  String get accountTooltip => 'Cuenta';

  @override
  String get loginButton => 'Login';

  @override
  String get logoutButton => 'CERRAR SESIÓN';

  @override
  String accountGreeting(String username) {
    return 'Hola, $username';
  }

  @override
  String get loginPromptTitle => '¿Quieres guardar tu progreso?';

  @override
  String get loginPromptSubtitle =>
      'Inicia sesión o crea una cuenta para sincronizar tus niveles y puntuaciones. También puedes seguir sin cuenta.';

  @override
  String get loginPromptLoginButton => 'Iniciar sesión';

  @override
  String get loginPromptRegisterButton => 'Crear cuenta';

  @override
  String get loginPromptGuestButton => 'Continuar como invitado';

  @override
  String get error_invalid_email =>
      'El formato del correo electrónico no es válido.';
}
