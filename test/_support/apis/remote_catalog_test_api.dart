import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:arrow_maze/application/builders/level_definition.dart';
import 'package:arrow_maze/application/dtos/level_preview.dart';
import 'package:arrow_maze/application/enums/level_source.dart';
import 'package:arrow_maze/application/errors/api_error.dart';
import 'package:arrow_maze/application/ports/i_api_client.dart';
import 'package:arrow_maze/infrastructure/catalog/backend_level_catalog_service.dart';
import 'package:arrow_maze/infrastructure/catalog/remote_first_level_catalog_service.dart';

import '../fakes/fake_level_catalog_service.dart';
import '../mothers/level_definition_mother.dart';
import '../mothers/level_preview_mother.dart';

class _MockApiClient extends Mock implements IApiClient {}

/// Testing API: catálogo de campaña remoto-primero
/// (BackendLevelCatalogService decorado por RemoteFirstLevelCatalogService).
class RemoteCatalogTestApi {
  final _MockApiClient _api = _MockApiClient();
  final FakeLevelCatalogService _local = FakeLevelCatalogService();
  List<LevelPreview>? _result;

  RemoteCatalogTestApi givenABundledCampaignInOrder(List<String> ids) {
    for (final id in ids) {
      _local.seed(LevelPreviewMother.asset(id: id));
    }
    return this;
  }

  RemoteCatalogTestApi givenTheBackendReturnsLevels(
    List<LevelDefinition> defs,
  ) {
    when(() => _api.getLevels()).thenAnswer((_) async => defs);
    return this;
  }

  RemoteCatalogTestApi givenTheBackendReturnsLevelIds(List<String> ids) =>
      givenTheBackendReturnsLevels([
        for (final id in ids) LevelDefinitionMother.withEscapableArrow(id: id),
      ]);

  RemoteCatalogTestApi givenTheBackendIsUnreachable() {
    when(() => _api.getLevels())
        .thenThrow(const NetworkError('connection refused'));
    return this;
  }

  RemoteCatalogTestApi givenTheBackendHasNoLevels() =>
      givenTheBackendReturnsLevels(const []);

  Future<RemoteCatalogTestApi> whenTheCatalogIsRequested() async {
    final service = RemoteFirstLevelCatalogService(
      remote: BackendLevelCatalogService(_api),
      local: _local,
    );
    _result = await service.getLevels();
    return this;
  }

  void thenTheCatalogOrderShouldBe(List<String> ids) =>
      expect(_result!.map((p) => p.id).toList(), equals(ids));

  void thenTheLevelShouldBeNamed(String id, String name) => expect(
        _result!.firstWhere((p) => p.id == id).name,
        equals(name),
      );

  void thenEveryLevelShouldBelongToTheCampaign() {
    for (final preview in _result!) {
      expect(preview.source, equals(LevelSource.asset),
          reason: '${preview.id} debería ser de campaña');
    }
  }
}
