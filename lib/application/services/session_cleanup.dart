/// Purga estado de presentación al cerrar sesión (DIP — sin acoplar auth a Riverpod).
abstract interface class ISessionCleanup {
  /// Invalida ViewModels en memoria para que la UI refleje progreso vacío (invitado).
  void clearSessionState();
}
