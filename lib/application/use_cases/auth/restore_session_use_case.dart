import 'package:arrow_maze/application/dtos/auth_user.dart';
import 'package:arrow_maze/application/ports/i_token_storage.dart';
import 'package:arrow_maze/application/ports/i_user_storage.dart';

/// Restaura la sesión local leyendo JWT y usuario persistidos.
class RestoreSessionUseCase {
  final ITokenStorage _tokenStorage;
  final IUserStorage _userStorage;

  const RestoreSessionUseCase({
    required ITokenStorage tokenStorage,
    required IUserStorage userStorage,
  })  : _tokenStorage = tokenStorage,
        _userStorage = userStorage;

  Future<AuthUser?> execute() async {
    final token = await _tokenStorage.read();
    if (token == null || token.isEmpty) return null;

    final user = await _userStorage.read();
    if (user == null) {
      await _tokenStorage.clear();
      return null;
    }

    return user;
  }
}
