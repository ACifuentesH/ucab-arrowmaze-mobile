import 'package:arrow_maze/application/ports/i_auth_repository.dart';
import 'package:arrow_maze/domain/entities/user.dart';

class RegisterUseCase {
  final IAuthRepository _auth;

  const RegisterUseCase({required IAuthRepository auth}) : _auth = auth;

  Future<User> execute({
    required String username,
    required String email,
    required String password,
  }) {
    return _auth.register(
      username: username.trim(),
      email: email.trim(),
      password: password,
    );
  }
}
