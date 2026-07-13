import 'package:arrow_maze/domain/entities/user.dart';

/// Puerto de almacenamiento local seguro para credenciales sensibles (JWT).
abstract interface class ILocalStorage {
  Future<void> saveToken(String token);
  Future<String?> readToken();
  Future<void> deleteToken();

  Future<void> saveUser(User user);
  Future<User?> readUser();
}
