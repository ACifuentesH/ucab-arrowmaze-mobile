/// Usuario autenticado en forma interna ÚNICA.
///
/// El backend devuelve `user.id` en register y `user.userId` en login;
/// [AuthUser.fromJson] normaliza ambas formas a [id].
class AuthUser {
  final String id;
  final String username;
  final String email;

  const AuthUser({
    required this.id,
    required this.username,
    required this.email,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: (json['id'] ?? json['userId']) as String,
        username: json['username'] as String,
        email: json['email'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
      };
}
