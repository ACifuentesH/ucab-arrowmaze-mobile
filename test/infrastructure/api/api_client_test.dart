import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:arrow_maze/application/errors/api_error.dart';
import 'package:arrow_maze/application/ports/i_api_client.dart';
import 'package:arrow_maze/application/services/session_expired_notifier.dart';
import 'package:arrow_maze/domain/interfaces/i_local_storage.dart';
import 'package:arrow_maze/infrastructure/api/dio_api_client.dart';

import '../../_support/mothers/api_response_mother.dart';
import '../../_support/network/api_client_test_base.dart';

class MockLocalStorage extends Mock implements ILocalStorage {}

/// Pruebas de caja negra sobre [IApiClient] — solo entradas y salidas públicas.
void main() {
  late MockLocalStorage storage;
  late SessionExpiredNotifier sessionExpired;
  late IApiClient client;

  setUpAll(() {
    expect(networkTestBaseVersion, 1);
  });

  setUp(() {
    storage = MockLocalStorage();
    sessionExpired = SessionExpiredNotifier();
    when(() => storage.readToken()).thenAnswer((_) async => null);
    when(() => storage.deleteToken()).thenAnswer((_) async {});
  });

  IApiClient buildClient({
    required int status,
    required Map<String, dynamic> envelope,
  }) {
    return DioApiClient(
      dio: _dioWithEnvelope(status: status, envelope: envelope),
      storage: storage,
      sessionExpired: sessionExpired,
      baseUrl: 'http://localhost:3000',
    );
  }

  group('IApiClient — envelope contract', () {
    test('should_return_only_data_when_response_is_200_and_success_is_true',
        () async {
      client = buildClient(
        status: 200,
        envelope: ApiResponseMother.loginSuccess(),
      );

      final result = await client.post('/auth/login', body: {
        'email': 'alice@example.com',
        'password': 'password123',
      });

      expect(result, isA<Map<String, dynamic>>());
      final data = result as Map<String, dynamic>;
      expect(data.containsKey('user'), isTrue);
      expect(data.containsKey('token'), isTrue);
      expect(data['token'], 'jwt-login');
      expect(data.containsKey('success'), isFalse);
      expect(data.containsKey('message'), isFalse);
    });
  });

  group('IApiClient — unauthorized handling', () {
    test('should_clear_local_storage_when_http_status_is_401', () async {
      var sessionExpiredFired = false;
      sessionExpired.onSessionExpired = () => sessionExpiredFired = true;

      client = buildClient(
        status: 401,
        envelope: ApiResponseMother.error('Invalid credentials'),
      );

      await expectLater(
        client.post('/auth/login', body: {
          'email': 'alice@example.com',
          'password': 'wrong',
        }),
        throwsA(isA<UnauthorizedError>()),
      );

      verify(() => storage.deleteToken()).called(1);
      expect(sessionExpiredFired, isTrue);
    });
  });
}

Dio _dioWithEnvelope({
  required int status,
  required Map<String, dynamic> envelope,
}) {
  final dio = Dio();
  dio.httpClientAdapter = _StubEnvelopeAdapter(
    status: status,
    envelope: envelope,
  );
  return dio;
}

class _StubEnvelopeAdapter implements HttpClientAdapter {
  _StubEnvelopeAdapter({required this.status, required this.envelope});

  final int status;
  final Map<String, dynamic> envelope;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(envelope),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
