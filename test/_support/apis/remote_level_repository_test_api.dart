import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:arrow_maze/application/builders/level_builder.dart';
import 'package:arrow_maze/application/errors/api_error.dart';
import 'package:arrow_maze/application/ports/i_api_client.dart';
import 'package:arrow_maze/domain/aggregates/board.dart';
import 'package:arrow_maze/domain/value_objects/level_id.dart';
import 'package:arrow_maze/infrastructure/repositories/remote_json_level_repository.dart';

import '../mothers/level_definition_mother.dart';

class _MockApiClient extends Mock implements IApiClient {}

/// Testing API: carga de niveles desde el backend (RemoteJsonLevelRepository).
class RemoteLevelRepositoryTestApi {
  final _MockApiClient _api = _MockApiClient();
  Board? _board;
  Object? _error;

  RemoteLevelRepositoryTestApi givenTheBackendHasTheLevel(String id) {
    when(() => _api.getLevelById(id)).thenAnswer(
      (_) async => LevelDefinitionMother.withEscapableArrow(id: id),
    );
    return this;
  }

  RemoteLevelRepositoryTestApi givenTheBackendLacksTheLevel(String id) {
    when(() => _api.getLevelById(id))
        .thenThrow(const NotFoundError('Not found'));
    return this;
  }

  Future<RemoteLevelRepositoryTestApi> whenTheLevelIsLoaded(String id) async {
    final repo = RemoteJsonLevelRepository(
      api: _api,
      builder: LevelBuilder(),
    );
    try {
      _board = await repo.loadLevel(LevelId(id));
    } catch (e) {
      _error = e;
    }
    return this;
  }

  void thenAPlayableBoardShouldBeBuilt() {
    expect(_error, isNull);
    expect(_board, isNotNull);
    expect(_board!.arrowCount, greaterThan(0));
  }

  void thenLoadingShouldFailWithNotFound() =>
      expect(_error, isA<NotFoundError>());
}
