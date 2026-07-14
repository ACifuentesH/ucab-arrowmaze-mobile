import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arrow_maze/application/ports/i_audio_service.dart';
import 'package:arrow_maze/presentation/view_models/settings/settings_state.dart';

/// ViewModel de ajustes (MVVM): expone el idioma y el silencio como estado
/// observable y traduce las intenciones de la UI en operaciones de dominio.
///
/// Reutiliza el puerto [IAudioService] existente para el mute (no crea una
/// nueva abstracción de audio) y guarda el [Locale] elegido, que la
/// `MaterialApp` observa para relocalizar toda la app.
class SettingsViewModel extends StateNotifier<SettingsState> {
  final IAudioService _audio;

  /// Idioma por defecto de la app: español (idioma original del proyecto).
  static const Locale defaultLocale = Locale('es');

  SettingsViewModel({
    required IAudioService audioService,
    Locale initialLocale = defaultLocale,
  })  : _audio = audioService,
        super(SettingsState(
          locale: initialLocale,
          isMuted: audioService.isMuted,
        ));

  /// Alterna el silencio a través del puerto de audio compartido y refleja el
  /// nuevo estado en la vista.
  void toggleMute() {
    _audio.toggleMute();
    state = state.copyWith(isMuted: _audio.isMuted);
  }

  /// Cambia el idioma de la interfaz. Idempotente si ya es el idioma actual.
  void setLocale(Locale locale) {
    if (locale.languageCode == state.locale.languageCode) return;
    state = state.copyWith(locale: locale);
  }
}
