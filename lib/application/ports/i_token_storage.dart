/// Puerto de persistencia del JWT de sesión.
/// Implementación en infrastructure (SharedPreferences).
abstract interface class ITokenStorage {
  Future<String?> read();
  Future<void> save(String token);
  Future<void> clear();
}
