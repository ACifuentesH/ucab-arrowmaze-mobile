/// Puerto de almacenamiento local seguro para credenciales sensibles (JWT).
abstract interface class ILocalStorage {
  Future<void> saveToken(String token);
  Future<String?> readToken();
  Future<void> deleteToken();
}
