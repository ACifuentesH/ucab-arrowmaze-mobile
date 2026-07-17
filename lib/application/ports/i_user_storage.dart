import 'package:arrow_maze/application/dtos/auth_user.dart';

/// Persistencia del usuario autenticado (complementa el JWT en [ITokenStorage]).
abstract interface class IUserStorage {
  Future<void> save(AuthUser user);
  Future<AuthUser?> read();
  Future<void> clear();
}
