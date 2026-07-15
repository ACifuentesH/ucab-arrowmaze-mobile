import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:arrow_maze/application/dtos/leaderboard_entry_dto.dart';
import 'package:arrow_maze/application/errors/api_error.dart';
import 'package:arrow_maze/application/ports/i_api_client.dart';
import 'package:arrow_maze/application/proxies/exception_handling_proxy.dart';

import '../mothers/leaderboard_entry_mother.dart';

class _MockApiClient extends Mock implements IApiClient {}

/// Testing API: proxy de manejo de excepciones (decorator AOP). El mock es
/// legítimo: lo observable es CÓMO se propagan/mapean los errores del puerto y
/// cuántas veces se reintenta una llamada. Los reintentos usan `retryDelay`
/// cero para que las pruebas sean instantáneas.
class ExceptionHandlingProxyTestApi {
  final _MockApiClient _delegate = _MockApiClient();
  int _maxAttempts = 1;

  ExceptionHandlingApiClientProxy _buildProxy() =>
      ExceptionHandlingApiClientProxy(
        delegate: _delegate,
        maxAttempts: _maxAttempts,
        retryDelay: Duration.zero,
      );

  List<LeaderboardEntryDto>? _result;

  ExceptionHandlingProxyTestApi givenRetriesAreEnabled(int maxAttempts) {
    _maxAttempts = maxAttempts;
    return this;
  }

  ExceptionHandlingProxyTestApi givenTheDelegateAlwaysThrows(Object error) {
    when(() => _delegate.getLeaderboard(any(), limit: any(named: 'limit')))
        .thenAnswer((_) async => throw error);
    return this;
  }

  ExceptionHandlingProxyTestApi givenTheDelegateThrowsThenSucceeds(
    Object firstError,
  ) {
    var calls = 0;
    when(() => _delegate.getLeaderboard(any(), limit: any(named: 'limit')))
        .thenAnswer((_) async {
      calls++;
      if (calls == 1) throw firstError;
      return [LeaderboardEntryMother.entry()];
    });
    return this;
  }

  Future<void> whenTheLeaderboardIsRequested() async {
    _result = await _buildProxy().getLeaderboard('level_1');
  }

  Future<void> thenItShouldThrowA<T extends ApiError>() async {
    await expectLater(
      _buildProxy().getLeaderboard('level_1'),
      throwsA(isA<T>()),
    );
  }

  void thenTheResultShouldNotBeNull() => expect(_result, isNotNull);

  void thenTheDelegateShouldHaveBeenCalled(int times) =>
      verify(() => _delegate.getLeaderboard(any(), limit: any(named: 'limit')))
          .called(times);
}
