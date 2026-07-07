import 'package:arrow_maze/application/dtos/auth_session.dart';
import 'package:arrow_maze/application/dtos/auth_user.dart';

/// Object Mother: sesiones autenticadas en la forma interna normalizada.
class AuthSessionMother {
  static AuthSession active({
    String id = 'u-1',
    String username = 'alice',
    String token = 'jwt-token',
  }) =>
      AuthSession(
        user: AuthUser(
          id: id,
          username: username,
          email: '$username@example.com',
        ),
        token: token,
      );
}
