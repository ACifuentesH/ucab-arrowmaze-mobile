import 'package:arrow_maze/domain/entities/user.dart';

/// Estado de sesión global observable por la UI y el router.
enum AuthStatus {
  unauthenticated,
  authenticated,
  loading,
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.user,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;

  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  factory AuthState.unauthenticated({String? errorMessage}) => AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: errorMessage,
      );

  factory AuthState.authenticated(User user) => AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );

  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);
}
