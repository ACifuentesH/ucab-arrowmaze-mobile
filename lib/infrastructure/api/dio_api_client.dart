import 'package:dio/dio.dart';

import 'package:arrow_maze/application/errors/api_error.dart';
import 'package:arrow_maze/application/ports/i_api_client.dart';
import 'package:arrow_maze/application/services/session_expired_notifier.dart';
import 'package:arrow_maze/domain/interfaces/i_local_storage.dart';

/// Adapter Dio de [IApiClient] contra ucab-arrowmaze-api.
///
/// - Interceptor de request: `Content-Type: application/json` + Bearer JWT.
/// - Desempaqueta `{ success, data, message }` y retorna `data`.
/// - Mapea 401/404/409/422/500 → [ApiError]; en 401 borra el token y notifica.
class DioApiClient implements IApiClient {
  final Dio _dio;
  final ILocalStorage _storage;
  final SessionExpiredNotifier _sessionExpired;

  DioApiClient({
    required Dio dio,
    required ILocalStorage storage,
    required SessionExpiredNotifier sessionExpired,
    required String baseUrl,
  })  : _dio = dio,
        _storage = storage,
        _sessionExpired = sessionExpired {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    _dio.interceptors.add(
      _AuthInterceptor(storage: _storage),
    );
  }

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) =>
      _send(() => _dio.get<dynamic>(path, queryParameters: queryParameters));

  @override
  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
  }) =>
      _send(() => _dio.post<dynamic>(path, data: body));

  @override
  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
  }) =>
      _send(() => _dio.put<dynamic>(path, data: body));

  @override
  Future<dynamic> delete(String path) =>
      _send(() => _dio.delete<dynamic>(path));

  Future<dynamic> _send(Future<Response<dynamic>> Function() call) async {
    try {
      final response = await call();
      return await _unwrap(response);
    } on DioException catch (e) {
      throw await _mapDioException(e);
    }
  }

  Future<dynamic> _unwrap(Response<dynamic> response) async {
    final envelope = _asEnvelope(response.data);
    final success = envelope['success'] == true;
    final status = response.statusCode ?? 0;

    if (status >= 200 && status < 300 && success) {
      return envelope['data'];
    }

    print('--- INTERCEPTOR: Error HTTP detectado: $status');
    throw await _statusToError(
      status,
      (envelope['message'] as String?) ?? 'Unexpected API error',
    );
  }

  Future<ApiError> _mapDioException(DioException e) async {
    final response = e.response;
    if (response != null) {
      print(
        '--- INTERCEPTOR: Error HTTP detectado: ${response.statusCode}',
      );
      final envelope = _asEnvelope(response.data);
      final message =
          (envelope['message'] as String?) ?? e.message ?? 'Unexpected API error';
      return _statusToError(response.statusCode ?? 500, message);
    }

    return NetworkError('Transport failure: ${e.message}');
  }

  Map<String, dynamic> _asEnvelope(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    throw const ServerError('Malformed response envelope');
  }

  Future<ApiError> _statusToError(int status, String message) async {
    if (status == 401) {
      await _storage.deleteToken();
      _sessionExpired.notify();
      print('--- INTERCEPTOR: Señal de logout ejecutada');
      return UnauthorizedError(message);
    }
    return switch (status) {
      404 => NotFoundError(message),
      409 => ConflictError(message),
      422 => ValidationError(message),
      _ => ServerError(message),
    };
  }
}

class _AuthInterceptor extends Interceptor {
  final ILocalStorage _storage;

  _AuthInterceptor({required ILocalStorage storage}) : _storage = storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['Content-Type'] = 'application/json';
    final token = await _storage.readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer token_invalido_123';
    }
    handler.next(options);
  }
}
