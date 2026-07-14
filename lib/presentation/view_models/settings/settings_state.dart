import 'dart:ui' show Locale;

/// Estado de vista inmutable de los ajustes de la app.
///
/// Contiene el idioma seleccionado (impulsa `MaterialApp.locale`) y el reflejo
/// del estado de silencio del `IAudioService` compartido.
class SettingsState {
  /// Idioma activo de la interfaz.
  final Locale locale;

  /// Refleja el estado de silencio del `IAudioService`.
  final bool isMuted;

  const SettingsState({
    required this.locale,
    required this.isMuted,
  });

  SettingsState copyWith({
    Locale? locale,
    bool? isMuted,
  }) {
    return SettingsState(
      locale: locale ?? this.locale,
      isMuted: isMuted ?? this.isMuted,
    );
  }
}
