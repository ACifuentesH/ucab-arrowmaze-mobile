import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:arrow_maze/application/dtos/auth_session.dart';
import 'package:arrow_maze/application/dtos/leaderboard_entry_dto.dart';
import 'package:arrow_maze/application/dtos/level_spec.dart';
import 'package:arrow_maze/application/dtos/player_progress_dto.dart';
import 'package:arrow_maze/application/enums/difficulty.dart';
import 'package:arrow_maze/application/builders/level_definition.dart';
import 'package:arrow_maze/application/errors/api_error.dart';
import 'package:arrow_maze/infrastructure/api/http_api_client.dart';

import '../fakes/fake_token_storage.dart';
import '../mothers/progress_mother.dart';

/// Testing API: HttpApiClient contra un servidor simulado (MockClient de
/// package:http/testing — sin red real). Toda la "suciedad" HTTP vive aquí.
class ApiClientTestApi {
  static const String _baseUrl = 'http://localhost:3000';

  final FakeTokenStorage _tokens = FakeTokenStorage();
  http.Request? _lastRequest;
  int _status = 200;
  Map<String, dynamic> _envelope = const {};
  Object? _result;
  Object? _error;

  late final HttpApiClient _client = HttpApiClient(
    httpClient: MockClient((request) async {
      _lastRequest = request;
      return http.Response(
        jsonEncode(_envelope),
        _status,
        headers: {'content-type': 'application/json'},
      );
    }),
    tokenStorage: _tokens,
    baseUrl: _baseUrl,
  );

  // ── Given ──────────────────────────────────────────────────────────────────

  ApiClientTestApi givenServerResponds(
    int status,
    Map<String, dynamic> envelope,
  ) {
    _status = status;
    _envelope = envelope;
    return this;
  }

  ApiClientTestApi givenAStoredToken([String token = 'stored-jwt']) {
    _tokens.stored = token;
    return this;
  }

  // ── When ───────────────────────────────────────────────────────────────────

  Future<ApiClientTestApi> whenRegistering() =>
      _capture(() => _client.register(
            username: 'alice',
            email: 'alice@example.com',
            password: 'password123',
          ));

  Future<ApiClientTestApi> whenLoggingIn() => _capture(
      () => _client.login(email: 'alice@example.com', password: 'password123'));

  Future<ApiClientTestApi> whenLoggingOut() => _capture(_client.logout);

  Future<ApiClientTestApi> whenGettingProgress() =>
      _capture(_client.getProgress);

  Future<ApiClientTestApi> whenPuttingCompletedLevelProgress() =>
      _capture(() => _client.putProgress(ProgressMother.levelCompletedUpdate()));

  Future<ApiClientTestApi> whenPuttingMinimalProgress() =>
      _capture(() => _client.putProgress(ProgressMother.minimalUpdate()));

  Future<ApiClientTestApi> whenGettingLeaderboard({int limit = 10}) =>
      _capture(() => _client.getLeaderboard('level_1', limit: limit));

  Future<ApiClientTestApi> whenGettingLevels() => _capture(_client.getLevels);

  Future<ApiClientTestApi> whenGettingLevelById(String id) =>
      _capture(() => _client.getLevelById(id));

  Future<ApiClientTestApi> whenGeneratingLevel({
    String shapeName = 'a heart',
    Difficulty difficulty = Difficulty.medium,
  }) =>
      _capture(() => _client.generateLevel(LevelSpec(
            shapeName: shapeName,
            difficulty: difficulty,
            gridSize: 16,
          )));

  Future<ApiClientTestApi> _capture(Future<Object?> Function() call) async {
    try {
      _result = await call();
    } catch (e) {
      _error = e;
    }
    return this;
  }

  // ── Then ───────────────────────────────────────────────────────────────────

  void thenRequestShouldBe(String method, String path) {
    expect(_lastRequest, isNotNull, reason: 'No HTTP request was sent');
    expect(_lastRequest!.method, equals(method));
    expect(_lastRequest!.url.toString(), equals('$_baseUrl$path'));
  }

  void thenAuthorizationHeaderShouldBe(String value) =>
      expect(_lastRequest!.headers['Authorization'], equals(value));

  void thenNoAuthorizationHeaderShouldBeSent() =>
      expect(_lastRequest!.headers.containsKey('Authorization'), isFalse);

  void thenRequestBodyFieldShouldBe(String field, Object? value) {
    final body = jsonDecode(_lastRequest!.body) as Map<String, dynamic>;
    expect(body[field], equals(value));
  }

  void thenRequestBodyFieldShouldContain(String field, String substring) {
    final body = jsonDecode(_lastRequest!.body) as Map<String, dynamic>;
    expect(body[field], contains(substring));
  }

  void thenRequestBodyShouldNotContain(String field) {
    final body = jsonDecode(_lastRequest!.body) as Map<String, dynamic>;
    expect(body.containsKey(field), isFalse);
  }

  void thenSessionUserIdShouldBe(String id) {
    final session = _result as AuthSession;
    expect(session.user.id, equals(id));
  }

  void thenTokenShouldBeStored(String token) =>
      expect(_tokens.stored, equals(token));

  void thenTokenShouldBeCleared() => expect(_tokens.stored, isNull);

  void thenErrorShouldBe<T>() {
    expect(_error, isA<T>());
  }

  void thenErrorMessageShouldBe(String message) {
    expect(_error, isA<ApiError>());
    expect((_error! as ApiError).message, equals(message));
  }

  void thenNoErrorShouldOccur() => expect(_error, isNull);

  void thenProgressUserIdShouldBe(String userId) {
    final dto = _result as PlayerProgressDto;
    expect(dto.userId, equals(userId));
  }

  void thenProgressBestScoreShouldBe(String levelId, int score) {
    final dto = _result as PlayerProgressDto;
    expect(dto.bestScores[levelId], equals(score));
  }

  void thenLeaderboardShouldHaveEntries(int count) {
    final entries = _result as List<LeaderboardEntryDto>;
    expect(entries, hasLength(count));
  }

  void thenFirstLeaderboardScoreShouldBe(int score) {
    final entries = _result as List<LeaderboardEntryDto>;
    expect(entries.first.score, equals(score));
  }

  void thenLevelsShouldHaveIds(List<String> ids) {
    final levels = _result as List<LevelDefinition>;
    expect(levels.map((l) => l.id).toList(), equals(ids));
  }

  void thenLevelShouldFollowContract() {
    final level = _result as LevelDefinition;
    expect(level.cells, isNotEmpty);
    expect(level.arrows, isNotEmpty);
    expect(level.lives, greaterThanOrEqualTo(0));
  }

  void thenGeneratedLevelNameShouldBe(String name) {
    final level = _result as LevelDefinition;
    expect(level.name, equals(name));
  }

  void thenGeneratedLevelLivesShouldBe(int lives) {
    final level = _result as LevelDefinition;
    expect(level.lives, equals(lives));
  }

  void thenGeneratedLevelCellsShouldBe(List<List<int>> cells) {
    final level = _result as LevelDefinition;
    expect(level.cells, equals(cells));
  }
}
