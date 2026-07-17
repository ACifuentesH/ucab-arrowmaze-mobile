import 'package:flutter_test/flutter_test.dart';

import '../../_support/apis/remote_catalog_test_api.dart';
import '../../_support/mothers/level_definition_mother.dart';

void main() {
  group('RemoteFirstLevelCatalogService — campaña remoto-primero', () {
    test(
        'should_serve_backend_content_in_local_campaign_order_when_backend_is_reachable',
        () async {
      // Given: el backend devuelve la campaña en orden lexicográfico (como
      // GET /levels real) pero el manifest local define la secuencia jugable.
      final api = RemoteCatalogTestApi()
          .givenABundledCampaignInOrder(['level_1', 'level_2', 'level_10'])
          .givenTheBackendReturnsLevelIds(['level_1', 'level_10', 'level_2']);

      await api.whenTheCatalogIsRequested();

      api.thenTheCatalogOrderShouldBe(['level_1', 'level_2', 'level_10']);
      api.thenEveryLevelShouldBelongToTheCampaign();
    });

    test('should_prefer_the_backend_version_when_a_level_exists_on_both_sides',
        () async {
      final api = RemoteCatalogTestApi()
          .givenABundledCampaignInOrder(['level_1']).givenTheBackendReturnsLevels([
        LevelDefinitionMother.withEscapableArrow(
          id: 'level_1',
          name: 'Primer Vuelo (remoto)',
        ),
      ]);

      await api.whenTheCatalogIsRequested();

      api.thenTheLevelShouldBeNamed('level_1', 'Primer Vuelo (remoto)');
    });

    test('should_fall_back_to_bundled_levels_when_backend_is_unreachable',
        () async {
      final api = RemoteCatalogTestApi()
          .givenABundledCampaignInOrder(['level_1', 'level_2'])
          .givenTheBackendIsUnreachable();

      await api.whenTheCatalogIsRequested();

      api.thenTheCatalogOrderShouldBe(['level_1', 'level_2']);
    });

    test('should_fall_back_to_bundled_levels_when_backend_catalog_is_empty',
        () async {
      // DB recién creada sin seed: la campaña bundleada sigue funcionando.
      final api = RemoteCatalogTestApi()
          .givenABundledCampaignInOrder(['level_1', 'level_2'])
          .givenTheBackendHasNoLevels();

      await api.whenTheCatalogIsRequested();

      api.thenTheCatalogOrderShouldBe(['level_1', 'level_2']);
    });

    test('should_append_backend_only_levels_after_the_local_campaign',
        () async {
      // El backend publica un nivel nuevo que la app bundleada no conoce:
      // aparece al final de la campaña sin republicar la app.
      final api = RemoteCatalogTestApi()
          .givenABundledCampaignInOrder(['level_1', 'level_2'])
          .givenTheBackendReturnsLevelIds(
              ['level_16_nuevo', 'level_1', 'level_2']);

      await api.whenTheCatalogIsRequested();

      api.thenTheCatalogOrderShouldBe(
          ['level_1', 'level_2', 'level_16_nuevo']);
    });

    test('should_keep_the_bundled_level_when_the_backend_is_missing_it',
        () async {
      // Seed incompleto: el nivel ausente en el backend se sirve del bundle
      // en su posición de campaña — nunca desaparece un nivel jugable.
      final api = RemoteCatalogTestApi()
          .givenABundledCampaignInOrder(['level_1', 'level_2', 'level_3'])
          .givenTheBackendReturnsLevelIds(['level_1', 'level_3']);

      await api.whenTheCatalogIsRequested();

      api.thenTheCatalogOrderShouldBe(['level_1', 'level_2', 'level_3']);
    });
  });
}
