/// Estado de un nivel en la pantalla de selección.
enum LevelStatus {
  /// Aún no se completó el nivel anterior de la campaña.
  locked,

  /// Disponible para jugar; todavía sin completar.
  unlocked,

  /// Completado al menos una vez (tiene progreso guardado).
  completed,
}
