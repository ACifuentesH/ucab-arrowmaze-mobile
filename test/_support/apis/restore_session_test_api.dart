import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:arrow_maze/application/dtos/auth_user.dart';
import 'package:arrow_maze/application/ports/i_token_storage.dart';
import 'package:arrow_maze/application/use_cases/auth/restore_session_use_case.dart';

import '../fakes/fake_user_storage.dart';

class _MockTokenStorage extends Mock implements ITokenStorage {}

/// Testing API: RestoreSessionUseCase — lee token + usuario persistidos.
/// La interacción con ITokenStorage (clear() tras usuario ausente) ES el
/// comportamiento observable, así que aquí sí usamos mocktail
/// (docs/testing-architecture.md §0.5); IUserStorage usa el fake in-memory.
class RestoreSessionTestApi {
  final _MockTokenStorage _tokenStorage = _MockTokenStorage();
  final FakeUserStorage _userStorage = FakeUserStorage();
  late final RestoreSessionUseCase _useCase = RestoreSessionUseCase(
    tokenStorage: _tokenStorage,
    userStorage: _userStorage,
  );

  AuthUser? _result;

  RestoreSessionTestApi() {
    when(() => _tokenStorage.clear()).thenAnswer((_) async {});
  }

  // ── Given ──────────────────────────────────────────────────────────────

  Future<RestoreSessionTestApi> givenAStoredTokenAndUser({
    String userId = 'u-1',
  }) async {
    when(() => _tokenStorage.read()).thenAnswer((_) async => 'jwt');
    await _userStorage.save(
      AuthUser(id: userId, username: 'alice', email: 'a@b.com'),
    );
    return this;
  }

  RestoreSessionTestApi givenAStoredTokenWithoutAUser() {
    when(() => _tokenStorage.read()).thenAnswer((_) async => 'jwt');
    return this;
  }

  RestoreSessionTestApi givenNoStoredToken() {
    when(() => _tokenStorage.read()).thenAnswer((_) async => null);
    return this;
  }

  // ── When ───────────────────────────────────────────────────────────────

  Future<RestoreSessionTestApi> whenRestoringTheSession() async {
    _result = await _useCase.execute();
    return this;
  }

  // ── Then ───────────────────────────────────────────────────────────────

  void thenSessionShouldBeRestoredFor(String userId) =>
      expect(_result?.id, equals(userId));

  void thenSessionShouldBeNull() => expect(_result, isNull);

  void thenTokenShouldBeCleared() =>
      verify(() => _tokenStorage.clear()).called(1);

  void thenTokenShouldNotBeCleared() =>
      verifyNever(() => _tokenStorage.clear());
}
