/// Purga estado en memoria al cerrar sesión (DIP — sin acoplar infra a Riverpod).
abstract interface class ISessionCleanup {
  void clearSessionState();
}
