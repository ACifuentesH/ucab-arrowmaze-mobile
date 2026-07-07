import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:arrow_maze/application/dtos/auth_session.dart';
import 'package:arrow_maze/application/errors/api_error.dart';
import 'package:arrow_maze/application/ports/i_api_client.dart';
import 'package:arrow_maze/application/use_cases/auth/login_use_case.dart';
import 'package:arrow_maze/application/use_cases/auth/logout_use_case.dart';
import 'package:arrow_maze/application/use_cases/auth/register_use_case.dart';

import '../mothers/auth_session_mother.dart';

class _MockApiClient extends Mock implements IApiClient {}

/// Testing API: autenticación (login / register / logout) contra IApiClient.
/// La llamada al servicio externo ES el comportamiento observable, así que
/// aquí sí usamos mocktail (docs/testing-architecture.md §0.5).
class AuthTestApi {
  final _MockApiClient _api = _MockApiClient();
  AuthSession? _session;
  Object? _error;

  // ── Given ──────────────────────────────────────────────────────────────────

  AuthTestApi givenApiAcceptsCredentials() {
    when(() => _api.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => AuthSessionMother.active());
    when(() => _api.register(
          username: any(named: 'username'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => AuthSessionMother.active());
    return this;
  }

  AuthTestApi givenApiRejectsCredentials() {
    when(() => _api.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(const UnauthorizedError('Invalid credentials'));
    return this;
  }

  AuthTestApi givenEmailIsAlreadyRegistered() {
    when(() => _api.register(
          username: any(named: 'username'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(const ConflictError('Email already registered'));
    return this;
  }

  AuthTestApi givenALocalSessionExists() {
    when(() => _api.logout()).thenAnswer((_) async {});
    return this;
  }

  // ── When ───────────────────────────────────────────────────────────────────

  Future<AuthTestApi> whenLoggingIn() async {
    try {
      _session = await LoginUseCase(api: _api)
          .execute(email: 'alice@example.com', password: 'password123');
    } catch (e) {
      _error = e;
    }
    return this;
  }

  Future<AuthTestApi> whenRegistering() async {
    try {
      _session = await RegisterUseCase(api: _api).execute(
        username: 'alice',
        email: 'alice@example.com',
        password: 'password123',
      );
    } catch (e) {
      _error = e;
    }
    return this;
  }

  Future<AuthTestApi> whenLoggingOut() async {
    await LogoutUseCase(api: _api).execute();
    return this;
  }

  // ── Then ───────────────────────────────────────────────────────────────────

  void thenSessionShouldBeActiveFor(String userId) {
    expect(_error, isNull);
    expect(_session!.user.id, equals(userId));
    expect(_session!.token, isNotEmpty);
  }

  void thenAuthShouldFailWith<T>() => expect(_error, isA<T>());

  void thenSessionShouldBeClosed() => verify(() => _api.logout()).called(1);
}
