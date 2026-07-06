/// Puerto de dominio: proveedor de tiempo transcurrido en segundos.
/// La implementación concreta (Stopwatch + Timer) va en infraestructura.
/// PROHIBIDO usar DateTime.now() o Timer en dominio/aplicación.
abstract interface class ITimeService {
  /// Emite el tiempo acumulado en segundos (1, 2, 3, …) mientras está activo.
  Stream<int> get elapsed;
  void start();
  void stop();
  void reset();
}
