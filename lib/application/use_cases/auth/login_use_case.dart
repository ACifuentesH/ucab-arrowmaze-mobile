import 'package:arrow_maze/application/ports/i_auth_repository.dart';
import 'package:arrow_maze/domain/entities/user.dart';

/// Orquesta el login contra [IAuthRepository].
class LoginUseCase {
  final IAuthRepository _auth;

  const LoginUseCase({required IAuthRepository auth}) : _auth = auth;

  Future<User> execute({
    required String email,
    required String password,
  }) {
    return _auth.login(email: email.trim(), password: password);
  }
}
