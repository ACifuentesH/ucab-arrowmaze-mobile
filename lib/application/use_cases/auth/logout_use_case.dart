import 'package:arrow_maze/application/ports/i_auth_repository.dart';

class LogoutUseCase {
  final IAuthRepository _auth;

  const LogoutUseCase({required IAuthRepository auth}) : _auth = auth;

  Future<void> execute() => _auth.logout();
}
