import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:arrow_maze/application/errors/api_error.dart';
import 'package:arrow_maze/application/ports/i_api_client.dart';
import 'package:arrow_maze/domain/entities/user.dart';
import 'package:arrow_maze/domain/interfaces/i_local_storage.dart';
import 'package:arrow_maze/infrastructure/repositories/auth_repository_impl.dart';

import '../../_support/mothers/api_response_mother.dart';

class MockApiClient extends Mock implements IApiClient {}

class MockLocalStorage extends Mock implements ILocalStorage {}

/// Pruebas de caja negra sobre [AuthRepositoryImpl].
void main() {
  group('AuthRepositoryImpl', () {
    late MockApiClient api;
    late MockLocalStorage storage;
    late AuthRepositoryImpl repository;

    setUp(() {
      api = MockApiClient();
      storage = MockLocalStorage();
      repository = AuthRepositoryImpl(api: api, storage: storage);
      when(() => storage.saveToken(any())).thenAnswer((_) async {});
      when(() => storage.deleteToken()).thenAnswer((_) async {});
    });

    test(
        'should_return_user_with_public_fields_and_persist_token_when_login_succeeds',
        () async {
      when(() => api.post('/auth/login', body: any(named: 'body'))).thenAnswer(
        (_) async => ApiResponseMother.loginSuccess()['data'],
      );

      final user = await repository.login(
        email: 'alice@example.com',
        password: 'password123',
      );

      expect(user, isA<User>());
      expect(user.id, 'u-1');
      expect(user.username, 'alice');
      expect(user.email, 'alice@example.com');
      verify(() => storage.saveToken('jwt-login')).called(1);
    });

    test(
        'should_return_user_with_public_fields_and_persist_token_when_register_succeeds',
        () async {
      when(() => api.post('/auth/register', body: any(named: 'body')))
          .thenAnswer(
        (_) async => ApiResponseMother.registerSuccess()['data'],
      );

      final user = await repository.register(
        username: 'alice',
        email: 'alice@example.com',
        password: 'password123',
      );

      expect(user.id, 'u-1');
      expect(user.username, 'alice');
      expect(user.email, 'alice@example.com');
      verify(() => storage.saveToken('jwt-register')).called(1);
    });

    test('should_clear_local_storage_when_logout_is_called', () async {
      await repository.logout();

      verify(() => storage.deleteToken()).called(1);
    });

    test('should_propagate_api_error_when_login_fails', () async {
      when(() => api.post('/auth/login', body: any(named: 'body')))
          .thenThrow(const UnauthorizedError('Invalid credentials'));

      await expectLater(
        repository.login(
          email: 'alice@example.com',
          password: 'wrong',
        ),
        throwsA(isA<UnauthorizedError>()),
      );

      verifyNever(() => storage.saveToken(any()));
    });

    test('should_propagate_conflict_when_register_fails', () async {
      when(() => api.post('/auth/register', body: any(named: 'body')))
          .thenThrow(const ConflictError('Email already registered'));

      await expectLater(
        repository.register(
          username: 'alice',
          email: 'alice@example.com',
          password: 'password123',
        ),
        throwsA(isA<ConflictError>()),
      );

      verifyNever(() => storage.saveToken(any()));
    });
  });
}
