import 'package:flutter_test/flutter_test.dart';

import '../../_support/apis/catalog_test_api.dart';

void main() {
  group('GetLevelCatalogUseCase', () {
    test('should_return_every_preview_when_catalog_has_levels', () async {
      (await CatalogTestApi()
              .givenACatalogWithLevels(['level_1', 'level_2'])
              .whenCatalogIsRequested())
          .thenPreviewsShouldBe(['level_1', 'level_2']);
    });

    test('should_return_empty_list_when_catalog_is_empty', () async {
      (await CatalogTestApi().givenAnEmptyCatalog().whenCatalogIsRequested())
          .thenCatalogShouldBeEmpty();
    });
  });
}
