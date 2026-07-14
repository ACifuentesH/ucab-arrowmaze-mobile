import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/application/ports/i_api_client.dart';
import 'package:arrow_maze/application/services/session_expired_notifier.dart';
import 'package:arrow_maze/infrastructure/api/dio_api_client.dart';

import '../fakes/fake_local_storage.dart';

/// Testing API: [IApiClient] contra respuestas JSON simuladas.
/// Solo verifica contrato de entrada/salida — sin detalles de implementación.
class DioApiClientTestApi {
  static const _baseUrl = 'http://localhost:3000';

  final FakeLocalStorage _storage = FakeLocalStorage();
  final SessionExpiredNotifier _sessionExpired = SessionExpiredNotifier();
  bool _sessionExpiredFired = false;

  int _status = 200;
  Map<String, dynamic> _envelope = const {};
  Object? _result;
  Object? _error;

  late final IApiClient _client = DioApiClient(
    dio: _buildDio(),
    storage: _storage,
    sessionExpired: _sessionExpired,
    baseUrl: _baseUrl,
  );

  DioApiClientTestApi() {
    _sessionExpired.onSessionExpired = () => _sessionExpiredFired = true;
  }

  Dio _buildDio() {
    final dio = Dio();
    dio.httpClientAdapter = _StubAdapter(
      onFetch: (options) {
        return ResponseBody.fromString(
          jsonEncode(_envelope),
          _status,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      },
    );
    return dio;
  }

  // ── Given ──────────────────────────────────────────────────────────────────

  DioApiClientTestApi givenServerResponds(
    int status,
    Map<String, dynamic> envelope,
  ) {
    _status = status;
    _envelope = envelope;
    return this;
  }

  DioApiClientTestApi givenAStoredToken([String token = 'stored-jwt']) {
    _storage.token = token;
    return this;
  }

  // ── When ───────────────────────────────────────────────────────────────────

  Future<DioApiClientTestApi> whenPostingLogin() => _capture(
        () => _client.post('/auth/login', body: {
          'email': 'alice@example.com',
          'password': 'password123',
        }),
      );

  Future<DioApiClientTestApi> whenPostingRegister() => _capture(
        () => _client.post('/auth/register', body: {
          'username': 'alice',
          'email': 'alice@example.com',
          'password': 'password123',
        }),
      );

  Future<DioApiClientTestApi> whenGettingProgress() =>
      _capture(() => _client.get('/progress'));

  Future<DioApiClientTestApi> whenGettingLeaderboard() => _capture(
        () => _client.get('/leaderboard/level_1', queryParameters: {'limit': 10}),
      );

  Future<DioApiClientTestApi> _capture(Future<Object?> Function() call) async {
    try {
      _result = await call();
    } catch (e) {
      _error = e;
    }
    return this;
  }

  // ── Then (solo contrato observable) ────────────────────────────────────────

  void thenDataShouldContainUserId(String id) {
    expect(_error, isNull);
    final data = _result as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>;
    expect(user['id'] ?? user['userId'], equals(id));
  }

  void thenDataShouldContainToken(String token) {
    final data = _result as Map<String, dynamic>;
    expect(data['token'], equals(token));
  }

  void thenProgressUserIdShouldBe(String userId) {
    final data = _result as Map<String, dynamic>;
    expect(data['userId'], equals(userId));
  }

  void thenLeaderboardShouldHaveEntries(int count) {
    final data = _result as List<dynamic>;
    expect(data, hasLength(count));
  }

  void thenErrorShouldBe<T>() => expect(_error, isA<T>());

  void thenNoErrorShouldOccur() => expect(_error, isNull);

  void thenStoredTokenShouldBe(String? token) => expect(_storage.token, token);

  void thenSessionExpiredShouldBeSignaled() =>
      expect(_sessionExpiredFired, isTrue);
}

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter({required this.onFetch});

  final ResponseBody Function(RequestOptions options) onFetch;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      onFetch(options);
}
