import 'package:flutter_test/flutter_test.dart';

import '../../_support/apis/remote_level_repository_test_api.dart';

void main() {
  group('RemoteJsonLevelRepository — niveles desde el backend', () {
    test('should_build_a_playable_board_when_the_backend_has_the_level',
        () async {
      final api = RemoteLevelRepositoryTestApi()
          .givenTheBackendHasTheLevel('level_1');

      await api.whenTheLevelIsLoaded('level_1');

      api.thenAPlayableBoardShouldBeBuilt();
    });

    test(
        'should_propagate_not_found_when_the_level_only_exists_locally',
        () async {
      // Ids generados localmente no existen en el backend: el error se
      // propaga para que ChainedLevelRepository pruebe la siguiente fuente.
      final api = RemoteLevelRepositoryTestApi()
          .givenTheBackendLacksTheLevel('generated_abc');

      await api.whenTheLevelIsLoaded('generated_abc');

      api.thenLoadingShouldFailWithNotFound();
    });
  });
}
