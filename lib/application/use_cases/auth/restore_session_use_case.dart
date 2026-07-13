import 'package:arrow_maze/application/ports/i_auth_repository.dart';
import 'package:arrow_maze/domain/entities/user.dart';

/// Restaura la sesión local leyendo JWT y usuario del almacenamiento seguro.
class RestoreSessionUseCase {
  final IAuthRepository _auth;

  const RestoreSessionUseCase({required IAuthRepository auth}) : _auth = auth;

  Future<User?> execute() => _auth.restoreSession();
}
