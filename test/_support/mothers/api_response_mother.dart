import 'level_definition_mother.dart';

/// Object Mother: envelopes JSON tal como los emite ucab-arrowmaze-api
/// (docs/backend-context.md §7).
class ApiResponseMother {
  /// POST /auth/register 201 — nota: register expone `user.id`.
  static Map<String, dynamic> registerSuccess({
    String id = 'u-1',
    String username = 'alice',
    String email = 'alice@example.com',
    String token = 'jwt-register',
  }) =>
      {
        'success': true,
        'data': {
          'user': {'id': id, 'username': username, 'email': email},
          'token': token,
        },
      };

  /// POST /auth/login 200 — nota: login expone `user.userId`.
  static Map<String, dynamic> loginSuccess({
    String userId = 'u-1',
    String username = 'alice',
    String email = 'alice@example.com',
    String token = 'jwt-login',
  }) =>
      {
        'success': true,
        'data': {
          'user': {'userId': userId, 'username': username, 'email': email},
          'token': token,
        },
      };

  /// GET/PUT /progress 200.
  static Map<String, dynamic> progress({
    String userId = 'u-1',
    String currentLevelId = 'level_2',
  }) =>
      {
        'success': true,
        'data': {
          'userId': userId,
          'completedLevels': ['level_1'],
          'bestScores': {'level_1': 900},
          'currentLevelId': currentLevelId,
        },
      };

  /// GET /leaderboard/:levelId 200 con una entry.
  static Map<String, dynamic> leaderboardWithOneEntry({
    String levelId = 'level_1',
    int score = 950,
  }) =>
      {
        'success': true,
        'data': [
          {
            'userId': 'u-1',
            'username': 'alice',
            'levelId': levelId,
            'score': score,
            'moves': 8,
            'timeSeconds': 45,
            'rankedAt': '2026-07-01T00:00:00.000Z',
          },
        ],
      };

  static Map<String, dynamic> emptyLeaderboard() =>
      {'success': true, 'data': <dynamic>[]};

  /// GET /levels 200 con un LevelDto.
  static Map<String, dynamic> levelsList() => {
        'success': true,
        'data': [LevelDefinitionMother.backendDtoJson()],
      };

  /// GET /levels/:id 200.
  static Map<String, dynamic> levelDto({String id = 'level_1'}) =>
      {'success': true, 'data': LevelDefinitionMother.backendDtoJson(id: id)};

  /// Error genérico del backend.
  static Map<String, dynamic> error(String message) =>
      {'success': false, 'message': message};
}
