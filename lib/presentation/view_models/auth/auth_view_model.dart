import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arrow_maze/application/dtos/auth_user.dart';
import 'package:arrow_maze/application/errors/api_error.dart';
import 'package:arrow_maze/application/use_cases/auth/login_use_case.dart';
import 'package:arrow_maze/application/use_cases/auth/logout_use_case.dart';
import 'package:arrow_maze/application/use_cases/auth/register_use_case.dart';

/// STUB — feature/auth (compañera): estado de sesión para las vistas.
class AuthState {
  final AuthUser? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({this.user, this.isLoading = false, this.errorMessage});

  bool get isAuthenticated => user != null;
}

/// STUB — feature/auth (compañera).
/// Implementar: login(), register(), logout(), manejo de ApiError
/// (UnauthorizedError → sesión expirada, ConflictError → duplicados,
/// ValidationError → errores de formulario).
class AuthViewModel extends StateNotifier<AuthState> {
  final LoginUseCase _login;
  // ignore: unused_field
  final RegisterUseCase _register;
  // ignore: unused_field
  final LogoutUseCase _logout;

  AuthViewModel({
    required LoginUseCase login,
    required RegisterUseCase register,
    required LogoutUseCase logout,
  })  : _login = login,
        _register = register,
        _logout = logout,
        super(const AuthState());

  Future<void> login(String email, String password) async {
    state = const AuthState(isLoading: true);

    try {
      final session = await _login.execute(
        email: email.trim(),
        password: password,
      );
      state = AuthState(user: session.user);
    } on ApiError catch (e) {
      state = AuthState(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = AuthState(isLoading: false, errorMessage: e.toString());
    }
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = AuthState(user: state.user, isLoading: state.isLoading);
    }
  }

  // TODO(feature/auth): Future<void> register(...)
  // TODO(feature/auth): Future<void> logout()
}
