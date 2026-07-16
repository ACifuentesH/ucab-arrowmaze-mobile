import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:arrow_maze/application/builders/level_definition.dart';
import 'package:arrow_maze/application/dtos/auth_session.dart';
import 'package:arrow_maze/application/dtos/auth_user.dart';
import 'package:arrow_maze/application/dtos/leaderboard_entry_dto.dart';
import 'package:arrow_maze/application/dtos/level_spec.dart';
import 'package:arrow_maze/application/dtos/player_progress_dto.dart';
import 'package:arrow_maze/application/dtos/progress_update.dart';
import 'package:arrow_maze/application/dtos/survival_entry_dto.dart';
import 'package:arrow_maze/application/errors/api_error.dart';
import 'package:arrow_maze/application/ports/i_api_client.dart';
import 'package:arrow_maze/application/ports/i_token_storage.dart';

/// Adapter HTTP de [IApiClient] contra ucab-arrowmaze-api.
///
/// Responsabilidades:
///  - Construir URLs de /auth, /progress, /leaderboard/:levelId, /levels.
///  - Desempaquetar el envelope `{ success, data, message }`.
///  - Adjuntar `Authorization: Bearer <token>` solo en rutas protegidas.
///  - Mapear 401/404/409/400|422/500 → ApiError tipado.
///  - Guardar el token vía [ITokenStorage] tras register/login.
class HttpApiClient implements IApiClient {
  final http.Client _http;
  final ITokenStorage _tokenStorage;
  final Uri _base;

  HttpApiClient({
    required http.Client httpClient,
    required ITokenStorage tokenStorage,
    required String baseUrl,
  })  : _http = httpClient,
        _tokenStorage = tokenStorage,
        _base = Uri.parse(baseUrl);

  // ── Auth ──────────────────────────────────────────────────────────────────

  @override
  Future<AuthSession> register({
    required String username,
    required String email,
    required String password,
  }) =>
      _authenticate('/auth/register', {
        'username': username,
        'email': email,
        'password': password,
      });

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) =>
      _authenticate('/auth/login', {
        'email': email,
        'password': password,
      });

  Future<AuthSession> _authenticate(
    String path,
    Map<String, dynamic> body,
  ) async {
    final data = await _request('POST', path, body: body)
        as Map<String, dynamic>;
    final session = AuthSession(
      // AuthUser.fromJson normaliza user.id (register) vs user.userId (login).
      user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
      token: data['token'] as String,
    );
    await _tokenStorage.save(session.token);
    return session;
  }

  @override
  Future<void> logout() => _tokenStorage.clear();

  // ── Progress (JWT) ────────────────────────────────────────────────────────

  @override
  Future<PlayerProgressDto> getProgress() async {
    final data = await _request('GET', '/progress', authenticated: true);
    return PlayerProgressDto.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<PlayerProgressDto> putProgress(ProgressUpdate update) async {
    final data = await _request(
      'PUT',
      '/progress',
      body: update.toJson(),
      authenticated: true,
    );
    return PlayerProgressDto.fromJson(data as Map<String, dynamic>);
  }

  // ── Leaderboard ───────────────────────────────────────────────────────────

  @override
  Future<List<LeaderboardEntryDto>> getLeaderboard(
    String levelId, {
    int limit = 10,
  }) async {
    final data = await _request(
      'GET',
      '/leaderboard/$levelId',
      query: {'limit': '$limit'},
    );
    return (data as List<dynamic>)
        .map((e) => LeaderboardEntryDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Levels ────────────────────────────────────────────────────────────────

  @override
  Future<List<LevelDefinition>> getLevels() async {
    final data = await _request('GET', '/levels');
    return (data as List<dynamic>)
        .map((e) => LevelDefinition.fromBackendJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<LevelDefinition> getLevelById(String id) async {
    final data = await _request('GET', '/levels/$id');
    return LevelDefinition.fromBackendJson(data as Map<String, dynamic>);
  }

  // ── Survival ──────────────────────────────────────────────────────────────

  @override
  Future<void> submitSurvival(Map<String, dynamic> body) async {
    await _request(
      'POST',
      '/survival',
      body: body,
      authenticated: true,
    );
  }

  @override
  Future<List<SurvivalEntryDto>> getSurvivalLeaderboard({
    required int durationSeconds,
    int limit = 10,
  }) async {
    final data = await _request(
      'GET',
      '/survival/leaderboard',
      query: {
        'durationSeconds': '$durationSeconds',
        'limit': '$limit',
      },
    );
    return (data as List<dynamic>)
        .map((e) => SurvivalEntryDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Generación de niveles con IA ─────────────────────────────────────────

  @override
  Future<LevelDefinition> generateLevel(LevelSpec spec) async {
    final data = await _request(
      'POST',
      '/levels/generate',
      body: {
        'prompt': _buildGeneratePrompt(spec),
        'difficulty': spec.difficulty.name,
      },
      authenticated: true,
    ) as Map<String, dynamic>;

    // El backend sólo devuelve el blob { cells, arrows, lives?,
    // timeLimitSeconds? } (no persiste, no hay id/name propios): el resto del
    // contrato lo completa el cliente a partir del spec, igual que antes.
    // "arrows" del LLM se ignora — GenerateLevelUseCase las reemplaza con
    // ProceduralArrowPlacer (determinista, sin solapes, sin depender del
    // modelo); solo importa "cells" (la silueta).
    return LevelDefinition.fromJson({
      'id': 'generated_${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}',
      'name': spec.shapeName,
      'lives': spec.lives,
      'difficulty': spec.difficulty.name,
      if (spec.timeLimitSeconds != null)
        'timeLimitSeconds': spec.timeLimitSeconds,
      'cells': _normalizeCells(data['cells'] as List<dynamic>),
      'arrows': data['arrows'],
    });
  }

  /// El modelo dibuja la silueta en cualquier esquina del grid que se le pidió
  /// (nunca necesariamente desde (0,0)); BoardView centra el bounding box
  /// completo (boundingRows × boundingCols), así que si no se recorta el
  /// margen sobrante el tablero visible sale descentrado y cambia de lugar en
  /// cada generación. Se traslada la forma para que su propio bounding box
  /// empiece en (0,0) — mismo tablero, ahora con el margen quitado.
  List<List<int>> _normalizeCells(List<dynamic> raw) {
    final cells = raw
        .map((e) => [(e as List<dynamic>)[0] as int, e[1] as int])
        .toList();
    if (cells.isEmpty) return cells;

    final minRow = cells.map((c) => c[0]).reduce((a, b) => a < b ? a : b);
    final minCol = cells.map((c) => c[1]).reduce((a, b) => a < b ? a : b);
    if (minRow == 0 && minCol == 0) return cells;

    return cells.map((c) => [c[0] - minRow, c[1] - minCol]).toList();
  }

  // El backend valida prompt.length <= 500 (zod), así que este texto tiene
  // que entrar holgado incluso con nombres de forma largos. Las flechas que
  // pida el modelo se descartan (ver arriba) — el prompt no les pide nada
  // salvo lo mínimo para pasar la validación del backend, dejando todo el
  // esfuerzo del modelo enfocado en la silueta.
  String _buildGeneratePrompt(LevelSpec spec) {
    final n = spec.gridSize;
    return 'A level shaped like: ${spec.shapeName}. Focus entirely on the '
        'silhouette: large, bold, clearly recognizable as '
        '"${spec.shapeName}", filling at least 60% of a ${n}x$n grid '
        '(row 0=top, col 0=left). Include 1-2 short arrows anywhere valid — '
        'their placement does not matter, they will be discarded.';
  }

  // ── Núcleo HTTP ───────────────────────────────────────────────────────────

  Future<Object?> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool authenticated = false,
  }) async {
    final uri = _base.replace(
      path: '${_base.path}$path',
      queryParameters: query,
    );

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (authenticated) 'Authorization': 'Bearer ${await _requireToken()}',
    };

    late final http.Response response;
    try {
      response = switch (method) {
        'GET' => await _http.get(uri, headers: headers),
        'POST' =>
          await _http.post(uri, headers: headers, body: jsonEncode(body)),
        'PUT' =>
          await _http.put(uri, headers: headers, body: jsonEncode(body)),
        _ => throw ArgumentError('Unsupported HTTP method: $method'),
      };
    } on http.ClientException catch (e) {
      throw NetworkError('Transport failure: ${e.message}');
    }

    return _unwrap(response);
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.read();
    if (token == null || token.isEmpty) {
      throw const UnauthorizedError('No stored session token');
    }
    return token;
  }

  /// Desempaqueta `{ success, data, message }` o lanza el ApiError apropiado.
  Object? _unwrap(http.Response response) {
    final Map<String, dynamic> envelope;
    try {
      envelope = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw ServerError(
          'Malformed response (HTTP ${response.statusCode})');
    }

    final success = envelope['success'] == true;
    if (response.statusCode >= 200 && response.statusCode < 300 && success) {
      return envelope['data'];
    }

    final message = _envelopeMessage(envelope);
    throw switch (response.statusCode) {
      401 => UnauthorizedError(message),
      404 => NotFoundError(message),
      409 => ConflictError(message),
      400 || 422 => ValidationError(_validationCode(envelope, message)),
      _ => ServerError(message),
    };
  }

  /// Extrae un texto de mensaje usable del envelope (string, lista, etc.).
  String _envelopeMessage(Map<String, dynamic> envelope) {
    final raw = envelope['message'];
    if (raw is String && raw.isNotEmpty) return raw;
    if (raw is List && raw.isNotEmpty) {
      return raw.map((e) => '$e').join('; ');
    }
    return 'Unexpected API error';
  }

  /// Normaliza errores de validación a códigos cortos de aplicación.
  ///
  /// El backend puede devolver `details`/`errors` con paths, regexes y
  /// mensajes largos; la UI nunca debe ver ese JSON crudo.
  String _validationCode(Map<String, dynamic> envelope, String fallback) {
    final details = envelope['details'] ?? envelope['errors'];
    if (details is List) {
      for (final item in details) {
        if (item is Map && _looksLikeEmailValidation(item)) {
          return 'invalid_email';
        }
      }
    }

    final lower = fallback.toLowerCase();
    if (lower.contains('email') &&
        (lower.contains('invalid') ||
            lower.contains('valid') ||
            lower.contains('format') ||
            lower.contains('regex') ||
            lower.contains('match'))) {
      return 'invalid_email';
    }

    // Mensaje ya corto / tipo código: preservarlo.
    if (!fallback.contains('{') &&
        !fallback.contains('[') &&
        fallback.length <= 64) {
      return fallback;
    }

    return 'validation_error';
  }

  bool _looksLikeEmailValidation(Map<dynamic, dynamic> item) {
    final path = item['path'] ?? item['field'] ?? item['param'] ?? item['property'];
    final pathStr =
        path is List ? path.map((e) => '$e').join('.') : '$path'.toLowerCase();
    if (pathStr.toLowerCase().contains('email')) return true;

    final validation =
        '${item['validation'] ?? item['code'] ?? item['keyword'] ?? ''}'
            .toLowerCase();
    if (validation.contains('email')) return true;

    final msg = '${item['message'] ?? item['msg'] ?? ''}'.toLowerCase();
    if (msg.contains('email')) return true;

    // Detalles con expresión regular suelen acompañar fallos de formato.
    final pattern =
        '${item['regex'] ?? item['pattern'] ?? item['expected'] ?? ''}';
    if (pattern.isNotEmpty &&
        (pathStr.toLowerCase().contains('email') || msg.contains('email'))) {
      return true;
    }

    return false;
  }
}
