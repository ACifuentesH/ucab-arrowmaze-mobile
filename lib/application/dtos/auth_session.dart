import 'package:arrow_maze/application/dtos/auth_user.dart';

/// Resultado de register/login: usuario normalizado + JWT.
class AuthSession {
  final AuthUser user;
  final String token;

  const AuthSession({required this.user, required this.token});
}
