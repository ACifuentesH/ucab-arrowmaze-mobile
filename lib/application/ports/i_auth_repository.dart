import 'package:arrow_maze/domain/entities/user.dart';

/// Puerto de autenticación — orquesta API remota y persistencia del JWT.
abstract interface class IAuthRepository {
  Future<User> login({
    required String email,
    required String password,
  });

  Future<User> register({
    required String username,
    required String email,
    required String password,
  });

  Future<void> logout();
}
