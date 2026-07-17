import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze/application/dtos/level_preview.dart';
import 'package:arrow_maze/application/use_cases/get_level_catalog_use_case.dart';

import '../fakes/fake_level_catalog_service.dart';
import '../mothers/level_preview_mother.dart';

/// Testing API: catálogo de niveles vía puerto ILevelCatalogService (fake).
class CatalogTestApi {
  final FakeLevelCatalogService _catalog = FakeLevelCatalogService();
  List<LevelPreview>? _result;

  CatalogTestApi givenACatalogWithLevels(List<String> ids) {
    for (final id in ids) {
      _catalog.seed(LevelPreviewMother.asset(id: id));
    }
    return this;
  }

  CatalogTestApi givenAnEmptyCatalog() => this;

  Future<CatalogTestApi> whenCatalogIsRequested() async {
    _result = await GetLevelCatalogUseCase(catalog: _catalog).execute();
    return this;
  }

  void thenPreviewsShouldBe(List<String> ids) =>
      expect(_result!.map((p) => p.id).toList(), equals(ids));

  void thenCatalogShouldBeEmpty() => expect(_result, isEmpty);
}
