/// Señal de sesión expirada (401) desacoplada de Riverpod e infraestructura.
///
/// [DioApiClient] invoca [notify] al detectar un 401; la capa de presentación
/// registra un listener para forzar logout en la UI.
class SessionExpiredNotifier {
  void Function()? onSessionExpired;

  void notify() => onSessionExpired?.call();
}
