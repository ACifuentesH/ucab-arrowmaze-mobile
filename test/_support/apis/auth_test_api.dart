import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:arrow_maze/application/errors/api_error.dart';
import 'package:arrow_maze/application/ports/i_auth_repository.dart';
import 'package:arrow_maze/application/use_cases/auth/login_use_case.dart';
import 'package:arrow_maze/application/use_cases/auth/logout_use_case.dart';
import 'package:arrow_maze/application/use_cases/auth/register_use_case.dart';

import '../mothers/user_mother.dart';

class _MockAuthRepository extends Mock implements IAuthRepository {}

/// Testing API: autenticación contra [IAuthRepository].
class AuthTestApi {
  final _MockAuthRepository _auth = _MockAuthRepository();
  Object? _user;
  Object? _error;

  AuthTestApi givenAuthAcceptsCredentials() {
    when(() => _auth.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => UserMother.alice());
    when(() => _auth.register(
          username: any(named: 'username'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => UserMother.alice());
    return this;
  }

  AuthTestApi givenAuthRejectsCredentials() {
    when(() => _auth.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(const UnauthorizedError('Invalid credentials'));
    return this;
  }

  AuthTestApi givenEmailIsAlreadyRegistered() {
    when(() => _auth.register(
          username: any(named: 'username'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(const ConflictError('Email already registered'));
    return this;
  }

  AuthTestApi givenALocalSessionExists() {
    when(() => _auth.logout()).thenAnswer((_) async {});
    return this;
  }

  Future<AuthTestApi> whenLoggingIn() async {
    try {
      _user = await LoginUseCase(auth: _auth)
          .execute(email: 'alice@example.com', password: 'password123');
    } catch (e) {
      _error = e;
    }
    return this;
  }

  Future<AuthTestApi> whenRegistering() async {
    try {
      _user = await RegisterUseCase(auth: _auth).execute(
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
    await LogoutUseCase(auth: _auth).execute();
    return this;
  }

  void thenUserShouldBeActiveWithId(String userId) {
    expect(_error, isNull);
    expect((_user as dynamic).id, equals(userId));
  }

  void thenAuthShouldFailWith<T>() => expect(_error, isA<T>());

  void thenSessionShouldBeClosed() => verify(() => _auth.logout()).called(1);
}
