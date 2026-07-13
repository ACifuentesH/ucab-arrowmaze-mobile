/// Usuario autenticado — contrato público de dominio.
///
/// Solo expone `{ id, username, email }`. Cualquier otro campo del backend
/// se descarta en [fromJson].
class User {
  final String id;
  final String username;
  final String email;

  const User({
    required this.id,
    required this.username,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: (json['id'] ?? json['userId']) as String,
        username: json['username'] as String,
        email: json['email'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          id == other.id &&
          username == other.username &&
          email == other.email;

  @override
  int get hashCode => Object.hash(id, username, email);
}
